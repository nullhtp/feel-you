# Contributing to Feel You

Thank you for helping build a phone that deaf-blind people can use on their own. This page explains how the project is organised and how to get a change in. The code of conduct is in [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md); security problems go through [SECURITY.md](SECURITY.md).

## Where things are

| | |
|---|---|
| What the app does today | [README.md](README.md) |
| Where it is going | [ROADMAP.md](ROADMAP.md), the [milestones](https://github.com/nullhtp/feel-you/milestones) and their epics |
| How to build, run and test | [app/README.md](app/README.md) |
| Behaviour specifications | `openspec/specs/` (one folder per capability) |
| Changes in progress | `openspec/changes/` |
| Release notes | [CHANGELOG.md](CHANGELOG.md) |

## Ways to help

- **Test without sight or hearing.** Blindfold, earplugs, a real phone. Report where you got lost. If you are deaf-blind yourself, or work with deaf-blind people, your feedback matters most: open an [accessibility feedback](https://github.com/nullhtp/feel-you/issues/new?template=accessibility_feedback.yml) issue or write to the maintainer.
- **Pick an issue.** Start with [good first issues](https://github.com/nullhtp/feel-you/issues?q=is%3Aissue%20is%3Aopen%20label%3A%22good%20first%20issue%22). Issues labelled `help wanted` need skills the core team lacks (user research, languages, device access). Comment on the issue before starting so two people do not do the same work.
- **Add a language or phrases.** Alphabets live in `app/lib/morse/`; each is a registry entry with letters, digits, twenty words and a language identifier. See the archived change `openspec/changes/archive/2026-03-24-add-russian-morse` for a complete example.
- **Report a bug.** Use the [bug template](https://github.com/nullhtp/feel-you/issues/new?template=bug_report.yml) and say which phone: vibration motors differ, and the companion overlay's `Vibration:` line tells us what yours can do.

## How work is organised

- The roadmap is seven phases. Each phase is a **milestone** with an **epic** issue (label `epic`) listing its tasks. Tasks are linked with `Depends on` / `Blocks` and GitHub's sub-issue and dependency relations, so an issue's page shows what must land first.
- Labels: `phase-N` says where an issue sits; `track: users` / `track: content` / `track: devices` mark work that runs alongside the phases; area labels (`vibration`, `gestures`, `cloud`, `i18n`, `security`) say what it touches.
- A phase is done when its **gate** passes (see the milestone description). Gates are tested blindfolded, following `docs/testing/blindfold-protocol.md` once it exists (#50).

## Making a change

Feel You uses [OpenSpec](https://github.com/Fission-AI/OpenSpec): behaviour is specified before it is built, and the specs stay in sync with the app.

1. **Discuss first** for anything that changes a gesture, a signal or a level: those are things users have already learned. Open or comment on an issue.
2. **Propose an OpenSpec change** under `openspec/changes/<name>/` with `proposal.md`, `design.md` (when the design is not obvious), delta specs and `tasks.md`. With Claude Code or opencode the `/opsx:propose` command scaffolds all of it. Run `openspec validate --strict` before pushing.
3. **Branch** from `master`; one change per branch. Name it after the change (`feat/text-reader`, `fix/stale-input`).
4. **Code** in `app/`. Follow the existing structure (`lib/<area>/`), keep timing constants in the config classes, and keep anything the user feels (durations, gaps, signal shapes) in `openspec/specs/` too.
5. **Test.** Unit and widget tests in `app/test/`, integration tests in `app/integration_test/`. New behaviour needs tests; changed timings need updated ones. CI runs `dart format`, `flutter analyze` and `flutter test`.
6. **Feel it on a phone.** Simulators report no motor and emulators cannot be felt. Before asking for review, run the change on a real device, blindfolded if it touches the user's flow.
7. **Open a pull request** against `master` using the template. Link the issue, say which devices you tested on, and add a line to `CHANGELOG.md` under `[Unreleased]`.
8. **Archive the change** when the PR is merged (`/opsx:archive`), which syncs the delta specs into `openspec/specs/`.

## Style

- Dart: `dart format`, [very_good_analysis](https://pub.dev/packages/very_good_analysis) lints, no warnings.
- Commits: `type(scope): what changed` in the imperative (`feat: add the text reader`, `fix: ignore a tap during feedback`). Keep the first line under 72 characters.
- Prose in the repository is in English. Alphabets, words and phrases are in their own language; word lists need a native-speaker review.

## Design rules that pull requests are checked against

These come from the [roadmap principles](ROADMAP.md#the-road-ahead):

- Nothing the user needs works only with sight, hearing, a network or a key.
- The app never advances on its own; the user swipes.
- Every state change the user cannot see has a vibration signal, and no two signals are the same.
- Amplitude never carries meaning; timing does.
- Anything a sighted helper must see is on the assistant screen or the companion overlay, and the user gets a signal when it opens.

## Licence

By contributing you agree that your contribution is licensed under the [MIT licence](LICENSE) like the rest of the project.
