/*
See THIRD_PARTY_NOTICES.md for this sample's licensing information.

This view adapts MeetingHeaderView from Apple's Scrumdinger tutorial.
*/

import Foundation
import SwiftUI

/// Displays elapsed and remaining time for the current pause.
struct PauseHeaderView: View {
  @Environment(\.locale) private var locale

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

  private var accessibilityValue: String {
    Self.accessibilityValue(
      secondsRemaining: secondsRemaining,
      locale: locale
    )
  }

  /// Formats the remaining time with localized minute and second units.
  nonisolated static func accessibilityValue(
    secondsRemaining: Int,
    locale: Locale
  ) -> String {
    let style = Duration.UnitsFormatStyle(
      allowedUnits: [.minutes, .seconds],
      width: .wide,
      maximumUnitCount: 2
    ).locale(locale)
    return style.format(.seconds(max(secondsRemaining, 0)))
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
    .accessibilityValue(accessibilityValue)
    .padding([.top, .horizontal])
  }
}
