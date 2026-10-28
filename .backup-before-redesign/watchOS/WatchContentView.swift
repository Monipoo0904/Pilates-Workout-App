import SwiftUI
import WatchKit

struct WatchContentView: View {
    @EnvironmentObject private var classStore: WatchClassStore
    @EnvironmentObject private var connectivity: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            List {
                Text(connectivity.status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(classStore.classes, id: \.id) { classValue in
                    NavigationLink(classValue.name) {
                        WatchRunView(plan: classValue)
                    }
                }
            }
            .navigationTitle("Classes")
        }
    }
}

struct WatchRunView: View {
    @EnvironmentObject private var logStore: WatchLogStore
    @EnvironmentObject private var connectivity: WatchConnectivityManager
    @StateObject private var controller: RunSessionController
    @StateObject private var workout = WorkoutSessionManager()

    @State private var showLogPrompt = false
    @State private var suggestedHours: Double = 0
    @State private var startedAt: Date?

    init(plan: PilatesClass) {
        _controller = StateObject(wrappedValue: RunSessionController(plan: plan))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if let item = controller.currentItem {
                    Text(item.section).font(.caption2).foregroundStyle(.secondary)
                    Text(item.name).font(.title3.weight(.semibold)).multilineTextAlignment(.center)
                    if !item.reps.isEmpty { Text(item.reps).font(.headline) }
                    Text(TimeFormat.mmss(controller.snapshot.currentItemRemaining))
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                    ProgressView(value: Double(controller.snapshot.currentItemElapsed), total: Double(max(item.seconds, 1)))
                    Text("Whole class: \(TimeFormat.mmss(controller.snapshot.classElapsed)) of \(TimeFormat.mmss(controller.snapshot.totalClassSeconds))")
                        .font(.footnote)
                    Text("Left: \(TimeFormat.mmss(controller.snapshot.classRemaining))").font(.footnote)
                    Text("Next: \(controller.nextItemName)").font(.caption2).foregroundStyle(.secondary)

                    if !item.cue.isEmpty || !item.buildingBlock.isEmpty || !item.modification.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            if !item.cue.isEmpty {
                                Text("Cue:").font(.caption2).foregroundStyle(.secondary)
                                Text(item.cue).font(.footnote)
                            }
                            if !item.buildingBlock.isEmpty {
                                Text("Building Block:").font(.caption2).foregroundStyle(.secondary)
                                Text(item.buildingBlock).font(.footnote)
                            }
                            if !item.modification.isEmpty {
                                Text("Modification:").font(.caption2).foregroundStyle(.red)
                                Text(item.modification).font(.footnote).foregroundStyle(.red)
                            }
                        }
                    }
                }

                HStack {
                    Button("Back") { controller.back() }
                    Button(controller.snapshot.isPaused ? "Resume" : "Pause") { controller.pauseResume() }
                    Button("Next") { controller.next() }
                }

                Button("End Class") {
                    controller.stop()
                    workout.endWorkout()
                    maybePromptForLog()
                }
            }
        }
        .onAppear {
            startedAt = Date()
            Task { await workout.requestAuthorization() }
            workout.startPilatesWorkout()
            controller.start { snapshot, previous in
                handleHaptics(snapshot: snapshot, previous: previous)
            }
        }
        .onDisappear {
            controller.stop()
            workout.endWorkout()
        }
        .onChange(of: controller.snapshot.isFinished) { _, done in
            if done {
                WKInterfaceDevice.current().play(.success)
                workout.endWorkout()
                maybePromptForLog()
            }
        }
        .alert("Log this class?", isPresented: $showLogPrompt) {
            Button("Teaching") { addLog(.teaching) }
            Button("Practice") { addLog(.practice) }
            Button("Observation") { addLog(.observation) }
            Button("Don't log", role: .cancel) { }
        } message: {
            Text("Hours: \(String(format: "%.2f", suggestedHours))")
        }
    }

    private func handleHaptics(snapshot: TimerSnapshot, previous: TimerSnapshot?) {
        guard !snapshot.isPaused else { return }
        if previous == nil || snapshot.currentIndex != previous?.currentIndex {
            WKInterfaceDevice.current().play(.start)
        }
        if previous?.currentItemRemaining != 10 && snapshot.currentItemRemaining == 10 {
            WKInterfaceDevice.current().play(.click)
        }
        if (1...3).contains(snapshot.currentItemRemaining) && previous?.currentItemRemaining != snapshot.currentItemRemaining {
            WKInterfaceDevice.current().play(.notification)
        }
    }

    private func maybePromptForLog() {
        guard let startedAt else { return }
        let elapsed = Int(Date().timeIntervalSince(startedAt))
        guard elapsed >= 60 else { return }
        suggestedHours = max(0.25, TimeFormat.hoursRoundedQuarter(from: elapsed))
        showLogPrompt = true
    }

    private func addLog(_ type: LogType) {
        let entry = ClassLogEntry(
            type: type,
            hours: suggestedHours,
            className: controller.plan.name,
            sourceDevice: "Watch"
        )
        logStore.add(entry)
        connectivity.sendLogsToPhone()
    }
}

#Preview {
    WatchRunView(plan: SampleData.starterClass)
        .environmentObject(WatchLogStore())
        .environmentObject(WatchConnectivityManager())
}
