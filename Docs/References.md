# Apple References

Still adapts naming and implementation patterns from Apple sample code. Product
behavior and data remain specific to Still.

## Product feature references

- [App Dev Tutorials](https://developer.apple.com/tutorials/app-dev-training):
  Scrumdinger’s `ScrumTimer`, view life-cycle handling, elapsed-time correction,
  progress presentation, and `CardView` naming.
- [Managing state and life cycle](https://developer.apple.com/tutorials/app-dev-training/managing-state-and-life-cycle):
  starting and stopping a timer with view appearance and disappearance.

## Family-wide references

- [Food Truck](https://github.com/apple/sample-food-truck/tree/3954a769e99f3cc53297d94f2b960ceb2665b3d6):
  `General`, `Navigation`, feature folders, and StoreKit transaction listeners.
- [Backyard Birds](https://github.com/apple/sample-backyard-birds/tree/1843d5655bf884b501e2889ad9862ec58978fdbe):
  app-specific feature folders, StoreKit configuration, and adaptive navigation.
- [ml-comlet](https://github.com/apple/ml-comlet/tree/c3811e7367c1a211698078c8ffbc11e282e3c794):
  `Services`, model separation, localization, and `Supporting Files`.
- [Foundation Models sample](https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models):
  availability handling, `LanguageModelSession`, instructions, and on-device privacy.

## Platform verification

- [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons/)
  and [Creating your app icon using Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer):
  `Resources/AppIcon.icon` is the sole primary app-icon source. Xcode renders the
  required platform, appearance, and legacy-size variants from its layered artwork.
- [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
  and [Managing your app’s information property list](https://developer.apple.com/documentation/bundleresources/managing-your-app-s-information-property-list):
  interface text uses `Localizable.xcstrings`; the localizable `CFBundleDisplayName`
  and `CFBundleName` values use the target-specific InfoPlist String Catalog.
- [Accessibility fundamentals](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals):
  the custom timer is exposed as one combined accessibility element.
- [Setting up StoreKit Testing in Xcode](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode/):
  local StoreKit configurations and scheme selection.
- [Transaction.currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements):
  the all-product sequence supplies verified current transactions, including the latest
  non-renewing purchase, and the client filters them against the app catalog.
- [Task cancellation and sleep](https://developer.apple.com/documentation/swift/task/):
  the Daily Pass monitor retains and cancels its task, uses a cancellable sleep, and
  receives the same injectable wall clock as entitlement calculation.
- [Handling subscriptions billing](https://developer.apple.com/documentation/storekit/handling-subscriptions-billing):
  app-owned duration, restoration, and cross-device responsibilities for a
  non-renewing subscription.
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/):
  role-based type names, labeled weakly typed parameters, clarity at the call site,
  fluent method names, and concise Markdown comments for reusable APIs.
- [Writing](https://developer.apple.com/design/human-interface-guidelines/writing):
  assistant and commerce diagnostics remain internal, while localized interface errors
  use plain language and give a clear retry action.
- [swift-format](https://github.com/swiftlang/swift-format):
  the Swift toolchain formatter and strict linter enforce the repository's pinned
  two-space indentation, import ordering, line length, documentation, and
  force-unwrap safety rules. Swift does not prescribe this as the only valid style;
  adopting one identical configuration across the five apps is a local consistency
  decision.

## Adopted implementation and local decisions

- [Foundation Models updates](https://developer.apple.com/documentation/updates/foundationmodels):
  iOS 27 error types replace the deprecated `GenerationError` API.
- [Supporting languages and locales](https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models):
  locale support is checked before sending a prompt.
- [Preserving SwiftData models](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches):
  `ModelContainer`, `ModelContext`, and `@Query` provide local persistence.
- [ModelContext transaction](https://developer.apple.com/documentation/swiftdata/modelcontext/transaction%28block%3A%29)
  and [rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback%28%29):
  user-initiated mutations run inside `transactionOrRollback(_:)`, so failures in either
  the changes or their save discard the complete pending unit before the app presents an
  error. The wrapper name and shared alert policy are family-wide implementation decisions.
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files):
  the manifest declares no tracking, collected data, or required-reason API use.

The default App Icon uses Still's accent color, a centered pause-and-ripple mark,
and no text, transparency, shadow, or pre-rendered mask. Dark and tinted artwork
remain optional design variants; until they are supplied, the asset catalog uses
the same default artwork. The mark and family color system are local design choices.

Apple doesn't prescribe one universal app-folder layout. Still therefore follows
the recurring official-sample pattern of app, model, service, resource, and
feature-specific groups. The Daily Pass is an app-owned policy: it uses StoreKit's
verified purchase date plus 24 hours and the device wall clock, without a server.

The downloaded samples include their own Apple or MIT license notices. Still adapts
the relevant patterns instead of redistributing any sample project unchanged.
