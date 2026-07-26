import XCTest

@testable import still

#if canImport(FoundationModels)
  import FoundationModels
#endif

final class AIPlatformTests: XCTestCase {
  func testRequestRoundTrip() throws {
    let request = AIRequest(
      instructions: "Be concise.",
      prompt: "Reflect on this moment.",
      localeIdentifier: "en_US"
    )

    let data = try JSONEncoder().encode(request)
    let decoded = try JSONDecoder().decode(AIRequest.self, from: data)

    XCTAssertEqual(decoded, request)
  }

  func testAvailableClientResponds() async throws {
    let client = AvailableAIClient()
    let availability = await client.availability
    let response = try await client.respond(to: AIRequest(prompt: "Hello"))

    XCTAssertEqual(availability, .available)
    XCTAssertEqual(response, AIResponse(text: "Hello"))
  }

  func testUnavailableClientReportsEveryReason() async {
    for reason in AIUnavailableReason.allCases {
      let client = UnavailableAIClient(reason: reason)
      let availability = await client.availability

      XCTAssertEqual(availability, .unavailable(reason))
    }
  }

  func testUnavailableReasonsHaveUserFacingDescriptions() {
    for reason in AIUnavailableReason.allCases {
      XCTAssertFalse(reason.localizedDescription.isEmpty)
      XCTAssertNotEqual(reason.localizedDescription, reason.rawValue)
    }
  }

  func testStableErrorsHaveUserFacingDescriptions() {
    let errors: [AIError] = [
      .unavailable(.unsupportedOS),
      .emptyPrompt,
      .contextWindowExceeded,
      .requestInProgress,
      .requestRefused,
      .safetyGuardrail,
      .unsupportedLanguage,
      .rateLimited,
      .generationFailed(debugDescription: "Test failure"),
      .cancelled,
    ]

    for error in errors {
      XCTAssertFalse(error.localizedDescription.isEmpty)
    }
  }

  func testGenerationFailureDoesNotExposeFrameworkDiagnostics() {
    let diagnostic = "INTERNAL_MODEL_DIAGNOSTIC"
    let message = AIError.generationFailed(
      debugDescription: diagnostic
    ).localizedDescription

    XCTAssertFalse(message.contains(diagnostic))
    XCTAssertFalse(message.isEmpty)
  }

  func testUnavailableClientRejectsEmptyPrompt() async {
    let client = UnavailableAIClient(reason: .unsupportedOS)

    do {
      _ = try await client.respond(to: AIRequest(prompt: "   "))
      XCTFail("Expected an empty prompt error.")
    } catch let error as AIError {
      XCTAssertEqual(error, .emptyPrompt)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  #if canImport(FoundationModels)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    func testFoundationModelErrorsMapToStableApplicationErrors() {
      XCTAssertEqual(
        FoundationModelAIClient.aiError(
          from: LanguageModelError.contextSizeExceeded(
            .init(
              contextSize: 4_096,
              tokenCount: 4_097,
              debugDescription: "Context exceeded"
            )
          )
        ),
        .contextWindowExceeded
      )
      XCTAssertEqual(
        FoundationModelAIClient.aiError(
          from: LanguageModelError.rateLimited(
            .init(resetDate: nil, debugDescription: "Rate limited")
          )
        ),
        .rateLimited
      )
      XCTAssertEqual(
        FoundationModelAIClient.aiError(
          from: LanguageModelError.guardrailViolation(
            .init(debugDescription: "Guardrail")
          )
        ),
        .safetyGuardrail
      )
      XCTAssertEqual(
        FoundationModelAIClient.aiError(
          from: LanguageModelError.refusal(
            .init(debugDescription: "Refusal")
          )
        ),
        .requestRefused
      )
      XCTAssertEqual(
        FoundationModelAIClient.aiError(
          from: LanguageModelError.unsupportedLanguageOrLocale(
            .init(languageCode: "fr", debugDescription: "Unsupported")
          )
        ),
        .unsupportedLanguage
      )
      XCTAssertEqual(
        FoundationModelAIClient.aiError(
          from: LanguageModelSession.Error.concurrentRequests
        ),
        .requestInProgress
      )
      XCTAssertEqual(
        FoundationModelAIClient.aiError(
          from: SystemLanguageModel.Error.assetsUnavailable(
            .init(debugDescription: "Assets unavailable")
          )
        ),
        .unavailable(.modelNotReady)
      )
    }
  #endif
}

nonisolated private struct AvailableAIClient: AIClient {
  var availability: AIAvailability {
    get async { .available }
  }

  func respond(to request: AIRequest) async throws -> AIResponse {
    AIResponse(text: request.prompt)
  }
}
