import SwiftData
import SwiftUI

struct PausesView: View {
  @Environment(AppEnvironment.self) private var environment
  @Environment(DataContainer.self) private var dataContainer
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
          timer
          controls
          history
        }
        .padding(24)
      }
      .navigationTitle("Still")
      .onAppear {
        configureTimer()
      }
      .onDisappear {
        pauseTimer.stopPause()
      }
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
        Text(persistenceError ?? "Please try again.")
      }
    }
  }

  private var timer: some View {
    ZStack {
      Circle()
        .stroke(.quaternary, lineWidth: 24)

      Circle()
        .trim(from: 0, to: pauseTimer.progress)
        .stroke(
          environment.product.accent,
          style: StrokeStyle(lineWidth: 24, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(.linear(duration: 0.1), value: pauseTimer.progress)

      VStack(spacing: 8) {
        Text(
          Duration.seconds(pauseTimer.secondsRemaining),
          format: .time(pattern: .minuteSecond)
        )
        .font(.system(.largeTitle, design: .rounded, weight: .semibold))
        .monospacedDigit()

        Text(pauseTimer.isRunning ? "Breathe naturally" : "Take a quiet pause")
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: 300)
    .aspectRatio(1, contentMode: .fit)
    .accessibilityElement(children: .combine)
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
          configureTimer()
        }

        Button {
          if pauseTimer.isRunning {
            pauseTimer.stopPause()
            configureTimer()
          } else {
            startedAt = .now
            pauseTimer.startPause()
          }
        } label: {
          Label(
            pauseTimer.isRunning ? "End Pause" : "Begin Pause",
            systemImage: pauseTimer.isRunning ? "stop.fill" : "play.fill"
          )
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(environment.product.accent)
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
            Label(
              "\(Int(pause.duration / 60)) min",
              systemImage: "checkmark.circle.fill"
            )
            Spacer()
            Text(pause.endedAt, format: .dateTime.month().day().hour().minute())
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

  private func configureTimer() {
    pauseTimer.reset(duration: TimeInterval(durationInMinutes * 60))
    pauseTimer.pauseCompletedAction = saveCompletedPause
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
      try dataContainer.context.transactionOrRollback {
        dataContainer.context.insert(pause)
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
      try dataContainer.context.transactionOrRollback {
        dataContainer.context.delete(pausePendingDeletion)
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
