# Still App Store submission record

This is a working submission checklist, not a submission or public-release
date. Every technical item must be revalidated against the current tree and
final stable Xcode toolchain.

## App identity

- Name: Still
- Bundle ID: `llc.ether.still`
- Minimum deployment target: iOS 18.0
- Devices: iPhone and iPad
- Version/build baseline: 1.0 (1)
- Category, age rating, SKU, copyright, export compliance, content rights, and
  final name availability: human/App Store Connect decisions

## In-App Purchases

| Product ID | Type | Local contract |
| --- | --- | --- |
| `llc.ether.still.pro.daily` | Non-renewing subscription | Pro for 24 hours from the latest verified purchase date; no stacking |
| `llc.ether.still.pro.monthly` | Auto-renewable subscription | Pro while a verified entitlement is active |
| `llc.ether.still.pro.yearly` | Auto-renewable subscription | Pro while a verified entitlement is active |

Monthly and Yearly must be in one subscription group at the same level. Product
type, localization, pricing, availability, tax/category data, review screenshots,
and first-product submission require an App Store Connect user. The local
StoreKit file is test data and is excluded from the app bundle.

## Legal and support destinations

The shipped product definition points to Ether LLC's app-document routes:

- Privacy Policy: `https://ether-llc.com/apps/still/privacy/`
- Terms of Use: `https://ether-llc.com/apps/still/terms/`
- Support: `https://ether-llc.com/apps/still/support/`

Confirm anonymous mobile reachability after the production deployment and before
submission. If a URL changes, update the product definition, documentation,
tests, App Store Connect metadata, and final Archive together.

## Privacy and review notes

- Pause history stays in the local SwiftData store. Foundation Models requests
  run on device; no remote AI provider is configured.
- The privacy manifest currently declares no tracking, collected data, or listed
  Required Reason API use. Recheck source and the final Archive after every
  dependency or platform-API change.
- Explain the usable free pause/history path and that the assistant is optional,
  explicitly invoked, on-device, and availability-gated.
- Explain the non-renewing Daily Pass, restore, Manage Subscription, and verified
  entitlement behavior. No account or demo credentials are required.
- Prepare Still-specific screenshots and value proposition for guideline 4.3;
  verify localization, Dynamic Type, VoiceOver labels, contrast, iPad layout,
  cancellation, empty/error states, purchase, restore, and legal links.

## Icon record

Submit the current layered `still/Resources/AppIcon.icon`, which uses the
non-SF-Symbol `still-selected-source.png` foreground. Confirm the built icon at
required sizes and appearances using the final stable toolchain. Apple Developer
Support case `20000121467132` is historical correspondence; App Review makes the
final determination.

## Technical and external gates

- [ ] Static project, localization, privacy, Required Reason API, and public-URL
      checks pass against the current tree.
- [ ] Debug and Release builds pass using the final stable Xcode toolchain.
- [ ] Non-StoreKit tests pass without unexpected failure or skip.
- [ ] Analyze passes and the release Archive contents are inspected.
- [ ] Pass StoreKit end-to-end tests without skips on a compatible Apple runtime,
      device, or TestFlight environment.
- [ ] Complete distribution signing and App Store validation.
- [ ] Complete TestFlight purchase/restore/expiry and physical-device checks.
- [ ] Verify legal and support URLs and approve metadata, screenshots, privacy
      answers, IAPs, subscriptions, accessibility, and review notes.

Signing, validation, upload, TestFlight distribution, publication, and external
messages remain outside this task unless separately authorized. Record the
selected toolchain, test results, Archive inspection, and public-URL checks after
revalidation; do not reuse results from an earlier revision.
