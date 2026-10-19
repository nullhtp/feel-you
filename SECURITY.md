# Security Policy

Feel You is an assistive app. A security problem here can leave a deaf-blind person without their only channel to the world, or expose photos and conversations of the people around them. Please report problems privately.

## Supported versions

Only the latest release on GitHub, Google Play and the App Store receives fixes.

## Reporting a vulnerability

- Preferred: [open a private security advisory](https://github.com/nullhtp/feel-you/security/advisories/new) on GitHub.
- Or email the maintainer at null.htp@gmail.com with "Feel You security" in the subject.

Please include the app version, the platform, steps to reproduce and what an attacker could gain. You will get an acknowledgement within 7 days and a fix or a plan within 30 days for confirmed issues. Please do not open a public issue until a fix is released.

## What we consider in scope

- Anything that lets the app vibrate, call, send a message or spend money without the user's gesture (for example the emergency gesture or the cloud features).
- Leakage of the assistant's OpenRouter key or of photos, transcripts and messages handled by the app.
- Crashes or hangs that can be triggered from content the app reads (messages, OCR text, model answers).

## What is out of scope

- Vulnerabilities in OpenRouter or in the model providers themselves. Report those to them.
- Issues that require a rooted or jailbroken device, or physical access to an unlocked phone.
