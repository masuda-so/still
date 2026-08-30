import Foundation

/// Maps verified StoreKit entitlements to Still's product access.
enum StillAccessPolicy {
  /// Returns the access level granted by the current entitlements.
  static func accessLevel(
    for entitlements: EntitlementSnapshot,
    at date: Date = .now
  ) -> AccessLevel {
    grantsProAccess(for: entitlements, at: date) ? .pro : .free
  }

  /// Returns whether the current entitlements grant Pro access.
  static func grantsProAccess(
    for entitlements: EntitlementSnapshot,
    at date: Date = .now
  ) -> Bool {
    entitlements.hasPremiumAccess(in: StillCommerceCatalog.catalog, at: date)
  }
}
