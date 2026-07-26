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
one-to-ten-minute duration, end a running pause, review recent sessions, and
delete individual history entries.

## Intelligence and commerce

The assistant uses Apple Foundation Models on supported devices and languages.
It does not use a remote AI provider. The local StoreKit configuration defines
the same three plan shapes used by the app family:

- `llc.ether.still.pro.daily`: non-renewing 24-hour Daily Pass.
- `llc.ether.still.pro.monthly`: auto-renewable monthly plan.
- `llc.ether.still.pro.yearly`: auto-renewable yearly plan.

App Store Connect product records, production prices, and review metadata remain
external release tasks.
