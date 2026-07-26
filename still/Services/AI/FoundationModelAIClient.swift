#if canImport(FoundationModels)
  import Foundation
  import FoundationModels

  /// Sends requests to Apple's on-device system language model.
  @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
  nonisolated struct FoundationModelAIClient: AIClient {
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
      let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !prompt.isEmpty else {
        throw AIError.emptyPrompt
      }

      if let localeIdentifier = request.localeIdentifier {
        let locale = Locale(identifier: localeIdentifier)
        guard model.supportsLocale(locale) else {
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

      do {
        let session = LanguageModelSession(
          model: model,
          instructions: request.instructions
        )
        let response = try await session.respond(to: prompt)
        return AIResponse(text: response.content)
      } catch is CancellationError {
        throw AIError.cancelled
      } catch {
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
          if let modelError = error as? LanguageModelError {
            throw Self.aiError(from: modelError)
          }
          if let sessionError = error as? LanguageModelSession.Error {
            throw Self.aiError(from: sessionError)
          }
          if let systemModelError = error as? SystemLanguageModel.Error {
            throw Self.aiError(from: systemModelError)
          }
        }
        throw AIError.generationFailed(debugDescription: String(describing: error))
      }
    }

    /// Maps an iOS 27 model error to the app's stable error vocabulary.
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    static func aiError(from error: LanguageModelError) -> AIError {
      switch error {
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
      default:
        return .generationFailed(debugDescription: error.localizedDescription)
      }
    }

    /// Maps an iOS 27 session error to the app's stable error vocabulary.
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    static func aiError(from error: LanguageModelSession.Error) -> AIError {
      switch error {
      case .concurrentRequests:
        return .requestInProgress
      case .transcriptMutationWhileResponding:
        return .generationFailed(debugDescription: error.localizedDescription)
      @unknown default:
        return .generationFailed(debugDescription: error.localizedDescription)
      }
    }

    /// Maps an iOS 27 system-model error to the app's stable error vocabulary.
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    static func aiError(from error: SystemLanguageModel.Error) -> AIError {
      switch error {
      case .assetsUnavailable:
        return .unavailable(.modelNotReady)
      @unknown default:
        return .generationFailed(debugDescription: error.localizedDescription)
      }
    }
  }
#endif
