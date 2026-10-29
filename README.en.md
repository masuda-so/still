# Still

[日本語](README.md) | [English](README.en.md)

## Overview

Still is a private pause timer with a local history of completed sessions and
optional on-device guidance with active Pro access on supported devices and languages.

## Features and limitations

### Main navigation

- Pauses
- Assistant
- Pro
- Settings

### Core experience

Completed pauses are stored on device with SwiftData. People can choose a
one-to-ten-minute duration, end a running pause, review recent sessions, and
delete individual history entries.

### Intelligence and commerce

The assistant requires active Pro access and uses Apple Foundation Models on supported devices and languages.
It does not use a remote AI provider. The local StoreKit configuration defines
the same three plan shapes used by the app family:

- `llc.ether.still.pro.daily`: non-renewing 24-hour Daily Pass.
- `llc.ether.still.pro.monthly`: auto-renewable monthly plan.
- `llc.ether.still.pro.yearly`: auto-renewable yearly plan.

App Store Connect product records, production prices, and review metadata remain
external release tasks.

## Getting started and usage

Open `still.xcodeproj` in Xcode and select the shared `still` scheme.
See [repository structure and verification](Docs/Structure.md) for build and test guidance,
and [release gates](Docs/Release.md) for device and release requirements.
The local StoreKit configuration is for purchase testing, not proof of production availability.

## Support and documentation

- [Repository structure and verification](Docs/Structure.md)
- [Product scope](Docs/Product.md), [Privacy](Docs/Privacy.md), and
  [Terms](Docs/Terms.md)
- [Implementation references](Docs/References.md)
- [Release readiness](Docs/Release.md)
- [App Store submission record](Docs/App-Store-Submission.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)

Published public routes:

- `https://ether-llc.com/apps/still/privacy/`
- `https://ether-llc.com/apps/still/terms/`
- `https://ether-llc.com/apps/still/support/`

Signing, validation, upload, publication, and release are not repository-local
steps.

## Development and contributions

GitHub Actions requires product loading and eight purchase-related scenarios to pass in a dedicated StoreKit workflow alongside normal CI. The unfinished-transaction stream scenario still runs separately with strict same-transaction finish verification, but its result and artifacts are observational rather than part of the pass/fail gate. Logs show slow storekitd synchronization and changing cache revisions; the root cause remains unresolved. A green job does not mean all nine scenarios passed or notification handling is fixed. See [tracking and coverage](Docs/Structure.md#unresolved-stream-validation). Physical-device and production-store behavior require separate validation.

Use the support route above for product help. For repository changes, consult the
implementation references and release gates linked above, and describe the change
and its validation in a pull request. PR descriptions and review comments use Japanese by default; an explicit request for another language takes precedence.

See [AGENTS.md](AGENTS.md) for shared repository instructions.
