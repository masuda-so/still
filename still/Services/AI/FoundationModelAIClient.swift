#if canImport(FoundationModels)
  import Foundation
  import FoundationModels

  @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
  @Generable(description: "Whether Still can safely offer a short grounding pause")
  private enum GeneratedPauseDisposition {
    case offerPause
    case doNotOfferPause
  }

  @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
  @Generable(description: "A short optional pause proposal for human review")
  private struct GeneratedPauseProposal {
    @Guide(
      description:
        "Choose doNotOfferPause when the input describes immediate danger; otherwise choose offerPause."
    )
    var disposition: GeneratedPauseDisposition

    @Guide(description: "The pause duration in minutes.", .range(1...2))
    var durationInMinutes: Int

    @Guide(description: "One brief grounding instruction. Do not diagnose or provide treatment.")
    var guidance: String

    @Guide(description: "One optional reflection question, or an empty string.")
    var reflection: String
  }

  /// Sends requests to Apple's on-device system language model.
  @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
  nonisolated struct FoundationModelAIClient: AIClient {
    private static let contextSafetyMargin = 128
    private static let textResponseTokenLimit = 384
    private static let proposalResponseTokenLimit = 256

    private let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
      self.model = model
    }

    var availability: AIAvailability {
      get async {
        guard model.supportsLocale() else {
          return .unavailable(.unsupportedLocale)
        }

        switch model.availability {
        case .available:
          return .available
        case .unavailable(let reason):
          switch reason {
          case .deviceNotEligible:
            return .unavailable(.deviceNotEligible)
          case .appleIntelligenceNotEnabled:
            return .unavailable(.appleIntelligenceDisabled)
          case .modelNotReady:
            return .unavailable(.modelNotReady)
          @unknown default:
            return .unavailable(.unknown)
          }
        }
      }
    }

    func respond(to request: AIRequest) async throws -> AIResponse {
      do {
        let (promptText, session) = try await preparedRequest(request)
        let prompt = Prompt { promptText }
        try await ensureRequestFits(
          prompt: prompt,
          session: session,
          schema: nil,
          responseTokenLimit: Self.textResponseTokenLimit,
          fallbackCharacterCount: (request.instructions?.count ?? 0) + promptText.count
        )
        let response = try await session.respond(
          to: prompt,
          options: GenerationOptions(maximumResponseTokens: Self.textResponseTokenLimit)
        )
        try Task.checkCancellation()
        return AIResponse(text: response.content)
      } catch is CancellationError {
        throw AIError.cancelled
      } catch let error as AIError {
        throw error
      } catch {
        throw Self.aiError(from: error)
      }
    }

    func generatePauseProposal(from request: AIRequest) async throws -> StillPauseProposal {
      do {
        let (promptText, session) = try await preparedRequest(request)
        let prompt = Prompt { promptText }
        try await ensureRequestFits(
          prompt: prompt,
          session: session,
          schema: GeneratedPauseProposal.generationSchema,
          responseTokenLimit: Self.proposalResponseTokenLimit,
          fallbackCharacterCount: (request.instructions?.count ?? 0) + promptText.count
        )
        let response = try await session.respond(
          to: prompt,
          generating: GeneratedPauseProposal.self,
          options: GenerationOptions(maximumResponseTokens: Self.proposalResponseTokenLimit)
        )
        try Task.checkCancellation()

        switch response.content.disposition {
        case .offerPause:
          return try StillPauseProposal.generatedPause(
            durationInMinutes: response.content.durationInMinutes,
            guidance: response.content.guidance,
            reflection: response.content.reflection
          )
        case .doNotOfferPause:
          return .immediateSafetyConcern
        }
      } catch is CancellationError {
        throw AIError.cancelled
      } catch let error as AIError {
        throw error
      } catch {
        throw Self.aiError(from: error)
      }
    }

    private func preparedRequest(
      _ request: AIRequest
    ) async throws -> (String, LanguageModelSession) {
      let promptText = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !promptText.isEmpty else { throw AIError.emptyPrompt }

      if let localeIdentifier = request.localeIdentifier {
        guard model.supportsLocale(Locale(identifier: localeIdentifier)) else {
          throw AIError.unavailable(.unsupportedLocale)
        }
      }

      let currentAvailability = await availability
      guard case .available = currentAvailability else {
        if case .unavailable(let reason) = currentAvailability {
          throw AIError.unavailable(reason)
        }
        throw AIError.unavailable(.unknown)
      }

      return (
        promptText,
        LanguageModelSession(model: model, instructions: request.instructions)
      )
    }

    private func ensureRequestFits(
      prompt: Prompt,
      session: LanguageModelSession,
      schema: GenerationSchema?,
      responseTokenLimit: Int,
      fallbackCharacterCount: Int
    ) async throws {
      let reservedTokens = responseTokenLimit + Self.contextSafetyMargin
      if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
        let transcriptTokenCount = try await model.tokenCount(for: session.transcript)
        let promptTokenCount = try await model.tokenCount(for: prompt)
        let schemaTokenCount: Int
        if let schema {
          schemaTokenCount = try await model.tokenCount(for: schema)
        } else {
          schemaTokenCount = 0
        }
        guard
          transcriptTokenCount + promptTokenCount + schemaTokenCount + reservedTokens
            <= model.contextSize
        else {
          throw AIError.contextWindowExceeded
        }
      } else {
        guard fallbackCharacterCount + reservedTokens <= model.contextSize else {
          throw AIError.contextWindowExceeded
        }
      }
    }

    /// Adapts Foundation Models errors to the app's stable error vocabulary.
    static func aiError(from error: any Error) -> AIError {
      #if compiler(<6.4)
        if let generationError = error as? LanguageModelSession.GenerationError {
          return aiError(from: generationError)
        }
      #else
        if #unavailable(iOS 27.0, macOS 27.0, visionOS 27.0) {
          if let generationError = error as? LanguageModelSession.GenerationError {
            return aiError(from: generationError)
          }
        }
      #endif

      #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
          if let languageModelError = error as? LanguageModelError {
            switch languageModelError {
            case .contextSizeExceeded:
              return .contextWindowExceeded
            case .rateLimited:
              return .rateLimited
            case .guardrailViolation:
              return .safetyGuardrail
            case .refusal:
              return .requestRefused
            case .unsupportedLanguageOrLocale:
              return .unsupportedLanguage
            case .timeout:
              return .requestTimedOut
            case .unsupportedCapability,
              .unsupportedTranscriptContent,
              .unsupportedGenerationGuide:
              return .generationFailed(debugDescription: languageModelError.debugDescription)
            @unknown default:
              return .generationFailed(debugDescription: languageModelError.debugDescription)
            }
          }

          if let systemLanguageModelError = error as? SystemLanguageModel.Error {
            switch systemLanguageModelError {
            case .assetsUnavailable:
              return .unavailable(.modelNotReady)
            @unknown default:
              return .generationFailed(debugDescription: systemLanguageModelError.debugDescription)
            }
          }

          if let sessionError = error as? LanguageModelSession.Error {
            switch sessionError {
            case .concurrentRequests:
              return .requestInProgress
            case .transcriptMutationWhileResponding:
              return .generationFailed(debugDescription: sessionError.debugDescription)
            @unknown default:
              return .generationFailed(debugDescription: sessionError.debugDescription)
            }
          }
        }
      #endif

      return .generationFailed(debugDescription: String(describing: error))
    }

    /// Maps the GenerationError vocabulary shipped with the stable iOS 26 SDK.
    private static func aiError(
      from error: LanguageModelSession.GenerationError
    ) -> AIError {
      switch error {
      case .exceededContextWindowSize:
        return .contextWindowExceeded
      case .assetsUnavailable:
        return .unavailable(.modelNotReady)
      case .guardrailViolation:
        return .safetyGuardrail
      case .unsupportedLanguageOrLocale:
        return .unsupportedLanguage
      case .rateLimited:
        return .rateLimited
      case .concurrentRequests:
        return .requestInProgress
      case .refusal:
        return .requestRefused
      case .unsupportedGuide(let context), .decodingFailure(let context):
        return .generationFailed(debugDescription: context.debugDescription)
      @unknown default:
        return .generationFailed(debugDescription: String(describing: error))
      }
    }
  }
#endif
