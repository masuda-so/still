import SwiftUI

struct SettingsView: View {
  @Environment(AppEnvironment.self) private var environment

  var body: some View {
    NavigationStack {
      Form {
        Section("Product") {
          LabeledContent("App", value: environment.product.name)
          LabeledContent("Plan", value: environment.isPremium ? "Pro" : "Free")
          LabeledContent("Bundle ID", value: environment.product.bundleIdentifier)
        }

        Section("Privacy") {
          Label(
            "AI requests use the on-device model when available.",
            systemImage: "iphone.and.arrow.forward")
          Label("Purchases are verified with StoreKit 2.", systemImage: "checkmark.shield")
          Label(
            "No analytics or remote AI service is included in this foundation.",
            systemImage: "hand.raised")
        }

        Section("Assistant") {
          LabeledContent("Availability", value: assistantAvailability)
        }

        Section("Legal") {
          Link(destination: environment.product.privacyPolicyURL) {
            Label("Privacy Policy", systemImage: "hand.raised")
          }
          Link(destination: environment.product.termsOfUseURL) {
            Label("Terms of Use", systemImage: "doc.text")
          }
        }
      }
      .navigationTitle("Settings")
    }
  }

  private var assistantAvailability: String {
    switch environment.aiAvailability {
    case .available:
      return String(localized: "Available")
    case .unavailable:
      return String(localized: "Unavailable")
    }
  }
}
