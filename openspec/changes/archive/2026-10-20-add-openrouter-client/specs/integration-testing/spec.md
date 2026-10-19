## ADDED Requirements

### Requirement: Cloud client end-to-end test
An end-to-end test SHALL run the client in the app's own provider container on the device, with the key saved through the real secure storage and the base URL pointed through the real settings at an HTTP server on the device's loopback address, started by the test. It SHALL check `openrouter-client` over real connections. The test SHALL remove the key and the cloud settings and usage before and after it runs.

#### Scenario: Request and streamed words
- **WHEN** the server streams an answer in chunks, holding back the rest until the first word has been released
- **THEN** it SHALL have received the endpoint, headers and body of `openrouter-client`, including the data policy, and no request before the test asked
- **AND** the words SHALL arrive in order, the first before the rest was sent

#### Scenario: Timeout and cancellation
- **WHEN** the server sends only keep-alive comments, and in another request one word and then nothing
- **THEN** the first SHALL fail with the timeout error and the server SHALL see the connection closed
- **AND** cancelling the second SHALL close its connection with no further word or error

#### Scenario: Errors
- **WHEN** the server answers 401, 402, 404, a `200` with only an error event, closes the connection mid-answer, or its port refuses connections
- **THEN** the request SHALL fail with key rejected, limit exhausted, model unavailable twice and offline twice, and no error's text SHALL contain the key

#### Scenario: Usage and key information across a restart
- **WHEN** two answers report usage, the key information is asked for, the app is restarted and both are read again, and the clock is then moved to the next day
- **THEN** the totals SHALL survive the restart, the server SHALL have received one `GET /key` before the next day and a second one after it, and today's totals SHALL then be zero
