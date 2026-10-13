import Foundation
import SwiftData
import SwiftUI
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
  func testLegalURLsMatchPublishedRoutesAndLocale() {
    let product = ProductDefinition.still
    let base = "https://ether-llc.com/apps/\(product.identifier)"
    let urls = [
      (product.privacyPolicyURL, "privacy"),
      (product.termsOfUseURL, "terms"),
      (product.supportURL, "support"),
    ]

    for (url, route) in urls {
      XCTAssertEqual(url.absoluteString, "\(base)/\(route)/")
      XCTAssertEqual(
        product.localizedLegalURL(url, for: Locale(identifier: "en_US")),
        url
      )

      let japaneseURL = product.localizedLegalURL(
        url,
        for: Locale(identifier: "ja_JP")
      )
      XCTAssertEqual(
        japaneseURL.absoluteString,
        "https://ether-llc.com/ja/apps/\(product.identifier)/\(route)/"
      )
      XCTAssertEqual(
        product.localizedLegalURL(japaneseURL, for: Locale(identifier: "ja_JP")),
        japaneseURL
      )
    }
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

  @MainActor
  func testAppEnvironmentUsesInjectedDateForDailyPassAccess() {
    let expiration = Date(timeIntervalSince1970: 100_000)
    let entitlements = EntitlementSnapshot(
      activeProductIDs: [StillCommerceCatalog.dailyPassProductID],
      expirationDates: [StillCommerceCatalog.dailyPassProductID: expiration]
    )
    let environmentBeforeExpiration = AppEnvironment(
      aiClient: UnavailableAIClient(reason: .modelNotReady),
      subscriptionClient: PreviewSubscriptionClient(),
      currentDate: { expiration.addingTimeInterval(-1) }
    )
    environmentBeforeExpiration.entitlements = entitlements
    XCTAssertTrue(environmentBeforeExpiration.isPremium)
    XCTAssertTrue(
      environmentBeforeExpiration.isProductActive(StillCommerceCatalog.dailyPassProductID)
    )

    let environmentAtExpiration = AppEnvironment(
      aiClient: UnavailableAIClient(reason: .modelNotReady),
      subscriptionClient: PreviewSubscriptionClient(),
      currentDate: { expiration }
    )
    environmentAtExpiration.entitlements = entitlements
    XCTAssertFalse(environmentAtExpiration.isPremium)
    XCTAssertFalse(
      environmentAtExpiration.isProductActive(StillCommerceCatalog.dailyPassProductID)
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
  func testPauseTimerResetsWithTutorialMinuteVocabulary() {
    let pauseTimer = PauseTimer()

    pauseTimer.reset(lengthInMinutes: 2)

    XCTAssertEqual(pauseTimer.secondsElapsed, 0)
    XCTAssertEqual(pauseTimer.secondsRemaining, 120)
    XCTAssertFalse(pauseTimer.isRunning)
  }

  @MainActor
  func testPauseTimerStartsAndStopsItsScheduledTimer() {
    let pauseTimer = PauseTimer(lengthInMinutes: 1)

    pauseTimer.startPause()
    XCTAssertTrue(pauseTimer.isRunning)

    pauseTimer.stopPause()
    XCTAssertFalse(pauseTimer.isRunning)
  }

  @MainActor
  func testZeroLengthPauseCompletesExactlyOnce() async {
    let completion = expectation(description: "Pause completes")
    var completionCount = 0
    let pauseTimer = PauseTimer()
    pauseTimer.pauseCompletedAction = {
      completionCount += 1
      completion.fulfill()
    }

    pauseTimer.startPause()
    await fulfillment(of: [completion], timeout: 1)
    try? await Task.sleep(for: .milliseconds(100))

    XCTAssertEqual(completionCount, 1)
    XCTAssertEqual(pauseTimer.secondsElapsed, 0)
    XCTAssertEqual(pauseTimer.secondsRemaining, 0)
    XCTAssertFalse(pauseTimer.isRunning)
  }

  @MainActor
  func testTrailingIconLabelStyleRendersTheRetainedLabelUnit() {
    let renderer = ImageRenderer(
      content: Label("Pause", systemImage: "timer")
        .labelStyle(.trailingIcon)
        .frame(width: 120, height: 44)
    )

    XCTAssertNotNil(renderer.uiImage)
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
      try dataContainer.context.performTransactionOrRollback {
        dataContainer.context.insert(Pause(duration: 60, startedAt: .now, endedAt: .now))
        throw CocoaError(.fileWriteNoPermission)
      }
    )

    XCTAssertTrue(try dataContainer.context.fetch(FetchDescriptor<Pause>()).isEmpty)
  }

  @MainActor
  func testFailedEditRestoresPersistedPause() throws {
    let dataContainer = DataContainer(isStoredInMemoryOnly: true)
    let pause = Pause(duration: 60, startedAt: .now, endedAt: .now)
    dataContainer.context.insert(pause)
    try dataContainer.context.save()

    XCTAssertThrowsError(
      try dataContainer.context.performTransactionOrRollback {
        pause.duration = 120
        throw CocoaError(.fileWriteNoPermission)
      }
    )

    let saved = try XCTUnwrap(
      dataContainer.context.fetch(FetchDescriptor<Pause>()).first
    )
    XCTAssertEqual(saved.duration, 60)
  }

  @MainActor
  func testFailedDeleteRestoresPersistedPause() throws {
    let dataContainer = DataContainer(isStoredInMemoryOnly: true)
    let pause = Pause(duration: 60, startedAt: .now, endedAt: .now)
    dataContainer.context.insert(pause)
    try dataContainer.context.save()

    XCTAssertThrowsError(
      try dataContainer.context.performTransactionOrRollback {
        dataContainer.context.delete(pause)
        throw CocoaError(.fileWriteNoPermission)
      }
    )

    XCTAssertEqual(try dataContainer.context.fetch(FetchDescriptor<Pause>()).count, 1)
  }

  func testTransactionFailureTriggersRollback() {
    var didRollback = false

    XCTAssertThrowsError(
      try ModelContext.performTransactionOrRollback(
        transaction: { throw CocoaError(.fileWriteNoPermission) },
        rollback: { didRollback = true }
      )
    )
    XCTAssertTrue(didRollback)
  }
}
