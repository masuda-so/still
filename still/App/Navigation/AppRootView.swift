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
      PausesView()
        .tabItem {
          Label("Pauses", systemImage: "wind")
        }
        .tag(AppSection.pauses)

      AssistantView(selection: $selection)
        .tabItem {
          Label("Assistant", systemImage: "sparkles")
        }
        .tag(AppSection.assistant)

      PaywallView()
        .tabItem {
          Label("Pro", systemImage: "crown")
        }
        .tag(AppSection.pro)

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gearshape")
        }
        .tag(AppSection.settings)
    }
    .tint(environment.product.accent)
  }
}

#Preview {
  AppRootView()
    .environment(AppEnvironment.preview)
    .sampleDataContainer()
}
