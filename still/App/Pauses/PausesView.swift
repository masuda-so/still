import SwiftData
import SwiftUI

struct PausesView: View {
  @Environment(AppEnvironment.self) private var environment
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Pause.endedAt, order: .reverse) private var pauses: [Pause]

  @State private var pauseTimer = PauseTimer()
  @State private var durationInMinutes = 1
  @State private var startedAt: Date?
  @State private var pausePendingDeletion: Pause?
  @State private var persistenceError: String?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          PauseHeaderView(
            secondsElapsed: pauseTimer.secondsElapsed,
            secondsRemaining: pauseTimer.secondsRemaining,
            accentColor: environment.product.accent
          )
          controls
          history
        }
        .padding(24)
      }
      .navigationTitle("Still")
      .onAppear(perform: preparePauseTimer)
      .onDisappear(perform: pauseTimer.stopPause)
      .confirmationDialog(
        "Delete Pause",
        isPresented: isShowingDeleteConfirmation,
        titleVisibility: .visible
      ) {
        Button("Delete Pause", role: .destructive) {
          deletePendingPause()
        }
        Button("Cancel", role: .cancel) {
          pausePendingDeletion = nil
        }
      } message: {
        Text("This completed pause will be permanently deleted.")
      }
      .alert("Data Error", isPresented: isShowingPersistenceError) {
        Button("OK", role: .cancel) {
          persistenceError = nil
        }
      } message: {
        Text(persistenceError ?? String(localized: "Please try again."))
      }
    }
  }

  private var controls: some View {
    CardView {
      VStack(spacing: 16) {
        Stepper(
          "\(durationInMinutes) minute pause",
          value: $durationInMinutes,
          in: 1...10
        )
        .disabled(pauseTimer.isRunning)
        .onChange(of: durationInMinutes) {
          pauseTimer.reset(lengthInMinutes: durationInMinutes)
        }

        Button(action: togglePause) {
          Label(
            pauseTimer.isRunning ? "Cancel Pause" : "Begin Pause",
            systemImage: pauseTimer.isRunning ? "stop.fill" : "play.fill"
          )
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(environment.product.accent)

        if pauseTimer.isRunning {
          Text("If you cancel, this pause won’t appear in your history.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  @ViewBuilder
  private var history: some View {
    if pauses.isEmpty {
      ContentUnavailableView(
        "No Pauses Yet",
        systemImage: "wind",
        description: Text("Completed pauses will appear here.")
      )
    } else {
      VStack(alignment: .leading, spacing: 12) {
        Text("Recent Pauses")
          .font(.headline)

        ForEach(pauses.prefix(7)) { pause in
          HStack {
            Image(systemName: "calendar")
            Text(pause.endedAt, style: .date)
            Spacer()
            Label("\(Int(pause.duration / 60)) min", systemImage: "clock")
              .foregroundStyle(.secondary)
            Button("Delete Pause", systemImage: "trash", role: .destructive) {
              pausePendingDeletion = pause
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
          }
          .font(.subheadline)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func preparePauseTimer() {
    pauseTimer.reset(lengthInMinutes: durationInMinutes)
    pauseTimer.pauseCompletedAction = saveCompletedPause
  }

  private func togglePause() {
    if pauseTimer.isRunning {
      pauseTimer.stopPause()
      pauseTimer.reset(lengthInMinutes: durationInMinutes)
    } else {
      startedAt = .now
      pauseTimer.startPause()
    }
  }

  private func saveCompletedPause() {
    let endedAt = Date.now
    let startedAt =
      startedAt
      ?? endedAt.addingTimeInterval(
        TimeInterval(-durationInMinutes * 60)
      )
    let pause = Pause(
      duration: TimeInterval(durationInMinutes * 60),
      startedAt: startedAt,
      endedAt: endedAt
    )

    do {
      try modelContext.performTransactionOrRollback {
        modelContext.insert(pause)
      }
      self.startedAt = nil
    } catch {
      persistenceError = error.localizedDescription
    }
  }

  private var isShowingDeleteConfirmation: Binding<Bool> {
    Binding(
      get: { pausePendingDeletion != nil },
      set: { if !$0 { pausePendingDeletion = nil } }
    )
  }

  private var isShowingPersistenceError: Binding<Bool> {
    Binding(
      get: { persistenceError != nil },
      set: { if !$0 { persistenceError = nil } }
    )
  }

  private func deletePendingPause() {
    guard let pausePendingDeletion else {
      return
    }

    do {
      try modelContext.performTransactionOrRollback {
        modelContext.delete(pausePendingDeletion)
      }
      self.pausePendingDeletion = nil
    } catch {
      self.pausePendingDeletion = nil
      persistenceError = error.localizedDescription
    }
  }
}

#Preview {
  PausesView()
    .environment(AppEnvironment.preview)
    .sampleDataContainer()
}
