# Still release readiness

This document defines the current release scope and remaining gates. It does not
set a submission or public-release date. Because the implementation and project
configuration have changed, all technical checks below must be rerun against the
current tree before submission.

## Implemented v1

- iOS 18 minimum deployment target, iPhone/iPad support, Swift 6 app and tests.
- Local SwiftData pause history with explicit start/end, deletion, transaction
  rollback, and error presentation.
- On-device Foundation Models adapter with availability/language fallback,
  cancellation, stable errors, and no remote AI provider.
- StoreKit 2 product loading, purchase, restore, verified entitlements, finishing,
  updates, revocation filtering, and device-clock expiry policy.
- Non-renewing Daily Pass plus Monthly and Yearly plans, local StoreKit fixtures,
  privacy manifest, English/Japanese String Catalogs, legal documents, tests,
  and third-party notices.

## Current technical gate

Use an Apple-supported stable Xcode release and compatible SDK/runtime. Run
static inspection, build, non-StoreKit tests, Analyze, then Archive and bundle
inspection serially against the current source.

- [ ] Swift formatting and project/resource/asset parsing pass.
- [ ] Privacy manifest, Required Reason API, localization, and production
      legal-URL checks pass.
- [ ] Debug and Release builds pass with the final stable toolchain.
- [ ] Non-StoreKit tests pass without unexpected failures or skips.
- [ ] Release Analyze passes for the app target.
- [ ] A release Archive is inspected for identity, minimum OS, localization,
      privacy manifest, icon assets, and absence of StoreKit/test payloads.
- [ ] StoreKit end-to-end scenarios pass on a compatible runtime, physical
      device, or TestFlight environment.

## App Store gates

- Confirm the App Store Connect record, distribution team/signing, version/build,
  and provisioning for `llc.ether.still`.
- Create/localize the three products, place Monthly/Yearly in one subscription
  group, confirm production price/availability/tax/review data, and submit initial
  product types with the app as required.
- Pass unskipped product loading, purchase/finish, unfinished transaction,
  restore, Daily boundary, Ask to Buy, refund, repurchase, and auto-renew
  cancellation scenarios.
- Verify the shipped Privacy, Terms, and Support URLs anonymously; reconcile App
  Privacy, Required Reason APIs, export compliance, age rating, and
  content-rights answers with the final Archive.
- Complete distribution-signed Archive, validation, TestFlight, compatible-device
  purchase/restore/expiry checks, and final human UI/content/accessibility review.

## Icon disposition

Use the current layered `still/Resources/AppIcon.icon`, whose foreground is the
non-SF-Symbol `still-selected-source.png`. The final stable Icon Composer must
render the required iOS appearances and the Archive must contain the compiled
icon. Inspect the submitted rendering; App Review makes the final determination.

## External or human blockers

Only Apple credentials/signing, App Store Connect state, an Apple-compatible
StoreKit environment, TestFlight/physical-device verification, public legal and
support URL acceptance, and final legal/content/accessibility/UI judgment may
remain external. No signing, validation, upload, release, deployment,
publication, or external message is authorized by this document.
