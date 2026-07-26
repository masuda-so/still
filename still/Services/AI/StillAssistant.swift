import Foundation

/// Provides Still-specific prompting on top of an interchangeable AI client.
struct StillAssistant {
  let client: any AIClient
  let product: ProductDefinition

  var availability: AIAvailability {
    get async {
      await client.availability
    }
  }

  /// Responds to user text using Still's product-specific instructions.
  func respond(to text: String) async throws -> String {
    let locale = Locale.current
    let response = try await client.respond(
      to:
        AIRequest(
          instructions: """
            \(product.assistantInstructions)
            Respond in the person's preferred language for locale \(locale.identifier).
            """,
          prompt: "\(product.assistantPromptPrefix)\n\n\(text)",
          localeIdentifier: locale.identifier
        )
    )
    return response.text
  }
}
