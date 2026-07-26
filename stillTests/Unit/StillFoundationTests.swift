import Foundation
import SwiftData
import XCTest

@testable import still

final class StillFoundationTests: XCTestCase {
  @MainActor
  func testProductIdentityMatchesBundleConvention() {
    let product = ProductDefinition.still

    XCTAssertEqual(product.identifier, "still")
    XCTAssertEqual(product.bundleIdentifier, "llc.ether.\(product.identifier)")
    XCTAssertEqual(
      StillCommerceCatalog.dailyPassProductID,
      "\(product.bundleIdentifier).pro.daily"
    )
    XCTAssertEqual(
      StillCommerceCatalog.monthlyProductID,
      "\(product.bundleIdentifier).pro.monthly"
    )
    XCTAssertEqual(
      StillCommerceCatalog.yearlyProductID,
      "\(product.bundleIdentifier).pro.yearly"
    )
    XCTAssertEqual(
      StillCommerceCatalog.catalog.nonRenewingDurations[StillCommerceCatalog.dailyPassProductID],
      24 * 60 * 60
    )
    XCTAssertEqual(product.name, "Still")
    XCTAssertFalse(product.tagline.isEmpty)
  }

  @MainActor
  func testApplicationSectionsRemainDistinct() {
    let sections: Set<AppSection> = [.pauses, .assistant, .pro, .settings]

    XCTAssertEqual(sections.count, 4)
  }

  @MainActor
  func testDailyPassControlsProAccessAtExpiration() {
    let expiration = Date(timeIntervalSince1970: 100_000)
    let entitlements = EntitlementSnapshot(
      activeProductIDs: [StillCommerceCatalog.dailyPassProductID],
      expirationDates: [StillCommerceCatalog.dailyPassProductID: expiration]
    )

    XCTAssertTrue(
      entitlements.hasPremiumAccess(
        in: StillCommerceCatalog.catalog,
        at: expiration.addingTimeInterval(-1)
      )
    )
    XCTAssertFalse(
      entitlements.hasPremiumAccess(in: StillCommerceCatalog.catalog, at: expiration)
    )
  }

  func testExpirationDelayUsesInjectedCurrentDate() {
    let currentDate = Date(timeIntervalSince1970: 1_000)

    XCTAssertEqual(
      AppEnvironment.expirationDelay(
        until: currentDate.addingTimeInterval(60),
        from: currentDate
      ),
      .seconds(60)
    )
    XCTAssertEqual(
      AppEnvironment.expirationDelay(
        until: currentDate.addingTimeInterval(-1),
        from: currentDate
      ),
      .zero
    )
  }

  @MainActor
  func testDataContainerCreatesEditsAndDeletesPause() throws {
    let dataContainer = DataContainer(isStoredInMemoryOnly: true)
    let pause = Pause(duration: 60, startedAt: .now, endedAt: .now)

    dataContainer.context.insert(pause)
    try dataContainer.context.save()
    let saved = try XCTUnwrap(
      dataContainer.context.fetch(FetchDescriptor<Pause>()).first
    )
    saved.duration = 90
    try dataContainer.context.save()
    XCTAssertEqual(
      try dataContainer.context.fetch(FetchDescriptor<Pause>()).first?.duration,
      90
    )

    dataContainer.context.delete(saved)
    try dataContainer.context.save()
    XCTAssertTrue(try dataContainer.context.fetch(FetchDescriptor<Pause>()).isEmpty)
  }

  @MainActor
  func testFailedTransactionDiscardsPendingPause() throws {
    let dataContainer = DataContainer(isStoredInMemoryOnly: true)

    XCTAssertThrowsError(
      try dataContainer.context.transactionOrRollback {
        dataContainer.context.insert(Pause(duration: 60, startedAt: .now, endedAt: .now))
        throw CocoaError(.fileWriteNoPermission)
      }
    )

    XCTAssertTrue(try dataContainer.context.fetch(FetchDescriptor<Pause>()).isEmpty)
  }

  func testTransactionFailureTriggersRollback() {
    var didRollback = false

    XCTAssertThrowsError(
      try ModelContext.transactionOrRollback(
        transaction: { throw CocoaError(.fileWriteNoPermission) },
        rollback: { didRollback = true }
      )
    )
    XCTAssertTrue(didRollback)
  }
}
