import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var classStore = ClassStore()
    @StateObject private var logStore = LogStore()
    @StateObject private var connectivity = PhoneConnectivityManager()

    var body: some View {
        TabView {
            NavigationStack {
                ClassListView()
            }
            .tabItem { Label("Classes", systemImage: "figure.pilates") }

            NavigationStack {
                LogsView()
            }
            .tabItem { Label("Hours", systemImage: "clock.badge.checkmark") }
        }
        .tint(Theme.rose)
        .preferredColorScheme(.light)
        .environmentObject(classStore)
        .environmentObject(logStore)
        .environmentObject(connectivity)
        .onChange(of: connectivity.latestWatchLogs) { _, logs in
            logStore.mergeRemote(logs)
        }
    }
}

// MARK: - Class list

struct ClassListView: View {
    @EnvironmentObject private var classStore: ClassStore
    @EnvironmentObject private var connectivity: PhoneConnectivityManager

    @State private var statusText = ""
    @State private var showImporter = false
    @State private var showBuilder = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MYVILLAGE PROJECT")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(Theme.gold)
                    Text("Pilates Timer")
                        .font(Theme.display(40))
                        .foregroundStyle(Theme.berry)
                    Text("Breathe, move and teach with confidence.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown.opacity(0.8))
                }
                .padding(.top, 8)

                HStack(spacing: 10) {
                    ActionTile(title: "Paste", icon: "doc.on.clipboard") { pasteClass() }
                    ActionTile(title: "Import", icon: "square.and.arrow.down") { showImporter = true }
                    ActionTile(title: "Build", icon: "hammer.fill") { showBuilder = true }
                    ActionTile(title: "Send to Watch", icon: "applewatch") {
                        connectivity.sendClasses(classStore.classes)
                    }
                }

                if !statusText.isEmpty || connectivity.syncStatus != "Not synced yet" {
                    Text(statusText.isEmpty ? connectivity.syncStatus : statusText)
                        .font(.caption)
                        .foregroundStyle(Theme.sage)
                }

                Text("Your classes")
                    .font(.headline)
                    .foregroundStyle(Theme.berry)
                    .padding(.top, 4)

                ForEach(classStore.classes, id: \.id) { classValue in
                    NavigationLink {
                        ClassDetailView(plan: classValue)
                    } label: {
                        ClassCard(plan: classValue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showBuilder) {
            WorkoutBuilderView()
                .environmentObject(classStore)
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let parsed = try classStore.importFile(url)
                        statusText = "Imported: \(parsed.name) (\(parsed.items.count) moves)"
                    } catch {
                        statusText = error.localizedDescription
                    }
                }
            case .failure(let error):
                statusText = error.localizedDescription
            }
        }
    }

    private func pasteClass() {
        guard let text = UIPasteboard.general.string else {
            statusText = "Clipboard is empty."
            return
        }
        do {
            let parsed = try classStore.importFromClipboard(text)
            statusText = "Imported: \(parsed.name) (\(parsed.items.count) moves)"
        } catch {
            statusText = error.localizedDescription
        }
    }
}

private struct ActionTile: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(Theme.berry)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.petal, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct ClassCard: View {
    let plan: PilatesClass

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Theme.rose, Theme.gold], startPoint: .top, endPoint: .bottom))
                .frame(width: 5)
            VStack(alignment: .leading, spacing: 8) {
                Text(plan.name)
                    .font(.system(.title3, design: .serif).weight(.bold).italic())
                    .foregroundStyle(Theme.berry)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Chip(text: plan.minutesLabel)
                    Chip(text: "\(plan.items.count) moves", tint: Theme.gold)
                }
                let extras = plan.props.filter { $0 != "Mat" }
                if !extras.isEmpty {
                    Text(extras.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Theme.sage)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.petal)
        }
        .padding(16)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: Theme.berry.opacity(0.08), radius: 10, y: 4)
    }
}

// MARK: - Class detail

struct WorkoutBuilderView: View {
    @EnvironmentObject private var classStore: ClassStore
    @Environment(\.dismiss) private var dismiss

    @State private var workoutName = ""
    @State private var props: [String] = ["Mat"]
    @State private var selectedSeries = WorkoutSeries.lunge
    @State private var moveName = ""
    @State private var reps = "8 each side"
    @State private var seconds = 30
    @State private var setup = ""
    @State private var cue = ""
    @State private var modification = ""
    @State private var transition = ""
    @State private var items: [PilatesClassItem] = []
    @State private var statusText = ""

