import SwiftUI

/// Stable identifiers that must remain compatible with App Store records.
enum ProductIdentity {
  nonisolated static let identifier = "still"
  nonisolated static let bundleIdentifier = "llc.ether.\(identifier)"
}

/// Product-specific presentation, assistant, and legal configuration.
struct ProductDefinition {
  let identifier: String
  let bundleIdentifier: String
  let name: String
  let tagline: String
  let symbolName: String
  let accent: Color
  let assistantInputTitle: String
  let assistantActionTitle: String
  let assistantTitle: String
  let assistantOutputTitle: String
  let assistantInstructions: String
  let assistantPromptPrefix: String
  let privacyPolicyURL: URL
  let termsOfUseURL: URL

  static let still = ProductDefinition(
    identifier: ProductIdentity.identifier,
    bundleIdentifier: ProductIdentity.bundleIdentifier,
    name: "Still",
    tagline: String(localized: "A quiet pause, exactly when you need it."),
    symbolName: "pause.circle.fill",
    accent: .teal,
    assistantInputTitle: String(localized: "How does this moment feel?"),
    assistantActionTitle: String(localized: "Pause"),
    assistantTitle: String(localized: "Pause Guide"),
    assistantOutputTitle: String(localized: "Pause"),
    assistantInstructions:
      "Offer a brief, optional grounding pause. Do not diagnose, provide medical treatment, imply crisis support, or encourage dependence.",
    assistantPromptPrefix:
      "Offer one simple pause of under two minutes and one optional reflection for this moment:",
    privacyPolicyURL: validatedURL(
      "https://github.com/masuda-so/still/blob/main/Docs/Privacy.md"
    ),
    termsOfUseURL: validatedURL(
      "https://github.com/masuda-so/still/blob/main/Docs/Terms.md"
    )
  )

  private static func validatedURL(_ value: String) -> URL {
    guard let url = URL(string: value) else {
      preconditionFailure("Invalid static URL: \(value)")
    }
    return url
  }
}
