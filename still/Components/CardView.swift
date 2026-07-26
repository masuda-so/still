import SwiftUI

/// Presents reusable content in the family-wide material card style.
struct CardView<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    content
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(20)
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
  }
}