    private var currentSuggestions: [String] {
        let built = selectedSeries.defaultSuggestions
        return built.filter { suggestion in
            !items.contains(where: { $0.name.lowercased() == suggestion.lowercased() })
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("Workout name", text: $workoutName)
                    TextField("Props (comma separated)", text: Binding(
                        get: { props.joined(separator: ", ") },
                        set: { props = $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } }
                    ))
                }

                Section("Add movement") {
                    Picker("Series", selection: $selectedSeries) {
                        ForEach(WorkoutSeries.allCases) { series in
                            Text(series.label).tag(series)
                        }
                    }
                    TextField("Move name", text: $moveName)
                    TextField("Reps", text: $reps)
                    Stepper("Seconds: \(seconds)", value: $seconds, in: 10...90, step: 5)
                    TextField("Setup", text: $setup)
                    TextField("Cue", text: $cue)
                    TextField("Modification", text: $modification)
                    TextField("Transition", text: $transition)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Suggested moves")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.rose)
                        ForEach(currentSuggestions.prefix(6), id: \.self) { suggestion in
                            Button(action: { applySuggestion(suggestion) }) {
                                Text("• \(suggestion)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("Add move") {
                        addSelectedMove()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section("Workout flow") {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.name)
                                    .font(.headline)
                                Spacer()
                                Text(item.series.label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.rose)
                            }
                            Text("\(item.reps) · \(TimeFormat.mmss(item.seconds))")
                                .font(.caption)
                                .foregroundStyle(Theme.brown)
                            if !item.modification.isEmpty {
                                Text("Mod: \(item.modification)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.brown)
                            }
                        }
                    }
                }

                if !statusText.isEmpty {
                    Section {
                        Text(statusText)
                            .foregroundStyle(Theme.sage)
                    }
                }
            }
            .navigationTitle("Workout Builder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .disabled(workoutName.isEmpty || items.isEmpty)
                }
            }
        }
    }

    private func applySuggestion(_ suggestion: String) {
        moveName = suggestion
        reps = suggestion.contains("pulse") ? "8-12 pulses" : suggestion.contains("hold") ? "20-30 sec" : suggestion.contains("push") ? "8-12" : "6-10 each side"
        setup = selectedSeries == .abs ? "Lie on your back with the ribs down and the lower back gently anchored." : selectedSeries == .arms ? "Set up in a stable plank or kneeling position with shoulders stacked." : selectedSeries == .squat ? "Feet hip-width and chest tall with knees tracking over toes." : "Stand tall with a split stance and the torso lifted."
        cue = selectedSeries == .abs ? "Keep the movement slow and control the breath." : "Move with control and keep the shape long through the torso."
        modification = selectedSeries.defaultModification
    }

    private func addSelectedMove() {
        let finalName = moveName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalName.isEmpty else {
            statusText = "Add a move name before saving."
            return
        }

        let item = PilatesClassItem(
            section: selectedSeries.label,
            name: finalName,
            reps: reps.isEmpty ? "8 each side" : reps,
            seconds: max(seconds, 10),
            setup: setup,
            cue: cue,
            buildingBlock: "",
            modification: modification.isEmpty ? selectedSeries.defaultModification : modification,
            transition: transition,
            props: selectedSeries == .abs ? ["Mat"] : ["Mat"],
            series: selectedSeries
        )
        items.append(item)
        statusText = "Added \(finalName) to \(selectedSeries.label)."
        moveName = ""
        reps = "8 each side"
        seconds = 30
        setup = ""
        cue = ""
        modification = ""
        transition = ""
    }

    private func saveWorkout() {
        let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !items.isEmpty else { statusText = "Name the workout and add at least one move."; return }
        let workout = PilatesClass(name: trimmedName, props: props.isEmpty ? ["Mat"] : props, items: items)
        classStore.addOrReplace(workout)
        statusText = "Saved \(trimmedName)."
        dismiss()
    }
}

