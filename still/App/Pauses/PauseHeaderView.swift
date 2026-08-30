/*
See THIRD_PARTY_NOTICES.md for this sample's licensing information.

This view adapts MeetingHeaderView from Apple's Scrumdinger tutorial.
*/

import SwiftUI

/// Displays elapsed and remaining time for the current pause.
struct PauseHeaderView: View {
  let secondsElapsed: Int
  let secondsRemaining: Int
  let accentColor: Color

  private var totalSeconds: Int {
    secondsElapsed + secondsRemaining
  }

  private var progress: Double {
    guard totalSeconds > 0 else { return 1 }
    return Double(secondsElapsed) / Double(totalSeconds)
  }

  private var minutesRemaining: Int {
    secondsRemaining / 60
  }

  var body: some View {
    VStack {
      ProgressView(value: progress)
        .tint(accentColor)
      HStack {
        VStack(alignment: .leading) {
          Text("Seconds Elapsed")
            .font(.caption)
          Label("\(secondsElapsed)", systemImage: "hourglass.bottomhalf.fill")
        }
        Spacer()
        VStack(alignment: .trailing) {
          Text("Seconds Remaining")
            .font(.caption)
          Label("\(secondsRemaining)", systemImage: "hourglass.tophalf.fill")
            .labelStyle(.trailingIcon)
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Time remaining")
    .accessibilityValue("\(minutesRemaining) minutes")
    .padding([.top, .horizontal])
  }
}
