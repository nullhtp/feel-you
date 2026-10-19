## Why

Phase 2 (#35) streams model output into Morse: Listen, Look and Ask all send a request to the cloud and play the answer word by word as it arrives. They need one HTTP client that talks to OpenRouter's OpenAI-compatible API with the assistant's key (#61), streams the answer, falls back to other models, honours the data policy, keeps track of what it costs and reports every failure as a distinct, typed error so the user can be told what broke (#64). This is that client (#62); the assistant screen (#63) and the reader (#65) build on it.

## What Changes

- **A streaming chat-completions client.** `POST {base URL}/chat/completions` with `stream: true`, the request's model fallback list (`models`, with the first as `model`), `temperature: 0`, `provider.data_collection: "deny"` while the data setting is on, and an optional JSON `response_format`. It sends the saved key as `Authorization: Bearer`, plus `HTTP-Referer` and `X-Title` for OpenRouter's app attribution. Without a saved key it fails with a "no key" error and sends nothing.
- **Server-sent events to words.** A parser for the event stream (data lines, keep-alive comments such as `: OPENROUTER PROCESSING`, multi-line events, `[DONE]`, an error object mid-stream) feeds a word buffer that hands out each word as soon as whitespace ends it and the last word when the answer ends. The raw text fragments are available too, for JSON answers.
- **Timeout and cancellation.** An answer whose first token has not arrived 5 s after the request was sent fails with a timeout. A cancellation API closes the connection and stops emitting at once; the gesture that calls it comes later (#65).
- **One error type with seven cases:** offline, key rejected (401), limit exhausted (402), model unavailable (404, 502, 503, or every fallback model failed), timeout, no key, and other (status code only). Errors, logs and `toString`s never contain the key or a response body.
- **Two cloud settings on the device:** the base URL (OpenRouter's by default; any OpenAI-compatible endpoint over `https`, or `http` on the phone's own loopback address) and "deny data collection", on by default. #63 adds the switches.
- **Usage accounting.** The `usage` of each answer (tokens, and cost when reported) is added up on the device for today and for this month, by the local calendar. The key's limit and spend (`GET {base URL}/key`) are fetched at most once a day per key and cached with the time they were fetched.

## Accessibility

- Nothing the user feels changes in this change: no screen calls the client yet, and it plays no signal. The offline core (the lessons, the menu, the picker) never touches it.
- The error cases are the ones the user must be able to tell apart by touch (#64). Folding them into seven typed cases now means each one can later get its own vibration, and the client never fails silently: every answer ends with its words, an error, or the caller's cancellation.
- Words are released as soon as they are complete, so the reader (#65) can start vibrating after the first word rather than after the whole answer. The 5 s first-token timeout bounds the silence before the user learns that something is wrong.

## Non-goals

- No screen, gesture, overlay line or signal. The assistant screen (#63) adds the key, model presets, the data-policy switch and the base URL; the status signals come with #64; the reader and the cancel gesture with #65.
- No network permission or privacy-text change. Nothing sends a request yet, so the Android `INTERNET` permission, `store/privacy-policy.md`, the data-safety and export-compliance lines of `store/store-info.md` and the README's privacy statements stay as they are. #63, the first screen that sends anything, changes them, and #71 adds the consent step. Until then the client cannot reach the network in an Android release build.
- No retries, rate-limit handling or offline fallback (#64, Phase 2 epics).
- No images or audio in requests (#66, #67), and no tool calls.
- No OAuth sign-in (#63).

## Capabilities

### New Capabilities

- `openrouter-client`: the cloud request (endpoint, body, headers, key and settings it uses), the base-URL and data-collection settings, streaming into words, the first-token timeout and cancellation, the error cases, the no-leak rule, usage accounting and the daily key-info fetch.

### Modified Capabilities

- `integration-testing`: an end-to-end test of the client in the real app against a local server on the device.

## Impact

- **Dependency:** `http` ^1.6.0 (already in the lock file through other packages, now direct), for its streamed, abortable requests and its test client.
- **New code** in `app/lib/cloud/`: the error type, the event-stream parser, the word buffer, the settings and usage values, their `SharedPreferences` store, and the client with its Riverpod providers. `main.dart` loads the store before the first frame, like the other settings.
- **Not touched:** the Android manifest, the iOS project, the vibration engine, the UI.
- **Docs:** `app/README.md` layout row for `lib/cloud/`, a CHANGELOG line.
- **Tests:** unit tests against recorded OpenRouter event streams (fixtures under `app/test/cloud/fixtures/`) and a fake HTTP client; an end-to-end test on the `E2EApp` harness with a real local HTTP server, the real secure storage and the real preferences.
