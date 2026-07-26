/// Maps verified StoreKit entitlements to Still's product access.
enum StillAccessPolicy {
  /// Returns the access level granted by the current entitlements.
  static func accessLevel(for entitlements: EntitlementSnapshot) -> AccessLevel {
    hasProAccess(entitlements: entitlements) ? .pro : .free
  }

  /// Returns whether the current entitlements grant Pro access.
  static func hasProAccess(entitlements: EntitlementSnapshot) -> Bool {
    entitlements.hasPremiumAccess(in: StillCommerceCatalog.catalog)
  }
}
