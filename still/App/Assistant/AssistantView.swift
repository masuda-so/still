import SwiftUI

struct AssistantView: View {
  @Environment(AppEnvironment.self) private var environment
  @Binding var selection: AppSection
  @State private var text = ""

  var body: some View {
    NavigationStack {
      Group {
        if environment.isPremium {
          assistantForm
        } else {
          lockedView
        }
      }
      .navigationTitle(environment.product.assistantTitle)
    }
  }

  private var assistantForm: some View {
    Form {
      Section(environment.product.assistantInputTitle) {
        TextEditor(text: $text)
          .frame(minHeight: 130)
          .accessibilityLabel(environment.product.assistantInputTitle)
      }

      Section {
        Button {
          Task {
            await environment.requestAssistantResponse(for: text)
          }
        } label: {
          if environment.isGenerating {
            ProgressView()
              .frame(maxWidth: .infinity)
          } else {
            Label(environment.product.assistantActionTitle, systemImage: "sparkles")
              .frame(maxWidth: .infinity)
          }
        }
        .disabled(
          text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || environment.isGenerating)
      } footer: {
        Text(availabilityMessage)
      }

      if let response = environment.assistantResponse {
        Section(environment.product.assistantOutputTitle) {
          Text(response)
            .textSelection(.enabled)
        }
      }
    }
  }

  private var lockedView: some View {
    ContentUnavailableView {
      Label(
        "\(environment.product.assistantTitle) is a Pro feature",
        systemImage: "crown.fill"
      )
    } description: {
      Text(
        "Choose the non-renewing Daily Pass or an auto-renewing plan to use the on-device assistant."
      )
    } actions: {
      Button("View Pro options") {
        selection = .pro
      }
      .buttonStyle(.borderedProminent)
      .tint(environment.product.accent)
    }
  }

  private var availabilityMessage: String {
    switch environment.aiAvailability {
    case .available:
      return String(localized: "Processed on this device with Apple Foundation Models.")
    case .unavailable(let reason):
      return String(
        localized:
          "\(reason.localizedDescription) \(environment.product.name) remains usable without the assistant."
      )
    }
  }
}
