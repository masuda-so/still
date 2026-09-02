# Still

Still is a private pause timer with a local history of completed sessions and
optional on-device guidance.

## Main navigation

- Pauses
- Assistant
- Pro
- Settings

## Core experience

Completed pauses are stored on device with SwiftData. People can choose a
one-to-ten-minute duration, cancel a running pause without saving it, review
recent sessions, and delete individual history entries.

## Intelligence and commerce

The assistant uses Apple Foundation Models on supported devices and languages.
It does not use a remote AI provider. A valid one- or two-minute suggestion shows
its proposed length, and the timer starts only after the person reviews and
confirms it. The local StoreKit configuration defines the same three plan shapes
used by the app family:

- `llc.ether.still.pro.daily`: non-renewing 24-hour Daily Pass.
- `llc.ether.still.pro.monthly`: auto-renewable monthly plan.
- `llc.ether.still.pro.yearly`: auto-renewable yearly plan.

App Store Connect product records, production prices, and review metadata remain
external release tasks.

## Documentation

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
