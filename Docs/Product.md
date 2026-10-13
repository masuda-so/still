# Still

Still is a quiet pause app built around short, optional moments of rest. It includes
timed pause sessions and private local history.

## Initial navigation

- Pauses
- Assistant
- Pro
- Settings

## Commerce baseline

- `llc.ether.still.pro.daily`: non-renewing Daily Pass with 24 hours of access.
- `llc.ether.still.pro.monthly`: auto-renewable monthly plan.
- `llc.ether.still.pro.yearly`: auto-renewable yearly plan.

The Daily Pass never renews automatically. App Store Connect products and pricing
must be configured and reviewed before these plans can be sold.
Its 24-hour expiration is calculated locally from StoreKit's verified purchase date
and the device wall clock. This release doesn't use a server-authoritative clock.
The on-device assistant is the initial Pro capability; the core app remains usable
without a purchase. An active Daily Pass cannot be repurchased or stacked.

## Implementation ownership

- Apple Foundation Models provides on-device generation when the system supports it.
- Still owns its prompt construction and AI client implementation locally.
- Still owns its StoreKit integration locally, while Daily, Monthly, and Yearly retain the common plan shape used across the app family.
