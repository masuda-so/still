import Foundation
import Observation

/// Coordinates assistant, StoreKit, and access state for the application UI.
@MainActor
@Observable
final class AppEnvironment {
  let product: ProductDefinition

  private let assistant: StillAssistant
  private let subscriptionClient: any SubscriptionClient
  private let currentDate: @Sendable () -> Date
  private let sleep: @Sendable (Duration) async throws -> Void
  private var entitlementTask: Task<Void, Never>?
  private var expirationTask: Task<Void, Never>?

  var aiAvailability: AIAvailability = .unavailable(.unknown)
  var products: [SubscriptionProduct] = []
  var entitlements = EntitlementSnapshot() {
    didSet {
      scheduleNextNonRenewingExpiration()
    }
  }
  var assistantResponse: String?
  var commerceMessage: String?
  var isGenerating = false
  var isLoadingStore = false

  init(
    aiClient: any AIClient = AIClientFactory.makeDefault(),
    subscriptionClient: (any SubscriptionClient)? = nil,
    currentDate: @escaping @Sendable () -> Date = Date.init,
    sleep: @escaping @Sendable (Duration) async throws -> Void = {
      try await Task.sleep(for: $0)
    }
  ) {
    self.product = .still
    self.assistant = StillAssistant(client: aiClient, product: .still)
    self.currentDate = currentDate
    self.sleep = sleep
    self.subscriptionClient =
      subscriptionClient
      ?? StoreKitSubscriptionClient(
        catalog: StillCommerceCatalog.catalog,
        now: currentDate
      )
  }

  /// Starts transaction monitoring and loads the initial assistant and StoreKit state.
  func start() async {
    if entitlementTask == nil {
      startEntitlementMonitor()
    }

    async let availability = assistant.availability
    async let storePreparation: Void = refreshStore()

    aiAvailability = await availability
    _ = await storePreparation
  }

  private func startEntitlementMonitor() {
    let subscriptionClient = self.subscriptionClient
    entitlementTask = Task { [weak self, subscriptionClient] in
      let updates = await subscriptionClient.entitlementUpdates()
      for await snapshot in updates {
        guard !Task.isCancelled else { break }
        self?.entitlements = snapshot
      }
    }
  }

  private func scheduleNextNonRenewingExpiration() {
    expirationTask?.cancel()
    expirationTask = nil

    let currentDate = currentDate()
    guard
      let expirationDate = entitlements.nextNonRenewingExpiration(
        in: StillCommerceCatalog.catalog,
        after: currentDate
      )
    else {
      return
    }

    let delay = Self.expirationDelay(
      until: expirationDate,
      from: currentDate
    )
    let subscriptionClient = self.subscriptionClient
    let sleep = self.sleep
    expirationTask = Task { [weak self, subscriptionClient, sleep] in
      do {
        try await sleep(delay)
      } catch {
        return
      }
      guard !Task.isCancelled else { return }
      self?.entitlements = await subscriptionClient.currentEntitlements()
    }
  }

  isolated deinit {
    entitlementTask?.cancel()
    expirationTask?.cancel()
  }

  /// Requests an assistant response and publishes the resulting UI state.
  func requestAssistantResponse(for text: String) async {
    guard isAIAvailable else {
      assistantResponse = String(localized: "The on-device assistant is unavailable.")
      return
    }

    guard isPremium else {
      assistantResponse = String(localized: "Choose a Pro plan to use the on-device assistant.")
      return
    }

    isGenerating = true
    defer { isGenerating = false }

    do {
      assistantResponse = try await assistant.respond(to: text)
    } catch {
      assistantResponse = error.localizedDescription
    }
  }

  /// Reloads products and verified entitlements from StoreKit.
  func refreshStore() async {
    isLoadingStore = true
    defer { isLoadingStore = false }

    do {
      async let loadedProducts = subscriptionClient.loadProducts()
      async let currentEntitlements = subscriptionClient.currentEntitlements()
      products = try await loadedProducts
      entitlements = await currentEntitlements
      commerceMessage = nil
    } catch {
      products = []
      commerceMessage = error.localizedDescription
    }
  }

  /// Purchases a configured product and publishes the resulting access state.
  func purchase(productID: String) async {
    isLoadingStore = true
    defer { isLoadingStore = false }

    do {
      switch try await subscriptionClient.purchase(productID: productID) {
      case .purchased(let snapshot):
        entitlements = snapshot
        commerceMessage = String(localized: "\(product.name) Pro is active.")
      case .pending:
        commerceMessage = String(localized: "The purchase is waiting for approval.")
      case .userCancelled:
        commerceMessage = nil
      }
    } catch {
      commerceMessage = error.localizedDescription
    }
  }

  /// Synchronizes App Store purchases and publishes the restored access state.
  func restorePurchases() async {
    isLoadingStore = true
    defer { isLoadingStore = false }

    do {
      entitlements = try await subscriptionClient.restorePurchases()
      commerceMessage =
        isPremium
        ? String(localized: "\(product.name) Pro was restored.")
        : String(localized: "No active \(product.name) Pro purchase was found.")
    } catch {
      commerceMessage = error.localizedDescription
    }
  }

  var isPremium: Bool {
    StillAccessPolicy.hasProAccess(entitlements: entitlements)
  }

  var isAIAvailable: Bool {
    aiAvailability == .available
  }

  /// Returns whether a configured product currently grants access.
  func isProductActive(_ productID: String) -> Bool {
    entitlements.isActive(
      productID: productID,
      in: StillCommerceCatalog.catalog
    )
  }

  /// Returns a nonnegative delay from an injected wall-clock date to an expiration.
  nonisolated static func expirationDelay(
    until expirationDate: Date,
    from currentDate: Date
  ) -> Duration {
    .seconds(max(expirationDate.timeIntervalSince(currentDate), 0))
  }

  static var preview: AppEnvironment {
    AppEnvironment(
      aiClient: UnavailableAIClient(reason: .modelNotReady),
      subscriptionClient: PreviewSubscriptionClient()
    )
  }
}
