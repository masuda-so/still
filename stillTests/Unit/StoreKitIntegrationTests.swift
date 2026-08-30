import StoreKit
import StoreKitTest
import XCTest

@testable import still

/// End-to-end checks that run against the local StoreKit configuration.
final class StoreKitIntegrationTests: XCTestCase {
  @MainActor
  func testConfiguredProductsLoadWithProductionIdentifiers() async throws {
    let session = try makeSession()
    defer { session.clearTransactions() }

    let client = StoreKitSubscriptionClient(catalog: StillCommerceCatalog.catalog)
    let products = try await client.loadProducts()
    let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

    XCTAssertEqual(Set(productsByID.keys), StillCommerceCatalog.catalog.productIDs)
    XCTAssertEqual(
      productsByID[StillCommerceCatalog.dailyPassProductID]?.renewal,
      .manual(accessDuration: Self.dailyPassDuration)
    )
    XCTAssertEqual(
      productsByID[StillCommerceCatalog.monthlyProductID]?.renewal,
      .automatic
    )
    XCTAssertEqual(
      productsByID[StillCommerceCatalog.yearlyProductID]?.renewal,
      .automatic
    )
  }

  @MainActor
  func testClientPurchaseReturnsVerifiedEntitlement() async throws {
    let session = try makeSession()
    defer { session.clearTransactions() }

    let client = StoreKitSubscriptionClient(catalog: StillCommerceCatalog.catalog)
    _ = try await client.loadProducts()
    let outcome = try await client.purchase(
      productID: StillCommerceCatalog.monthlyProductID
    )

    guard case .purchased(let entitlements) = outcome else {
      return XCTFail("Expected StoreKit to complete the purchase.")
    }
    XCTAssertTrue(
      entitlements.activeProductIDs.contains(StillCommerceCatalog.monthlyProductID)
    )

    var unfinishedProductIDs: Set<String> = []
    for await result in Transaction.unfinished {
      if case .verified(let transaction) = result {
        unfinishedProductIDs.insert(transaction.productID)
      }
    }
    XCTAssertFalse(unfinishedProductIDs.contains(StillCommerceCatalog.monthlyProductID))
  }

  @MainActor
  func testEntitlementUpdatesProcessesAndFinishesUnfinishedTransaction() async throws {
    let session = try makeSession()
    defer { session.clearTransactions() }

    _ = try await session.buyProduct(identifier: StillCommerceCatalog.monthlyProductID)

    var unfinishedProductIDs: Set<String> = []
    for await result in Transaction.unfinished {
      if case .verified(let transaction) = result {
        unfinishedProductIDs.insert(transaction.productID)
      }
    }
    XCTAssertTrue(unfinishedProductIDs.contains(StillCommerceCatalog.monthlyProductID))

    let client = StoreKitSubscriptionClient(catalog: StillCommerceCatalog.catalog)
    let updates = await client.entitlementUpdates()
    var iterator = updates.makeAsyncIterator()
    let snapshot = await iterator.next()

    XCTAssertTrue(
      snapshot?.activeProductIDs.contains(StillCommerceCatalog.monthlyProductID) == true
    )

    unfinishedProductIDs.removeAll()
    for await result in Transaction.unfinished {
      if case .verified(let transaction) = result {
        unfinishedProductIDs.insert(transaction.productID)
      }
    }
    XCTAssertFalse(unfinishedProductIDs.contains(StillCommerceCatalog.monthlyProductID))
  }

  @MainActor
  func testRestoreSynchronizesPurchasedEntitlementIntoFreshClient() async throws {
    let session = try makeSession()
    defer { session.clearTransactions() }

    _ = try await session.buyProduct(identifier: StillCommerceCatalog.yearlyProductID)
    let client = StoreKitSubscriptionClient(catalog: StillCommerceCatalog.catalog)
    let restored = try await client.restorePurchases()

    XCTAssertTrue(
      restored.activeProductIDs.contains(StillCommerceCatalog.yearlyProductID)
    )
  }

  @MainActor
  func testDailyPassUsesPurchaseDateAndInjectedClockAtBoundary() async throws {
    let session = try makeSession()
    defer { session.clearTransactions() }

    let requestedPurchaseDate = Date(timeIntervalSince1970: 1_750_000_000)
    let transaction = try await session.buyProduct(
      identifier: StillCommerceCatalog.dailyPassProductID,
      options: [.purchaseDate(requestedPurchaseDate)]
    )
    XCTAssertEqual(
      transaction.purchaseDate.timeIntervalSince1970,
      requestedPurchaseDate.timeIntervalSince1970,
      accuracy: 0.001
    )

    let expiration = transaction.purchaseDate.addingTimeInterval(Self.dailyPassDuration)
    let beforeExpiration = await entitlementSnapshot(at: expiration.addingTimeInterval(-0.001))
    let atExpiration = await entitlementSnapshot(at: expiration)
    let afterExpiration = await entitlementSnapshot(at: expiration.addingTimeInterval(0.001))

    XCTAssertEqual(
      beforeExpiration.expirationDates[StillCommerceCatalog.dailyPassProductID],
      expiration
    )
    XCTAssertTrue(
      beforeExpiration.activeProductIDs.contains(StillCommerceCatalog.dailyPassProductID)
    )
    XCTAssertFalse(
      atExpiration.activeProductIDs.contains(StillCommerceCatalog.dailyPassProductID)
    )
    XCTAssertFalse(
      afterExpiration.activeProductIDs.contains(StillCommerceCatalog.dailyPassProductID)
    )
  }

