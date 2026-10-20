import Observation
import SwiftData
import SwiftUI

/// Owns Still's SwiftData container and main-actor model context.
@MainActor
@Observable
final class DataContainer {
  let modelContainer: ModelContainer

  var context: ModelContext {
    modelContainer.mainContext
  }

  init(isStoredInMemoryOnly: Bool = false) {
    let schema = Schema([Pause.self])
    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: isStoredInMemoryOnly
    )

    do {
      modelContainer = try ModelContainer(
        for: schema,
        configurations: [configuration]
      )
    } catch {
      fatalError("Could not create the Still data container: \(error)")
    }
  }
}

extension View {
  /// Supplies an in-memory SwiftData container for previews.
  @MainActor
  func sampleDataContainer() -> some View {
    let container = DataContainer(isStoredInMemoryOnly: true)
    return environment(container)
      .modelContainer(container.modelContainer)
  }
}
