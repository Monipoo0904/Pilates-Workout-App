import SwiftUI
import WatchKit

/// A run screen to open, either tapped from the list or sent from the iPhone.
struct RunTarget: Hashable {
    let token: UUID
    let plan: PilatesClass
}

struct WatchContentView: View {
    @EnvironmentObject private var classStore: WatchClassStore
    @EnvironmentObject private var connectivity: WatchConnectivityManager
    @State private var path: [RunTarget] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pilates Timer")
                            .font(.system(.title3, design: .serif).weight(.heavy).italic())
                            .foregroundStyle(Theme.petal)
                        Text(connectivity.status)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                }

                ForEach(classStore.classes, id: \.id) { classValue in
                    NavigationLink(value: RunTarget(token: UUID(), plan: classValue)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(classValue.name)
                                .font(.headline)
                                .lineLimit(2)
                            Text("\(classValue.minutesLabel) · \(classValue.items.count) moves")
                                .font(.caption2)
                                .foregroundStyle(Theme.gold)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 14).fill(Theme.berry.opacity(0.55))
                    )
                }
            }
            .navigationTitle("Classes")
            .navigationDestination(for: RunTarget.self) { target in
                WatchRunView(plan: target.plan)
                    .id(target.token)
            }
        }
        .tint(Theme.rose)
        .onAppear { openRequestedClass() }
        .onChange(of: connectivity.startRequest) { _, _ in openRequestedClass() }
    }

    /// Jumps straight into a class the iPhone started.
    private func openRequestedClass() {
        guard let request = connectivity.startRequest else { return }
        path = [RunTarget(token: request.id, plan: request.plan)]
        connectivity.startRequest = nil
        connectivity.tellPhoneClassStarted()
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
    @State private var showTenMinutes = false

    init(plan: PilatesClass) {
        _controller = StateObject(wrappedValue: RunSessionController(plan: plan))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                if showTenMinutes {
                    Label("10 min left", systemImage: "bell.fill")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.gold, in: Capsule())
                        .foregroundStyle(.black)
                        .transition(.scale.combined(with: .opacity))
                }

                if let item = controller.currentItem {
                    if !item.section.isEmpty {
                        Text(item.section.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.petal)
                    }
                    Text(item.name)
                        .font(.system(.headline, design: .serif).italic())
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    ZStack {
                        TimerRing(
                            progress: Double(controller.snapshot.currentItemElapsed) / Double(max(item.seconds, 1)),
                            lineWidth: 8,
                            track: Theme.berry.opacity(0.7),
                            tint: Theme.rose
                        )
                        VStack(spacing: 0) {
                            Text(TimeFormat.mmss(controller.snapshot.currentItemRemaining))
                                .font(.system(size: 32, weight: .semibold, design: .rounded).monospacedDigit())
                            if !item.reps.isEmpty {
                                Text(item.reps)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.petal)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(width: 118, height: 118)

                    Text("\(TimeFormat.mmss(controller.snapshot.classRemaining)) left in class")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.gold)
                    Text("Next: \(controller.nextItemName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Button { controller.back() } label: { Image(systemName: "backward.fill") }
                        .buttonStyle(.bordered)
                    Button { controller.pauseResume() } label: {
                        Image(systemName: controller.snapshot.isPaused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    Button { controller.next() } label: { Image(systemName: "forward.fill") }
                        .buttonStyle(.bordered)
                }
                .tint(Theme.rose)

                if let item = controller.currentItem,
                   !item.setup.isEmpty || !item.cue.isEmpty || !item.buildingBlock.isEmpty || !item.modification.isEmpty || !item.transition.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if !item.setup.isEmpty {
                            LabeledNote(title: "Setup", text: item.setup, icon: "figure.movement", color: Theme.berry, textColor: .white)
                        }
                        if !item.cue.isEmpty {
                            LabeledNote(title: "Cue", text: item.cue, icon: "quote.bubble.fill", color: Theme.petal, textColor: .white)
                        }
                        if !item.buildingBlock.isEmpty {
                            LabeledNote(title: "Building Block", text: item.buildingBlock, icon: "square.stack.3d.up.fill", color: Theme.lightSage, textColor: .white)
                        }
                        if !item.modification.isEmpty {
                            LabeledNote(title: "Modification", text: item.modification, icon: "exclamationmark.triangle.fill", color: Theme.peach, textColor: .white)
                        }
                        if !item.transition.isEmpty {
                            LabeledNote(title: "Transition", text: item.transition, icon: "arrow.turn.down.right", color: Theme.gold, textColor: .white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                Button("End Class", role: .destructive) {
                    controller.stop()
                    workout.endWorkout()
                    maybePromptForLog()
                }
                .padding(.top, 4)
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
        .onChange(of: controller.snapshot.classRemaining) { old, new in
            if ClassAlerts.crossedTenMinutes(old: old, new: new, total: controller.snapshot.totalClassSeconds) {
                announceTenMinutes()
            }
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

    private func announceTenMinutes() {
        WKInterfaceDevice.current().play(.notification)
        withAnimation { showTenMinutes = true }
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            WKInterfaceDevice.current().play(.notification)
            try? await Task.sleep(for: .seconds(6))
            withAnimation { showTenMinutes = false }
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
    WatchRunView(plan: SampleData.fallIntoPilates)
        .environmentObject(WatchLogStore())
        .environmentObject(WatchConnectivityManager())
}