  @MainActor
  func testAskToBuyReturnsPendingPurchaseOutcome() async throws {
    let session = try makeSession()
    session.askToBuyEnabled = true
    defer { session.clearTransactions() }

    let client = StoreKitSubscriptionClient(catalog: StillCommerceCatalog.catalog)
    _ = try await client.loadProducts()
    let outcome = try await client.purchase(
      productID: StillCommerceCatalog.monthlyProductID
    )

    XCTAssertEqual(outcome, .pending)
  }

  @MainActor
  func testRefundRemovesMonthlyEntitlement() async throws {
    let session = try makeSession()
    defer { session.clearTransactions() }

    _ = try await session.buyProduct(identifier: StillCommerceCatalog.monthlyProductID)
    let client = StoreKitSubscriptionClient(catalog: StillCommerceCatalog.catalog)
    let purchased = await client.currentEntitlements()
    XCTAssertTrue(
      purchased.activeProductIDs.contains(StillCommerceCatalog.monthlyProductID)
    )

    let transaction = try testTransaction(
      in: session,
      productID: StillCommerceCatalog.monthlyProductID
    )
    _ = try session.refundTransaction(identifier: transaction.identifier)

    let refunded = await client.currentEntitlements()
    XCTAssertFalse(
      refunded.activeProductIDs.contains(StillCommerceCatalog.monthlyProductID)
    )
  }

  @MainActor
  func testDailyPassRepurchaseUsesLatestSignedPurchaseDate() async throws {
    let session = try makeSession()
    defer { session.clearTransactions() }

    let firstPurchaseDate = Date(timeIntervalSince1970: 1_750_000_000)
    let secondPurchaseDate = firstPurchaseDate.addingTimeInterval(60 * 60)
    let firstTransaction = try await session.buyProduct(
      identifier: StillCommerceCatalog.dailyPassProductID,
      options: [.purchaseDate(firstPurchaseDate)]
    )
    let secondTransaction = try await session.buyProduct(
      identifier: StillCommerceCatalog.dailyPassProductID,
      options: [.purchaseDate(secondPurchaseDate)]
    )

    XCTAssertEqual(
      firstTransaction.purchaseDate.timeIntervalSince1970,
      firstPurchaseDate.timeIntervalSince1970,
      accuracy: 0.001
    )
    XCTAssertEqual(
      secondTransaction.purchaseDate.timeIntervalSince1970,
      secondPurchaseDate.timeIntervalSince1970,
      accuracy: 0.001
    )

    let expectedExpiration = secondTransaction.purchaseDate.addingTimeInterval(
      Self.dailyPassDuration
    )
    let evaluationDate = secondTransaction.purchaseDate.addingTimeInterval(1)
    let client = StoreKitSubscriptionClient(
      catalog: StillCommerceCatalog.catalog,
      now: { evaluationDate }
    )
    let entitlements = await client.currentEntitlements()

    XCTAssertEqual(
      entitlements.expirationDates[StillCommerceCatalog.dailyPassProductID],
      expectedExpiration
    )
    XCTAssertTrue(
      entitlements.activeProductIDs.contains(StillCommerceCatalog.dailyPassProductID)
    )
  }

  @MainActor
  func testDisablingAutoRenewKeepsAccessUntilSubscriptionExpires() async throws {
    let session = try makeSession()
    defer { session.clearTransactions() }

    _ = try await session.buyProduct(identifier: StillCommerceCatalog.monthlyProductID)
    let transaction = try testTransaction(
      in: session,
      productID: StillCommerceCatalog.monthlyProductID
    )
    let client = StoreKitSubscriptionClient(catalog: StillCommerceCatalog.catalog)

    _ = try session.disableAutoRenewForTransaction(identifier: transaction.identifier)
    let afterDisablingAutoRenew = await client.currentEntitlements()
    XCTAssertTrue(
      afterDisablingAutoRenew.activeProductIDs.contains(
        StillCommerceCatalog.monthlyProductID
      )
    )

    _ = try session.expireSubscription(
      productIdentifier: StillCommerceCatalog.monthlyProductID
    )
    let afterExpiration = await client.currentEntitlements()
    XCTAssertFalse(
      afterExpiration.activeProductIDs.contains(StillCommerceCatalog.monthlyProductID)
    )
  }

  private static let dailyPassDuration: TimeInterval = 24 * 60 * 60

  private func makeSession() throws -> SKTestSession {
    let session = try SKTestSession(contentsOf: storeKitConfigurationURL)
    session.resetToDefaultState()
    session.clearTransactions()
    session.disableDialogs = true
    return session
  }

  private func testTransaction(
    in session: SKTestSession,
    productID: String
  ) throws -> SKTestTransaction {
    try XCTUnwrap(
      session.allTransactions().first { $0.productIdentifier == productID }
    )
  }

  @MainActor
  private func entitlementSnapshot(at date: Date) async -> EntitlementSnapshot {
    let client = StoreKitSubscriptionClient(
      catalog: StillCommerceCatalog.catalog,
      now: { date }
    )
    return await client.currentEntitlements()
  }

  private var storeKitConfigurationURL: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("still", isDirectory: true)
      .appendingPathComponent("Resources", isDirectory: true)
      .appendingPathComponent("StoreKit", isDirectory: true)
      .appendingPathComponent("StoreKit.storekit", isDirectory: false)
  }
}
