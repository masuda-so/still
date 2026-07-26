import Foundation
import SwiftData

/// A completed pause persisted by SwiftData.
@Model
final class Pause {
  var duration: TimeInterval
  var startedAt: Date
  var endedAt: Date

  init(
    duration: TimeInterval,
    startedAt: Date,
    endedAt: Date
  ) {
    self.duration = duration
    self.startedAt = startedAt
    self.endedAt = endedAt
  }
}
