# Still release readiness

## Implemented foundation

- iOS 18 minimum deployment target with iPhone and iPad support.
- Swift 6 application and test targets.
- Opaque 1,024-pixel App Icon artwork connected to the `AppIcon` asset catalog.
- Privacy manifest and on-device Foundation Models availability fallback.
- Verified StoreKit 2 loading, purchase, restore, and entitlement updates.
- A local StoreKit configuration selected by the shared scheme, with English and Japanese product metadata.
- In-app Privacy Policy, Terms of Use, purchase restoration, and subscription-management links.
- Non-renewing Daily Pass: `llc.ether.still.pro.daily` (24 hours).
- Auto-renewing plans: `llc.ether.still.pro.monthly` and `llc.ether.still.pro.yearly`.
- The on-device assistant is available only with active Pro access.

## Required before App Store submission

- Approve the supplied App Icon artwork and inspect its system-masked appearance,
  legibility, and optional dark/tinted variants on Device Hub and physical devices.
- Confirm production prices, create and localize all three products in App Store
  Connect, and place Monthly and Yearly in one subscription group at the same level.
- Add automated StoreKit Test coverage for purchase, pending, cancellation, restore,
  refund, expiration, and repurchase.
- Publish the included Privacy Policy and Terms of Use at stable public URLs, then
  add those URLs to App Store Connect metadata.
- Confirm that the documented device-clock policy for the non-renewing pass is acceptable for release.
- Define and test any required migration from a previously shipped data schema.
- Validate the release archive with an App Store-supported stable Xcode toolchain.

The Daily Pass does not auto-renew and cannot be stacked while it is active.
