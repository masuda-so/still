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
  let assistantProgressTitle: String
  let assistantTitle: String
  let assistantOutputTitle: String
  let assistantInstructions: String
  let assistantPromptPrefix: String
  let settingsPrivacySummary: String
  let privacyPolicyURL: URL
  let termsOfUseURL: URL
  let supportURL: URL

  static let still = ProductDefinition(
    identifier: ProductIdentity.identifier,
    bundleIdentifier: ProductIdentity.bundleIdentifier,
    name: "Still",
    tagline: String(localized: "A quiet pause, exactly when you need it."),
    symbolName: "pause.circle.fill",
    accent: .teal,
    assistantInputTitle: String(localized: "How does this moment feel?"),
    assistantActionTitle: String(localized: "Pause"),
    assistantProgressTitle: String(localized: "Preparing a pause…"),
    assistantTitle: String(localized: "Pause Guide"),
    assistantOutputTitle: String(localized: "Pause"),
    assistantInstructions:
      "Offer a brief, optional grounding pause. Do not diagnose, provide treatment, imply crisis support, or encourage dependence. If the content describes immediate danger, choose doNotOfferPause and do not provide a pause exercise.",
    assistantPromptPrefix:
      "Offer one simple pause of one or two minutes and one optional reflection for this moment:",
    settingsPrivacySummary: String(
      localized: "Your completed pauses stay on this device."
    ),
    privacyPolicyURL: validatedURL(
      "https://ether-llc.com/apps/still/privacy/"
    ),
    termsOfUseURL: validatedURL(
      "https://ether-llc.com/apps/still/terms/"
    ),
    supportURL: validatedURL(
      "https://ether-llc.com/apps/still/support/"
    )
  )

  func localizedLegalURL(_ url: URL, for locale: Locale) -> URL {
    guard
      locale.language.languageCode?.identifier == "ja",
      url.host == "ether-llc.com",
      !url.path.hasPrefix("/ja/")
    else {
      return url
    }

    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return url
    }
    components.percentEncodedPath = "/ja\(components.percentEncodedPath)"
    return components.url ?? url
  }

  private static func validatedURL(_ value: String) -> URL {
    guard let url = URL(string: value) else {
      preconditionFailure("Invalid static URL: \(value)")
    }
    return url
  }
}
