import StoreKit
import SwiftUI

struct PaywallView: View {
  @Environment(AppEnvironment.self) private var environment
  @State private var isShowingSubscriptionManagement = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 18) {
          Image(
            systemName: environment.isPremium
              ? "checkmark.seal.fill"
              : environment.product.symbolName
          )
          .font(.system(size: 48))
          .foregroundStyle(environment.product.accent)
          .accessibilityHidden(true)

          Text(
            environment.isPremium
              ? "\(environment.product.name) Pro is active" : "\(environment.product.name) Pro"
          )
          .font(.title.bold())

          Text(environment.product.tagline)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)

          if !environment.isAIAvailable {
            CardView {
              Label(
                "The on-device assistant is unavailable on this device or for the current language. Paid plans can’t be purchased until it becomes available.",
                systemImage: "exclamationmark.triangle"
              )
              .foregroundStyle(.secondary)
            }
          } else if environment.products.isEmpty {
            CardView {
              Text(
                "No StoreKit products are available yet. Add the \(environment.product.name) products in App Store Connect or a local StoreKit configuration before purchase testing."
              )
              .foregroundStyle(.secondary)
            }
          } else {
            ForEach(environment.products) { product in
              Button {
                Task {
                  await environment.purchase(productID: product.id)
                }
              } label: {
                HStack {
                  VStack(alignment: .leading) {
                    Text(product.displayName)
                      .font(.headline)
                    Text(product.description)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                    Text(renewalDescription(for: product))
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                    if let expirationDate = dailyPassExpiration(for: product) {
                      Text(
                        "Active until \(expirationDate.formatted(date: .abbreviated, time: .shortened))"
                      )
                      .font(.caption2.bold())
                      .foregroundStyle(environment.product.accent)
                    }
                  }
                  Spacer()
                  Text(product.displayPrice)
                    .font(.headline)
                }
                .padding()
              }
              .buttonStyle(.bordered)
              .disabled(isPurchaseDisabled(for: product))
            }
          }

          Button("Restore Purchases") {
            Task {
              await environment.restorePurchases()
            }
          }
          .disabled(environment.isLoadingStore)

          Button("Manage Subscription") {
            isShowingSubscriptionManagement = true
          }
          .disabled(environment.isLoadingStore)

          HStack(spacing: 16) {
            Link("Privacy Policy", destination: environment.product.privacyPolicyURL)
            Link("Terms of Use", destination: environment.product.termsOfUseURL)
          }
          .font(.footnote)

          if let message = environment.commerceMessage {
            Text(message)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
        .padding(24)
      }
      .navigationTitle("Pro")
      .refreshable {
        await environment.refreshStore()
      }
      .manageSubscriptionsSheet(isPresented: $isShowingSubscriptionManagement)
    }
  }

  private func renewalDescription(for product: SubscriptionProduct) -> String {
    switch product.renewal {
    case .automatic:
      return String(localized: "Auto-renews until cancelled.")
    case .manual(let accessDuration):
      let hours = Int(accessDuration / 3_600)
      return String(localized: "One-time access for \(hours) hours. Does not auto-renew.")
    }
  }

  private func dailyPassExpiration(for product: SubscriptionProduct) -> Date? {
    guard case .manual = product.renewal,
      environment.isProductActive(product.id)
    else {
      return nil
    }
    return environment.entitlements.expirationDates[product.id]
  }

  private func isPurchaseDisabled(for product: SubscriptionProduct) -> Bool {
    if !environment.isAIAvailable
      || environment.isLoadingStore
      || environment.isProductActive(product.id)
    {
      return true
    }
    if case .manual = product.renewal {
      return environment.isPremium
    }
    return false
  }
}
