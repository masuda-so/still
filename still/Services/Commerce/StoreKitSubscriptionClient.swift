import Foundation
import StoreKit

/// A StoreKit 2 client that derives access only from verified transactions.
actor StoreKitSubscriptionClient: SubscriptionClient {
  private let catalog: SubscriptionCatalog
  private let now: @Sendable () -> Date
  private var productsByID: [String: Product] = [:]

  /// Creates a StoreKit client with an injectable wall clock for entitlement checks.
  init(
    catalog: SubscriptionCatalog,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.catalog = catalog
    self.now = now
  }

  func loadProducts() async throws -> [SubscriptionProduct] {
    do {
      let products = try await Product.products(for: catalog.productIDs)
        .filter(isSupportedProduct)
        .sorted { $0.price < $1.price }
      productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
      return products.map(subscriptionProduct(from:))
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      throw SubscriptionError.storeUnavailable(
        debugDescription: String(describing: error)
      )
    }
  }

  func purchase(productID: String) async throws -> PurchaseOutcome {
    let product: Product
    if let loadedProduct = productsByID[productID] {
      product = loadedProduct
    } else {
      _ = try await loadProducts()
      guard let loadedProduct = productsByID[productID] else {
        throw SubscriptionError.unknownProduct(productID: productID)
      }
      product = loadedProduct
    }

    do {
      let result = try await product.purchase()
      switch result {
      case .success(let verification):
        let transaction = try Self.verifiedValue(from: verification)
        let entitlements = await currentEntitlements()
        await transaction.finish()
        return .purchased(entitlements)
      case .pending:
        return .pending
      case .userCancelled:
        return .userCancelled
      @unknown default:
        throw SubscriptionError.storeUnavailable(
          debugDescription: "Unknown purchase result."
        )
      }
    } catch is CancellationError {
      throw CancellationError()
    } catch let error as SubscriptionError {
      throw error
    } catch {
      throw SubscriptionError.storeUnavailable(
        debugDescription: String(describing: error)
      )
    }
  }

  func currentEntitlements() async -> EntitlementSnapshot {
    var activeProductIDs: Set<String> = []
    var expirationDates: [String: Date] = [:]
    let currentDate = now()

    for await result in Transaction.currentEntitlements {
      guard case .verified(let transaction) = result,
        catalog.productIDs.contains(transaction.productID),
        transaction.revocationDate == nil
      else {
        continue
      }

      switch transaction.productType {
      case .autoRenewable where !transaction.isUpgraded:
        activeProductIDs.insert(transaction.productID)
        if let expirationDate = transaction.expirationDate {
          expirationDates[transaction.productID] = expirationDate
        }
      case .nonRenewable:
        guard
          let expirationDate = catalog.activeExpirationDate(
            for: transaction.productID,
            purchasedAt: transaction.purchaseDate,
            at: currentDate
          )
        else {
          continue
        }
        activeProductIDs.insert(transaction.productID)
        expirationDates[transaction.productID] = max(
          expirationDates[transaction.productID] ?? .distantPast,
          expirationDate
        )
      default:
        continue
      }
    }

    return EntitlementSnapshot(
      activeProductIDs: activeProductIDs,
      expirationDates: expirationDates,
      refreshedAt: currentDate
    )
  }

  func restorePurchases() async throws -> EntitlementSnapshot {
    do {
      try await AppStore.sync()
      return await currentEntitlements()
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      throw SubscriptionError.storeUnavailable(
        debugDescription: String(describing: error)
      )
    }
  }

  func entitlementUpdates() async -> AsyncStream<EntitlementSnapshot> {
    let relevantProductIDs = catalog.productIDs

    return AsyncStream { continuation in
      let task = Task {
        continuation.yield(await self.currentEntitlements())

        for await result in Transaction.updates {
          guard !Task.isCancelled else { break }
          guard case .verified(let transaction) = result,
            relevantProductIDs.contains(transaction.productID)
          else {
            continue
          }
          let entitlements = await self.currentEntitlements()
          continuation.yield(entitlements)
          await transaction.finish()
        }

        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  /// Returns a signed value and rejects transactions StoreKit can't verify.
  nonisolated static func verifiedValue<Value>(
    from result: VerificationResult<Value>
  ) throws -> Value {
    switch result {
    case .verified(let value):
      return value
    case .unverified:
      throw SubscriptionError.failedVerification
    }
  }

  private func isSupportedProduct(_ product: Product) -> Bool {
    switch product.type {
    case .autoRenewable:
      return catalog.nonRenewingDurations[product.id] == nil
    case .nonRenewable:
      return catalog.nonRenewingDurations[product.id] != nil
    default:
      return false
    }
  }

  private func subscriptionProduct(from product: Product) -> SubscriptionProduct {
    let renewal: SubscriptionRenewal
    if let duration = catalog.nonRenewingDurations[product.id] {
      renewal = .manual(accessDuration: duration)
    } else {
      renewal = .automatic
    }

    return SubscriptionProduct(
      id: product.id,
      displayName: product.displayName,
      description: product.description,
      displayPrice: product.displayPrice,
      renewal: renewal
    )
  }
}
