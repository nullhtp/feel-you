# Tasks

## 1. Dependency

- [x] 1.1 Add `http: ^1.6.0` to `app/pubspec.yaml` (already locked at 1.6.0 as a transitive dependency); verify `flutter pub get --offline` succeeds and `pubspec.lock` only marks it `direct main`

## 2. Errors, event stream and words

- [x] 2.1 Add `app/lib/cloud/cloud_error.dart`: the sealed `CloudError` with `CloudOffline`, `CloudKeyRejected`, `CloudLimitExhausted`, `CloudModelUnavailable`, `CloudTimeout`, `CloudNoKey` and `CloudOtherError(statusCode)`, `CloudError.fromStatus` and `CloudError.fromErrorObject` (type, then numeric code, then `server_error`), fixed `toString`s. Verify with `test/cloud/cloud_error_test.dart`: every status of the *Error cases* scenario, every typed error, numeric and string codes, and that a message containing a key is not in the text
- [x] 2.2 Add `app/lib/cloud/sse_parser.dart` (`SseEvent`, `SseParser`) following the HTML standard. Verify with `test/cloud/sse_parser_test.dart` and the recorded streams under `test/cloud/fixtures/`: the OpenRouter stream's chunks without its comments, the same events for every chunk size including inside a multi-byte character, CRLF and CR, multi-line data, the optional space, skipped fields, an unfinished last event dropped, a byte order mark, malformed UTF-8, a passed-on error and cancellation reaching the byte stream
- [x] 2.3 Add `app/lib/cloud/word_buffer.dart` (`WordBuffer`, `WordSplitter`). Verify with `test/cloud/word_buffer_test.dart`: the `Hel` / `lo wor` / `ld, how` / ` are you?` scenario, Unicode whitespace (tab, CRLF, no-break, ideographic), empty pieces, a word over many pieces, a word released before the next piece, the unfinished word dropped on an error

## 3. Settings, usage and their store

- [x] 3.1 Add `app/lib/cloud/cloud_settings.dart` (`CloudSettings`, `parseCloudBaseUrl`, `loopbackHosts`) and `app/lib/cloud/cloud_usage.dart` (`CloudUsage`, `CloudUsageAmount`, `CloudUsageTotals` with local-calendar rollover, `CloudKeyInfo` with the masked key, the base URL and the fetch time). Verify with `test/cloud/cloud_settings_test.dart` and `test/cloud/cloud_usage_test.dart`: https and loopback http accepted, other http, credentials, queries, fragments and non-URLs rejected, trailing `/` dropped; usage parsing with and without cost, the *Two answers*, *Next day* and *Next month* scenarios, a clock set back, JSON round trips; `GET /key` parsing with and without a limit, and `isCurrent` per local day, masked key and base URL
- [x] 3.2 Add `app/lib/cloud/cloud_preferences.dart`: the `CloudPreferencesStore` interface, its `SharedPreferences` (keys `cloud_base_url`, `cloud_deny_data_collection`, `cloud_usage`, `cloud_key_info`) and in-memory implementations, `loadCloudPreferencesStore`, `cloudClockProvider`, `cloudSettingsProvider` (set, reject, reset the base URL; data collection on by default) and `cloudUsageProvider` (`add`, `current`). Load and override it in `app/lib/main.dart`. Verify with the same tests through restarts of the mock preferences: base URL and data-collection setting survive a restart, an invalid or mistyped stored value reads as the default, totals survive a restart and read as zero on the next day, corrupt totals read as nothing used

## 4. The client

- [x] 4.1 Add `app/lib/cloud/openrouter_client.dart`: `CloudMessage`, `CloudRequest` (`toJson` with `model`, `models`, `stream`, `temperature`, the data policy and `response_format`), `CloudTimingConfig` (5 s), `CloudCompletion` (`words`, `fragments`, `cancel`, `isCancelled`), `OpenRouterClient.stream` and `keyInfo`, and the providers `cloudTimingConfigProvider`, `cloudHttpClientProvider` and `openRouterClientProvider`; export everything from `cloud.dart`. Verify with `test/cloud/openrouter_client_test.dart` against a fake HTTP client and the fixtures: body, headers and no redirects; JSON and data-collection variants; custom base URL; no key sends nothing; nothing sent before listening; the recorded stream's words and usage, whatever the byte cuts; fragments of a JSON answer; words released as they complete; finish without `[DONE]`; a cut-off stream is offline; non-JSON events skipped; the first-token timeout with keep-alives and with no response, closing the connection, and no timeout after a first token; cancellation mid-answer, before the response, after the end, by the listener and with queued words; every status and error-event case; offline for refused, DNS, TLS and dropped connections; no key or body text in errors and recorded logs; key information fetched, cached per day, key and base URL, shared between concurrent calls, failures not saved; the provider wiring with the app's key, settings and usage totals, sending nothing by itself
- [x] 4.2 Check that nothing in `app/lib/cloud/` logs a key or a body: `grep -n "debugPrint(" app/lib/cloud/*.dart` shows only fixed messages, `CloudError`s and exception types

## 5. End-to-end test

- [x] 5.1 Add `app/integration_test/openrouter_client_test.dart` on the `E2EApp` harness with the real `SecureCloudKeyStore` and preferences store and an `HttpServer` on `127.0.0.1` started by the test; remove the key and the cloud preference keys before and after each test. Cover: no request at launch; the request's path, headers and body with and without the data policy and JSON; words in order from a chunked stream, the first before the rest is sent; the first-token timeout (1 s) closing the connection; cancellation closing the connection; 401, 402, 404, a `200` with only an error event, a dropped connection and a refused port; no key; usage and key information across a restart and the next day. Verify `flutter test integration_test/openrouter_client_test.dart -d <simulator>` passes on the iOS simulator, and that it fails with words held to the end, with a cancellation that leaves the connection open, with the key-information cache ignored and with usage not saved

## 6. Docs and checks

- [x] 6.1 Add `lib/cloud/`'s client, settings and usage to the layout table of `app/README.md`, the client to the project context of `openspec/config.yaml`, and a CHANGELOG line under `[Unreleased]`; verify the README's and the store texts' privacy statements are unchanged (hand-off below)
- [x] 6.2 Run in `app/`: `dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos` (no warnings or errors, no infos in new files), `flutter test`, and the whole `integration_test/` suite on the iOS simulator; `openspec validate add-openrouter-client --strict`; verify all pass
- [x] 6.3 Prove the archive: copy `openspec/` to a temporary directory, run `openspec archive add-openrouter-client --yes` and `openspec validate --specs --strict` there, and diff the main specs against the worktree's; verify only `openrouter-client` (new) and `integration-testing` (one added requirement) change

## Hand-off (not tracked here)

- #63 (the first screen that sends a request) adds `android.permission.INTERNET` to the main Android manifest and updates `store/privacy-policy.md`, the data-safety, Internet Access and export-compliance lines of `store/store-info.md` and the README's privacy statements, including that the cloud settings, usage totals and key information are kept in the app preferences. #71 adds the consent step. Until then the client reports offline in an Android release build.
- #64 maps each `CloudError` case to its signal; #65 consumes `CloudCompletion.words` (or `fragments` for JSON) and calls `cancel()` from the gesture.

## Workflow follow-up

- Try a real OpenRouter key on a phone once #63 can enter one (and the `INTERNET` permission is in), and write the time to the first word on LTE in the pull request of #63.
- Archive the change after the pull request is merged (CONTRIBUTING.md).
