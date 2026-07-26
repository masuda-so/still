/// Defines the StoreKit products and access durations sold by Still.
enum StillCommerceCatalog {
  nonisolated static let dailyPassProductID = "\(ProductIdentity.bundleIdentifier).pro.daily"
  nonisolated static let monthlyProductID = "\(ProductIdentity.bundleIdentifier).pro.monthly"
  nonisolated static let yearlyProductID = "\(ProductIdentity.bundleIdentifier).pro.yearly"

  nonisolated static let catalog: SubscriptionCatalog = {
    do {
      return try SubscriptionCatalog.validating(
        productIDs: [dailyPassProductID, monthlyProductID, yearlyProductID],
        premiumProductIDs: [dailyPassProductID, monthlyProductID, yearlyProductID],
        nonRenewingDurations: [dailyPassProductID: 24 * 60 * 60]
      )
    } catch {
      assertionFailure("Invalid Still subscription catalog: \(error)")
      return .empty
    }
  }()
}
