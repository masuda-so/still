import SwiftUI

enum AppSection: Hashable {
  case pauses
  case assistant
  case pro
  case settings
}

struct AppRootView: View {
  @Environment(AppEnvironment.self) private var environment
  @State private var selection: AppSection = .pauses

  var body: some View {
    TabView(selection: $selection) {
      Tab("Pauses", systemImage: "wind", value: .pauses) {
        PausesView()
      }

      Tab("Assistant", systemImage: "sparkles", value: .assistant) {
        AssistantView(selection: $selection)
      }

      Tab("Pro", systemImage: "crown", value: .pro) {
        PaywallView()
      }

      Tab("Settings", systemImage: "gearshape", value: .settings) {
        SettingsView()
      }
    }
    .tint(environment.product.accent)
  }
}

#Preview {
  AppRootView()
    .environment(AppEnvironment.preview)
    .sampleDataContainer()
}
