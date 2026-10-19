## Context

See proposal.md for why. The relevant current state:

- `app/lib/cloud/` (#61) holds `CloudKey` (validated, `toString` masked), `maskCloudKey`, the `CloudKeyStore`s and `cloudKeyProvider` (`AsyncNotifier<CloudKey?>`, never an error). The cloud-off signal is in the vibration engine.
- Settings follow one shape: an interface, a `SharedPreferences` implementation, an in-memory fallback that is the provider's default, and a `load…()` that `main.dart` awaits before `runApp`.
- The app has no network code. The Android main manifest has no `INTERNET` permission (the debug and profile manifests have it, for Flutter tooling). `http` 1.6.0 is already in the lock file through other packages.
- The OpenRouter documentation this design follows, read on 2026-10-19:
  - Streaming: <https://openrouter.ai/docs/api/reference/streaming> (SSE, `: OPENROUTER PROCESSING` comments, `data: [DONE]`, mid-stream error chunk with `finish_reason: "error"`, usage in the last chunk, cancellation by closing the connection).
  - Errors: <https://openrouter.ai/docs/api/reference/errors-and-debugging> (400, 401, 402, 403, 408, 429, 502, 503; typed `metadata.error_type` such as `provider_unavailable`, `not_found` (404), `timeout` (504); "if every provider fails before any tokens reach you, the status still stays 200").
  - Fallbacks: <https://openrouter.ai/docs/guides/routing/model-fallbacks> (`models` in priority order; the response's `model` is the one used).
  - Data policy: <https://openrouter.ai/docs/guides/routing/provider-selection> (`provider.data_collection`: `"allow"` by default, `"deny"` for providers that do not collect user data).
  - Usage: <https://openrouter.ai/docs/guides/administration/usage-accounting> (`usage` with tokens and `cost` in credits, now always included, in the last SSE message).
  - Key: <https://openrouter.ai/docs/api/reference/limits> (`GET /api/v1/key`: `data.limit`, `limit_remaining`, `usage`, `usage_daily`, `usage_monthly`, by UTC day and month).
  - Request schema and headers: <https://openrouter.ai/docs/api/reference/overview> and <https://openrouter.ai/docs/app-attribution> (`HTTP-Referer`; `X-OpenRouter-Title`, with `X-Title` "still accepted for backwards compatibility").
  - The event stream format itself: the HTML standard, <https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation>.

## Goals / Non-Goals

**Goals:**
- One client that #63 (validate the key, show the limit and spend), #65 (stream words into the reader, cancel) and #64 (map each failure to a signal) use as it is.
- Every request ends in exactly one of: its words and a normal end, one typed error, or the caller's cancellation. Never silence.
- The key never leaves the `Authorization` header: not in an error, a log, a cached value or a URL.

**Non-Goals:**
- Retries, backoff or a rate-limit case. A 429 is the other error with its status.
- An idle timeout after the first token (see Open Questions).
- Non-streaming answers, images, audio, tool calls.

## Decisions

### 1. `package:http`, streamed and abortable, behind a provider

`OpenRouterClient` takes an `http.Client`; `cloudHttpClientProvider` creates the default `http.Client()` (an `IOClient` on iOS and Android) only when the client is first used, and closes it with the container. Tests pass a fake `BaseClient` or `MockClient`.

Requests are `http.AbortableRequest`s (http 1.5+). Cancelling completes the abort trigger and cancels the response subscription. Checked on the host before relying on it: `IOClient` aborts a request that has no response yet; once streaming, cancelling the subscription makes `dart:io` destroy the socket (the server sees the connection close within a millisecond), whereas `HttpClientRequest.abort` alone does nothing after the response has arrived.

Alternatives: *`dart:io` `HttpClient` directly* (no test client, more code for the same abort); *`dio`* (a large dependency for one endpoint).

### 2. The request

```json
{"model": "<first>", "models": ["<first>", "<second>"], "messages": [...],
 "stream": true, "temperature": 0,
 "provider": {"data_collection": "deny"},
 "response_format": {"type": "json_object"}}
```

- `model` is the first of `models`: OpenRouter routes by `models` and falls back along it; an endpoint that only speaks the OpenAI API needs `model`.
- `provider` only while "deny data collection" is on; `response_format` only when the caller asks for JSON.
- Headers: `Authorization: Bearer <key>`, `HTTP-Referer: https://github.com/nullhtp/feel-you`, `X-Title: Feel You`, `Content-Type: application/json`, `Accept: text/event-stream`. `X-Title` as decided for #62; the docs now name `X-OpenRouter-Title` and still accept `X-Title`.
- `followRedirects = false`: `dart:io` copies every header, `Authorization` included, to a redirect's target. A 3xx is the other error with its status.

### 3. Settings and usage in one preferences store

`CloudPreferencesStore` (`cloud_preferences.dart`) keeps what is not secret, in `SharedPreferences` (`UserDefaults` on iOS): `cloud_base_url` (string, absent = default), `cloud_deny_data_collection` (bool, absent = on), `cloud_usage` (JSON) and `cloud_key_info` (JSON). One store, one `loadCloudPreferencesStore()` in `main.dart` (the preferences are already loaded by then, so the first frame does not wait longer), one provider override. Reads never throw (a wrong type or bad JSON reads as nothing); writes are best effort and logged without values.

`cloudSettingsProvider` (`Notifier<CloudSettings>`) exposes `setBaseUrl(String) → bool`, `resetBaseUrl()` and `setDenyDataCollection(deny:)` for #63. `parseCloudBaseUrl` accepts `https`, or `http` on `localhost`, `127.0.0.1` or `::1` (a server on the phone itself, which is what the end-to-end test needs), requires a host and rejects user info, a query or a fragment, so a base URL can't carry a secret and is safe to show and log. A trailing `/` is dropped; requests go to `{base}/chat/completions` and `{base}/key`. An invalid stored value reads as the default.

Alternative: *two stores (settings, usage).* Rejected: twice the boilerplate for four keys with the same lifecycle.

### 4. Event stream parser

`SseParser` is a `StreamTransformer<List<int>, SseEvent>`: UTF-8 with `allowMalformed` (a bad byte becomes U+FFFD rather than ending the answer), `LineSplitter` (LF, CRLF, CR, split across chunks), then the HTML standard's interpretation: `data:` lines joined with `\n`, one leading space dropped, comments and unknown fields skipped, `event:` and `id:` kept, a blank line dispatches, an unfinished event at the end is dropped. Cancelling the parsed stream cancels the byte subscription, so it closes the connection.

The client then skips events that are not JSON objects (OpenRouter: "skip non-JSON lines"), stops at `[DONE]`, and reads `error`, `usage`, `choices[0].delta.content` and `choices[0].finish_reason`.

### 5. Words and fragments

`WordBuffer` splits on `\S+` (Unicode whitespace, so no-break and ideographic spaces count) and keeps the last run until whitespace follows it. `CloudCompletion` offers `words` (through the buffer; the last word on a normal end) and `fragments` (the content pieces unchanged, for JSON answers that #65 parses into `{text, urgent}`). Only one of them may be listened to. `WordSplitter` is the same buffer as a stream transformer, for #65 to apply to text it extracts from JSON. After an error or a cancellation the unfinished word is dropped: it may have been cut off.

### 6. The life of one answer

```text
listen ─▶ read key ─▶ (none) ─────────────────────────────▶ error: no key, nothing sent
             │
             ▼
        send POST, start the 5 s timer
             │
   ┌─────────┼──────────────────┬──────────────────────────┐
   ▼         ▼                  ▼                          ▼
 throws   status ≠ 200     200 JSON body              200 event stream
 offline  error by status  error object → its case    content → timer off, words out
                                                       [DONE] / finish + end → last word, done
                                                       error event → its case
                                                       ends early / dropped → offline
 timer fires before the first content piece → timeout (connection closed)
 cancel() or the listener cancels → connection closed, stream done, nothing more out
```

- The request is sent when the stream is listened to, never on its own.
- The timer runs from sending to the first non-empty `delta.content`. Response headers, comments and the empty role chunk don't stop it.
- After `[DONE]` the stream ends at once, but the body is left to finish so `dart:io` can reuse the connection (a TLS handshake saved on the next request).
- The network is not paused when the listener is: the reader plays words far slower than they arrive, and the usage chunk must still be read. Words queued for a paused listener are dropped if the answer is cancelled.
- Every path ends the output stream exactly once (`_finished`).

### 7. Error cases

| Case | From |
|---|---|
| Offline | `ClientException` (including `SocketException` as wrapped by `IOClient`: refused, no route, DNS), `SocketException`, `HttpException` (dropped mid-body), `TlsException` (handshake, certificate), or a stream that ends before `[DONE]` and before a finish reason |
| Key rejected | 401; `error_type` `authentication` |
| Limit exhausted | 402; `payment_required` |
| Model unavailable | 404 (no such model, or none that meets the data policy), 502 (model down), 503 (no provider); `not_found`, `provider_unavailable`, `provider_overloaded`; code `server_error` (OpenRouter's example of a provider dropping out mid-answer) |
| Timeout | the first-token timer; 408, 504; `timeout` |
| No key | no saved key |
| Other (status) | any other status (400, 403, 429, 3xx, 500…), a `200` that is JSON without an error object, an error without a known code (status `null`), any unexpected exception |

An `error` object decides by `metadata.error_type` first, then a numeric `code` (number or string) through the status table. The key-info request uses its own small table: 401, 402, 408/504 as above, everything else (404 included: an endpoint without `/key`) is the other error.

### 8. Nothing secret in errors and logs

`CloudError` subclasses carry no message and no body; `toString` is a fixed sentence plus, for the other error, the status code. Error responses are closed unread, except a `200` JSON body (OpenRouter's "every provider failed") and the key information, read up to 64 KiB, of which only the error's type and code, or the key info's numbers, are kept: messages can echo the input, and moderation errors quote it. `ClientException` messages and URIs are never passed on. The client's only logs are `Cloud request failed: <error>` and `Cloud key information failed: <error>`. `CloudMessage` and `CloudRequest` print lengths and model IDs, not content.

### 9. Usage totals

`CloudUsageTotals` holds `day` (the local date last added to), `today` and `thisMonth` (`CloudUsageAmount`: answers, prompt, completion and total tokens, cost). `at(now)` rolls over: a different local date zeroes today; a different month (or year) zeroes both. A clock set back counts as a new day. `cloudUsageProvider.notifier.add(usage)` rolls, adds and saves; `current()` rolls the state to now for readers such as #63's overlay, since nothing ticks at midnight. Cost is OpenRouter credits (about one US dollar each); an answer without `cost` adds only tokens. The clock is `cloudClockProvider`, overridden in tests.

Usage counts and the key's spend are not secret, so they live in the preferences rather than the Keychain, and are backed up with the language like other settings.

### 10. Key information once a day

`keyInfo()` reads the key (no key → no-key error, nothing sent), then returns the saved `CloudKeyInfo` when it was fetched on today's local date for the same masked key and base URL. Otherwise it sends `GET {base}/key` (5 s timeout, aborting the connection), saves the result with `fetchedAt` (UTC) and returns it. A failure saves nothing, so the next call tries again. Two calls at once share one request.

The cache stores the **masked** key (`sk-or-...a1b2`), never the key: it tells a new key from the old one without putting the key in the preferences (`cloud-key-storage`: no preference value contains the key). Two keys with the same last four characters would share the cache for the rest of a day; the cost is a stale limit display, not a wrong request. `/key` is the documented path; the older `/auth/key` is not used.

### 11. Tests

- **Fixtures** (`app/test/cloud/fixtures/*.sse`): an OpenRouter answer (comments, role chunk, words split across chunks, a non-ASCII word, finish and usage chunks with OpenRouter's fields, `[DONE]`), a mid-stream error (the docs' `server_error` chunk), every model failing (a `200` with only a 502 `provider_unavailable` chunk) and a JSON answer. The parser is checked with every fixture cut at 1, 2, 3, 7, 64 and 333 bytes and with CRLF and CR line ends.
- **Client** against a fake `BaseClient` that records requests and lets a test feed the body chunk by chunk and see when it is cancelled; timeouts use 300 ms instead of 5 s, and the 5 s default is checked as a constant.
- **End to end** (`integration_test/openrouter_client_test.dart`): an `HttpServer` on `127.0.0.1` inside the test, the real secure storage and preferences, the app's providers. Event streams are written on the raw socket (`detachSocket`) with hand-written HTTP chunks and `Connection: close`, so the test sees exactly when the app closes a connection.

## Hand-off to #63 and #71

Decided for #62 (2026-10-19): no network permission and no privacy-text change here, because nothing sends a request yet. The first screen that sends anything (#63, with consent in #71) must:

- add `android.permission.INTERNET` to `app/android/app/src/main/AndroidManifest.xml`. Until then the client gets a `SocketException` in an Android release build, which it reports as offline; debug and profile builds have the permission already, and iOS needs none.
- update `store/privacy-policy.md` (what is sent to OpenRouter, and that the cloud settings, usage totals and key information are stored in the app preferences), the data-safety, Internet Access and export-compliance (HTTPS) lines of `store/store-info.md`, and the README's privacy statements ("Almost no state", The Cloud Key).

## Risks / Trade-offs

- [A reasoning model may think for longer than 5 s before its first content token] → The timeout fires and the user gets the timeout signal. #63's presets should pick fast models or turn reasoning off.
- [Cancelled answers are not counted, though they may be billed] → OpenRouter stops billing on cancel only for providers that support it; the key information (spend) is the authority, the local totals are an estimate.
- [Local totals use the local calendar, OpenRouter's `usage_daily` the UTC day] → Both are shown for what they are; documented on `CloudKeyInfo`.
- [`dart:io` speaks HTTP/1.1 only] → One TLS connection per concurrent request; connections are reused after a complete answer.
- [Words queue while the reader is slow] → Memory grows with the answer, which #65 keeps short (40 characters first).
- [`X-Title` may be dropped by OpenRouter one day] → Attribution only; requests still work. Switching to `X-OpenRouter-Title` is a one-line change.
- [The base URL setting allows `http` to the phone itself] → Loopback never leaves the device; any other host must be `https`.

## Migration Plan

No migration: nothing has been stored for the cloud apart from the key. Rollback is a revert; an older build ignores the four preference keys.

## Open Questions

- After the first token, a stalled connection (the network lost mid-answer without a reset) waits for the operating system to notice, which can take minutes. An idle timeout (for example 10 s without a chunk, comments included, giving the timeout error) would close that gap; it changes what the user feels, so it is left for #64/#65 to decide.
- Should a 429 (rate limited, common on `:free` models) get its own case and signal in #64 instead of the other error?
