import Foundation
import Observation

/// Tracks one pause against elapsed wall-clock time.
@MainActor
@Observable
final class PauseTimer {
  private(set) var secondsElapsed = 0
  private(set) var secondsRemaining = 0
  private(set) var isRunning = false

  /// Runs once when the active pause reaches its configured duration.
  var pauseCompletedAction: (() -> Void)?

  private var duration: TimeInterval = 60
  private weak var timer: Timer?
  private var startDate: Date?

  /// The completed fraction of the active pause, clamped to `0...1`.
  var progress: Double {
    guard duration > 0 else {
      return 0
    }
    return min(Double(secondsElapsed) / duration, 1)
  }

  /// Stops the timer and prepares it with a new duration.
  func reset(duration: TimeInterval) {
    stopPause()
    self.duration = max(duration, 1)
    secondsElapsed = 0
    secondsRemaining = Int(self.duration.rounded(.up))
  }

  /// Starts elapsed-time tracking unless a pause is already running.
  func startPause() {
    guard !isRunning else {
      return
    }

    startDate = .now
    isRunning = true
    timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) {
      [weak self] _ in
      self?.update()
    }
    timer?.tolerance = 0.1
  }

  /// Stops elapsed-time tracking without invoking the completion action.
  func stopPause() {
    timer?.invalidate()
    timer = nil
    isRunning = false
    startDate = nil
  }

  nonisolated private func update() {
    Task { @MainActor in
      guard let startDate, isRunning else {
        return
      }

      let elapsed = Date.now.timeIntervalSince(startDate)
      secondsElapsed = min(Int(elapsed), Int(duration))
      secondsRemaining = max(Int(ceil(duration - elapsed)), 0)

      guard elapsed >= duration else {
        return
      }

      stopPause()
      secondsElapsed = Int(duration)
      secondsRemaining = 0
      pauseCompletedAction?()
    }
  }
}