struct ClassDetailView: View {
    let plan: PilatesClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(plan.name)
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.berry)
                HStack(spacing: 6) {
                    Chip(text: plan.minutesLabel)
                    Chip(text: "\(plan.items.count) moves", tint: Theme.gold)
                }
                if !plan.props.isEmpty {
                    Text("Bring: \(plan.props.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown)
                }

                NavigationLink {
                    PhoneRunView(plan: plan)
                } label: {
                    Label("Start class", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.rose, in: Capsule())
                        .foregroundStyle(.white)
                }
                Text("Your Apple Watch starts the same class automatically.")
                    .font(.caption)
                    .foregroundStyle(Theme.brown.opacity(0.7))
                    .frame(maxWidth: .infinity)

                ForEach(Array(plan.orderedItems.enumerated()), id: \.offset) { index, item in
                    if !item.section.isEmpty && (index == 0 || plan.orderedItems[index - 1].section != item.section) {
                        Text(item.section.uppercased())
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.rose)
                            .padding(.top, 8)
                    }
                    MoveCard(item: item)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Series suggestions")
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    ForEach(Array(WorkoutSeries.allCases), id: \.self) { series in
                        let suggestions = plan.suggestionsFor(series: series)
                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(series.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.rose)
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Text("• \(suggestion)")
                                        .font(.footnote)
                                        .foregroundStyle(Theme.brown)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MoveCard: View {
    let item: PilatesClassItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(Theme.berry)
                Spacer()
                Text(TimeFormat.mmss(item.seconds))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.rose)
            }
            if !item.reps.isEmpty {
                Text(item.reps)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brown)
            }
            if !item.setup.isEmpty {
                LabeledNote(title: "Setup", text: item.setup, icon: "figure.movement", color: Theme.berry)
            }
            if !item.cue.isEmpty {
                LabeledNote(title: "Cue", text: item.cue, icon: "quote.bubble.fill", color: Theme.rose)
            }
            if !item.buildingBlock.isEmpty {
                LabeledNote(title: "Building Block", text: item.buildingBlock, icon: "square.stack.3d.up.fill", color: Theme.sage)
            }
            if !item.modification.isEmpty {
                LabeledNote(title: "Modification", text: item.modification, icon: "exclamationmark.triangle.fill", color: Theme.clay)
            }
            if !item.transition.isEmpty {
                LabeledNote(title: "Transition", text: item.transition, icon: "arrow.turn.down.right", color: Theme.gold)
            }
            if !item.props.isEmpty {
                HStack(spacing: 6) {
                    ForEach(item.props, id: \.self) { Chip(text: $0, tint: Theme.sage) }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Run

struct PhoneRunView: View {
    @EnvironmentObject private var logStore: LogStore
    @EnvironmentObject private var connectivity: PhoneConnectivityManager
    @StateObject private var controller: RunSessionController
    @State private var promptVisible = false
    @State private var suggestedHours: Double = 0
    @State private var showTenMinutes = false

    init(plan: PilatesClass) {
        _controller = StateObject(wrappedValue: RunSessionController(plan: plan))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if !connectivity.watchStatus.isEmpty {
                    Label(connectivity.watchStatus, systemImage: "applewatch")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.sage)
                }

                if let item = controller.currentItem {
                    VStack(spacing: 6) {
                        if !item.section.isEmpty {
                            Text(item.section.uppercased())
                                .font(.caption.weight(.bold))
                                .tracking(1.5)
                                .foregroundStyle(Theme.rose)
                        }
                        Text(item.name)
                            .font(Theme.display(30))
                            .foregroundStyle(Theme.berry)
                            .multilineTextAlignment(.center)
                        if !item.reps.isEmpty {
                            Text(item.reps).font(.headline).foregroundStyle(Theme.brown)
                        }
                    }

                    ZStack {
                        TimerRing(
                            progress: Double(controller.snapshot.currentItemElapsed) / Double(max(item.seconds, 1)),
                            lineWidth: 16
                        )
                        VStack(spacing: 2) {
                            Text(TimeFormat.mmss(controller.snapshot.currentItemRemaining))
                                .font(.system(size: 62, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(Theme.berry)
                            Text("this move")
                                .font(.caption)
                                .foregroundStyle(Theme.brown.opacity(0.7))
                        }
                    }
                    .frame(width: 240, height: 240)

                    VStack(spacing: 6) {
                        ProgressView(
                            value: Double(controller.snapshot.classElapsed),
                            total: Double(max(controller.snapshot.totalClassSeconds, 1))
                        )
                        .tint(Theme.gold)
                        HStack {
                            Text("\(TimeFormat.mmss(controller.snapshot.classElapsed)) done")
                            Spacer()
                            Text("\(TimeFormat.mmss(controller.snapshot.classRemaining)) left")
                        }
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.brown)
                    }

                    Label("Next: \(controller.nextItemName)", systemImage: "arrow.forward.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.rose)
                }

                HStack(spacing: 28) {
                    RoundControl(icon: "backward.fill", size: 58) { controller.back() }
                    RoundControl(icon: controller.snapshot.isPaused ? "play.fill" : "pause.fill", size: 78, filled: true) {
                        controller.pauseResume()
                    }
                    RoundControl(icon: "forward.fill", size: 58) { controller.next() }
                }

                if let item = controller.currentItem {
                    MoveCard(item: item)
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .overlay(alignment: .top) {
            if showTenMinutes {
                Label("10 minutes left", systemImage: "bell.fill")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Theme.berry, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            controller.start()
            connectivity.startClassOnWatch(controller.plan)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            controller.stop()
        }
        .onChange(of: controller.snapshot.classRemaining) { old, new in
            if ClassAlerts.crossedTenMinutes(old: old, new: new, total: controller.snapshot.totalClassSeconds) {
                announceTenMinutes()
            }
        }
        .onChange(of: controller.snapshot.isFinished) { _, done in
            if done {
                suggestedHours = max(0.25, TimeFormat.hoursRoundedQuarter(from: controller.snapshot.classElapsed))
                promptVisible = true
            }
        }
        .alert("Log this class?", isPresented: $promptVisible) {
            Button("Teaching") { addLog(.teaching) }
            Button("Practice") { addLog(.practice) }
            Button("Observation") { addLog(.observation) }
            Button("Don’t log", role: .cancel) { }
        } message: {
            Text("Hours: \(String(format: "%.2f", suggestedHours))")
        }
    }

    private func announceTenMinutes() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        withAnimation(.spring) { showTenMinutes = true }
        Task {
            try? await Task.sleep(for: .seconds(6))
            withAnimation { showTenMinutes = false }
        }
    }

    private func addLog(_ type: LogType) {
        let entry = ClassLogEntry(
            type: type,
            hours: suggestedHours,
            className: controller.plan.name,
            sourceDevice: "iPhone"
        )
        logStore.add(entry)
    }
}

private struct RoundControl: View {
    let icon: String
    let size: CGFloat
    var filled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.34, weight: .bold))
                .frame(width: size, height: size)
                .foregroundStyle(filled ? Color.white : Theme.rose)
                .background(
                    Circle().fill(filled ? Theme.rose : Theme.cream)
                )
                .overlay(Circle().stroke(Theme.petal, lineWidth: filled ? 0 : 1.5))
                .shadow(color: Theme.berry.opacity(filled ? 0.25 : 0.06), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hours

struct LogsView: View {
    @EnvironmentObject private var logStore: LogStore
    @State private var exportURL: URL?
    @State private var showShare = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Certification hours")
                    .font(Theme.display(32))
                    .foregroundStyle(Theme.berry)

                HStack(spacing: 10) {
                    GoalCard(label: "Practice", current: logStore.totalHours(for: .practice), goal: 20, tint: Theme.rose)
                    GoalCard(label: "Observe", current: logStore.totalHours(for: .observation), goal: 10, tint: Theme.gold)
                    GoalCard(label: "Teaching", current: logStore.totalHours(for: .teaching), goal: 20, tint: Theme.berry)
                }

                Text("Entries")
                    .font(.headline)
                    .foregroundStyle(Theme.berry)
                    .padding(.top, 6)

                if logStore.logs.isEmpty {
                    Text("Finish a class and choose Teaching, Practice or Observation to log it here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown.opacity(0.7))
                }

                ForEach(logStore.logs) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(log.className).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.berry)
                            Text("\(log.date.formatted(date: .abbreviated, time: .shortened)) · \(log.sourceDevice)")
                                .font(.caption)
                                .foregroundStyle(Theme.brown.opacity(0.7))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(String(format: "%.2f h", log.hours)).font(.subheadline.monospacedDigit().weight(.semibold))
                            Chip(text: log.type.rawValue.capitalized, tint: tint(for: log.type))
                        }
                    }
                    .padding(14)
                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Export CSV") {
                    exportURL = logStore.exportCSV()
                    showShare = exportURL != nil
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let exportURL {
                ShareSheet(activityItems: [exportURL])
            }
        }
    }

    private func tint(for type: LogType) -> Color {
        switch type {
        case .practice: return Theme.rose
        case .observation: return Theme.gold
        case .teaching: return Theme.berry
        }
    }
}

private struct GoalCard: View {
    let label: String
    let current: Double
    let goal: Double
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                TimerRing(progress: current / goal, lineWidth: 8, track: tint.opacity(0.15), tint: tint)
                Text(String(format: "%.1f", current))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.berry)
            }
            .frame(width: 70, height: 70)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Theme.brown)
            Text("of \(Int(goal)) h").font(.caption2).foregroundStyle(Theme.brown.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
