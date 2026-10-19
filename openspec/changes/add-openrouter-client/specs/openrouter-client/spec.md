## Purpose

How the app talks to the cloud: the streamed chat-completion request to OpenRouter (or another OpenAI-compatible endpoint) with the assistant's key, the settings it honours, how the answer becomes words, how it times out, is cancelled and fails, and what it counts on the device.

## ADDED Requirements

### Requirement: Chat completion request
A cloud request SHALL be `POST {base URL}/chat/completions` with a JSON body holding the messages, `model` (the first model of the request's fallback list), `models` (the whole list, in order), `stream: true` and `temperature: 0`. When the caller asks for JSON it SHALL add `response_format: {"type": "json_object"}`. Redirects SHALL NOT be followed.

#### Scenario: Body of a request
- **WHEN** a request with a system and a user message and the models `a/one` and `b/two` is sent
- **THEN** the body SHALL contain the two messages in order, `model` `a/one`, `models` `["a/one", "b/two"]`, `stream` `true` and `temperature` `0`
- **AND** it SHALL contain no `response_format`

#### Scenario: JSON answer asked for
- **WHEN** the caller asks for a JSON answer
- **THEN** the body SHALL contain `response_format` `{"type": "json_object"}`

#### Scenario: Redirect
- **WHEN** the endpoint answers with a redirect
- **THEN** the request SHALL fail with the other error and its status code, and nothing SHALL be sent to the redirect's target

### Requirement: Request headers
Every cloud request, including the key-info request, SHALL carry `Authorization: Bearer <key>` with the saved cloud key, `HTTP-Referer: https://github.com/nullhtp/feel-you` and `X-Title: Feel You`. The chat request SHALL also send `Content-Type: application/json` and `Accept: text/event-stream`.

#### Scenario: Headers of a request
- **WHEN** a request is sent with a key saved
- **THEN** it SHALL carry the key after `Bearer `, the referer and the title above

### Requirement: No key, no request
When no cloud key is saved, a cloud request and a key-info request SHALL fail with the no-key error without sending anything.

#### Scenario: Request without a key
- **WHEN** a request is made and no key is saved
- **THEN** it SHALL fail with the no-key error
- **AND** the endpoint SHALL receive nothing

### Requirement: Requests only when a feature asks
The app SHALL send a cloud request or a key-info request only when a feature asks for one. It SHALL send none at launch, in the background or on its own schedule.

#### Scenario: Launch
- **WHEN** the app is launched with a key saved
- **THEN** the endpoint SHALL receive no request until a feature asks for one

### Requirement: Base URL setting
The base URL SHALL be `https://openrouter.ai/api/v1` until another one is set. A new one SHALL be accepted only with the `https` scheme, or `http` when the host is `localhost`, `127.0.0.1` or `::1`, and only with a host and no user name, password, query or fragment. A trailing `/` SHALL be dropped. It SHALL be saved on the device and kept until it is set again or reset.

#### Scenario: Default
- **WHEN** no base URL has been set
- **THEN** requests SHALL go to `https://openrouter.ai/api/v1/chat/completions`

#### Scenario: Custom endpoint
- **WHEN** the base URL is set to `https://example.com/v1/` and the app is restarted
- **THEN** requests SHALL go to `https://example.com/v1/chat/completions`

#### Scenario: Plain HTTP
- **WHEN** the base URL `http://example.com/v1` is set
- **THEN** it SHALL be rejected and the base URL SHALL stay as it was
- **AND** `http://127.0.0.1:8080/v1`, `http://localhost/v1` and `http://[::1]:8080/v1` SHALL be accepted

#### Scenario: Credentials or query in the URL
- **WHEN** the base URL has a user name, a password, a query or a fragment
- **THEN** it SHALL be rejected

#### Scenario: Reset
- **WHEN** the base URL is reset
- **THEN** it SHALL be `https://openrouter.ai/api/v1` again

### Requirement: Data collection setting
The "deny data collection" setting SHALL be on until it is turned off, and saved on the device. While it is on, a cloud request SHALL carry `provider: {"data_collection": "deny"}`, so only providers that do not store or train on the data serve it. While it is off, the request SHALL carry no `provider` field.

#### Scenario: Default
- **WHEN** the setting has never been changed
- **THEN** a request SHALL carry `provider` `{"data_collection": "deny"}`

#### Scenario: Turned off
- **WHEN** the setting is turned off and the app is restarted
- **THEN** a request SHALL carry no `provider` field

### Requirement: Streamed answer
The answer SHALL be read as server-sent events: `data:` lines (one space after the colon dropped) joined with line breaks until a blank line ends the event; comment lines (starting with `:`), other fields and events that are not JSON SHALL be skipped. Each event's `choices[0].delta.content` SHALL be the next piece of the answer. `data: [DONE]` SHALL end the answer.

#### Scenario: OpenRouter stream
- **WHEN** the answer arrives as role, content, finish and usage chunks with `: OPENROUTER PROCESSING` comments between them, then `data: [DONE]`
- **THEN** the content pieces SHALL be delivered in order and the answer SHALL end normally

#### Scenario: Split anywhere
- **WHEN** the same stream arrives cut into chunks at arbitrary bytes, inside a line or a multi-byte character, with LF, CRLF or CR line ends
- **THEN** the same pieces SHALL be delivered

#### Scenario: Multi-line event
- **WHEN** an event has two `data:` lines
- **THEN** its data SHALL be the two values joined by a line break

#### Scenario: Unfinished last event
- **WHEN** the stream ends in the middle of an event, before its blank line
- **THEN** that event SHALL be dropped

#### Scenario: Ends without its end
- **WHEN** the connection ends before `data: [DONE]` and before a chunk with a finish reason
- **THEN** the answer SHALL fail with the offline error

### Requirement: Words as soon as they are complete
The answer SHALL be handed out as words, in order: a word SHALL be released as soon as whitespace follows it, and the last word when the answer ends normally. Whitespace SHALL NOT be part of a word; punctuation SHALL stay with its word. After an error or a cancellation the unfinished word SHALL be dropped.

#### Scenario: Words cut across pieces
- **WHEN** the pieces are `Hel`, `lo wor`, `ld, how` and ` are you?`
- **THEN** the words SHALL be `Hello`, `world,`, `how`, `are`, `you?`
- **AND** `Hello` SHALL be released before `ld, how` arrives

#### Scenario: Error mid-word
- **WHEN** `Hello wor` has arrived and the answer then fails
- **THEN** only `Hello` SHALL be released, followed by the error

### Requirement: First-token timeout
When the first piece of the answer has not arrived 5 s after the request was sent, the request SHALL fail with the timeout error and its connection SHALL be closed. Keep-alive comments, events without content and the response headers SHALL NOT count as the first piece.

#### Scenario: Only keep-alive comments
- **WHEN** the endpoint answers `200` and then sends only `: OPENROUTER PROCESSING` comments
- **THEN** the request SHALL fail with the timeout error 5 s after it was sent, and the connection SHALL be closed

#### Scenario: First token in time
- **WHEN** the first piece arrives within 5 s and the rest later
- **THEN** no timeout SHALL occur

### Requirement: Cancellation
A request SHALL be cancellable at any time. Cancelling SHALL close its connection, release no further word or piece and no error, and end the answer. Cancelling after the answer has ended SHALL do nothing. A listener that stops listening SHALL cancel the request the same way.

#### Scenario: Cancel mid-answer
- **WHEN** a request is cancelled after its first word
- **THEN** the endpoint SHALL see its connection closed
- **AND** no further word and no error SHALL be released

#### Scenario: Cancel before the answer
- **WHEN** a request is cancelled before the response has arrived
- **THEN** its connection SHALL be closed and nothing SHALL be released

### Requirement: Error cases
A failed request SHALL fail with exactly one of: offline (no connection, the name could not be resolved, refused, dropped, TLS failure), key rejected (401), limit exhausted (402), model unavailable (404, 502, 503), timeout (the first-token timeout, 408, 504), no key, or other with the status code (any other status, or none). An `error` object in the stream SHALL map by its type or code in the same way.

#### Scenario: Status codes
- **WHEN** the endpoint answers 401, 402, 404, 502, 503, 408, 504, 400 or 429
- **THEN** the request SHALL fail with, in order: key rejected, limit exhausted, model unavailable three times, timeout twice, other 400, other 429

#### Scenario: Every fallback model failed
- **WHEN** the endpoint answers `200` and its only event is an error with code 502 or type `provider_unavailable`
- **THEN** the request SHALL fail with model unavailable

#### Scenario: Error mid-answer
- **WHEN** words have arrived and an event then carries an `error` object with `finish_reason` `error`
- **THEN** the request SHALL fail with the error its code or type maps to, after the words already released

#### Scenario: No connection
- **WHEN** the endpoint refuses the connection, its name can't be resolved or it closes the connection mid-answer
- **THEN** the request SHALL fail with the offline error

### Requirement: No key or response body in errors and logs
Errors, their text and the app's logs about cloud requests SHALL NOT contain the key or any part of a response body. They SHALL name only the error case and, for the other error, the status code.

#### Scenario: Key rejected
- **WHEN** a request fails with key rejected and the response body repeats the key
- **THEN** the error's text and the logged message SHALL contain neither the key nor the body

### Requirement: Usage accounting
The `usage` of each answer (prompt, completion and total tokens, and `cost` when reported) SHALL be added to today's and this month's totals, with a count of answers, and saved on the device. Today SHALL start at local midnight and the month on the first day of the local calendar month; totals of an earlier day or month SHALL read as zero.

#### Scenario: Two answers
- **WHEN** two answers report 10 prompt and 5 completion tokens each, at a cost of 0.0002
- **THEN** today and this month SHALL each be 2 answers, 20 prompt, 10 completion and 30 total tokens, at a cost of 0.0004

#### Scenario: Survives a restart
- **WHEN** the app is restarted on the same day
- **THEN** the totals SHALL be the same

#### Scenario: Next day
- **WHEN** the next local day starts in the same month
- **THEN** today SHALL be zero and this month SHALL keep its totals

#### Scenario: Next month
- **WHEN** a new local month starts
- **THEN** today and this month SHALL both be zero

#### Scenario: No cost reported
- **WHEN** an answer reports tokens but no cost
- **THEN** its tokens SHALL be added and the cost SHALL stay as it was

### Requirement: Key information at most once a day
The key's limit, remaining limit and spend (all time, today, this month) SHALL be fetched with `GET {base URL}/key` and saved on the device with the time they were fetched and the masked key and base URL they belong to. When they were fetched on the same local day for the same key and base URL, the saved values SHALL be returned without a request. A failed fetch SHALL save nothing.

#### Scenario: Same day
- **WHEN** the key information is asked for twice on one day, with a restart in between
- **THEN** the endpoint SHALL receive one `GET /key`, and both answers SHALL be the same

#### Scenario: Next day
- **WHEN** it is asked for again on the next local day
- **THEN** it SHALL be fetched again

#### Scenario: Another key
- **WHEN** another key is saved and the key information is asked for on the same day
- **THEN** it SHALL be fetched for the new key

#### Scenario: Key rejected
- **WHEN** the endpoint answers `GET /key` with 401
- **THEN** the call SHALL fail with key rejected and nothing SHALL be saved
