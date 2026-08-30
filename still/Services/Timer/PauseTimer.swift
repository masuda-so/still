import Foundation

/// Keeps time for a pause and publishes its elapsed and remaining seconds.
@MainActor
@Observable
final class PauseTimer {
  /// The number of seconds since the beginning of the pause.
  var secondsElapsed = 0
  /// The number of seconds until the pause ends.
  var secondsRemaining = 0

  /// A closure that runs when the pause reaches its configured length.
  var pauseCompletedAction: (() -> Void)?

  /// The pause length.
  private var lengthInMinutes: Int
  private weak var timer: Timer?
  private var timerStopped = false
  private var frequency: TimeInterval { 1.0 / 60.0 }
  private var lengthInSeconds: Int { lengthInMinutes * 60 }
  private var startDate: Date?

  /// Whether the pause timer currently has an active scheduled timer.
  var isRunning: Bool {
    timer != nil && !timerStopped
  }

  /// Creates a timer with a pause length in whole minutes.
  init(lengthInMinutes: Int = 0) {
    self.lengthInMinutes = lengthInMinutes
    secondsRemaining = lengthInSeconds
  }

  /// Starts the pause timer.
  func startPause() {
    timerStopped = false
    timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
      self?.update()
    }
    timer?.tolerance = 0.1
    startDate = Date()
  }

  /// Stops the pause timer without invoking the completion action.
  func stopPause() {
    timer?.invalidate()
    timerStopped = true
  }

  /// Resets the timer with a new pause length.
  func reset(lengthInMinutes: Int) {
    self.lengthInMinutes = lengthInMinutes
    secondsElapsed = 0
    secondsRemaining = lengthInSeconds
    startDate = nil
  }

  nonisolated private func update() {
    Task { @MainActor in
      guard let startDate,
        !timerStopped
      else {
        return
      }

      let secondsElapsed = Int(Date().timeIntervalSince1970 - startDate.timeIntervalSince1970)
      self.secondsElapsed = min(secondsElapsed, lengthInSeconds)
      secondsRemaining = max(lengthInSeconds - self.secondsElapsed, 0)

      guard self.secondsElapsed >= lengthInSeconds else {
        return
      }

      stopPause()
      pauseCompletedAction?()
    }
  }
}
