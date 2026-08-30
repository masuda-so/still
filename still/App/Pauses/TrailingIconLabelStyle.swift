/*
See THIRD_PARTY_NOTICES.md for this sample's licensing information.

This file retains TrailingIconLabelStyle from Apple's Scrumdinger tutorial.
*/

import SwiftUI

/// Places a label's title before its icon.
struct TrailingIconLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.title
      configuration.icon
    }
  }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
  static var trailingIcon: Self { Self() }
}
