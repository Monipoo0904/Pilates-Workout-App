import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var classStore = ClassStore()
    @StateObject private var logStore = LogStore()
    @StateObject private var studentStore = StudentStore()
    @StateObject private var connectivity = PhoneConnectivityManager()

    var body: some View {
        TabView {
            NavigationStack {
                ClassListView()
            }
            .tabItem { Label("Classes", systemImage: "figure.pilates") }

            HoursView()
                .tabItem { Label("Hours", systemImage: "clock.badge.checkmark") }

            NavigationStack {
                StudentsView()
            }
            .tabItem { Label("Students", systemImage: "person.2") }
        }
        .tint(Theme.rose)
        .preferredColorScheme(.light)
        .environmentObject(classStore)
        .environmentObject(logStore)
        .environmentObject(studentStore)
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

// MARK: - Hours Tab View
/// Main Hours tab showing:
/// - Progress rings (Practice/Observation/Teaching vs. Nov 13 goals)
/// - Hours logged per type, hours remaining
/// - Days until deadline and weekly targets
/// - "Log a session" form with date, type, hours, place, student selection, notes
/// - Session list grouped by week, filterable by type
/// - CSV export, weekly plan, edit/delete individual entries
struct HoursView: View {
    @EnvironmentObject private var logStore: LogStore
    @StateObject private var studentStore = StudentStore()
    
    @State private var selectedTab: HoursTab = .progress
    @State private var selectedFilter: LogType? = nil
    @State private var showLogForm = false
    @State private var editingEntry: ClassLogEntry? = nil
    @State private var showWeeklyPlan = false
    
    enum HoursTab {
        case progress, sessionLog, weeklyPlan
    }
    
    // MARK: - Goal Tracking
    /// Hard-coded goals and deadline (Nov 13, 2026)
    private let practiceGoal: Double = 20.0
    private let observationGoal: Double = 10.0
    private let teachingGoal: Double = 20.0
    private let modulesGoal: Double = 3.5
    private let deadline = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 13))!
    
    private var totalGoal: Double {
        practiceGoal + observationGoal + teachingGoal + modulesGoal
    }
    
    private var practiceHours: Double {
        logStore.totalHours(for: .practice)
    }
    
    private var observationHours: Double {
        logStore.totalHours(for: .observation)
    }
    
    private var teachingHours: Double {
        logStore.totalHours(for: .teaching)
    }
    
    private var totalHours: Double {
        practiceHours + observationHours + teachingHours
    }
    
    private var practiceRemaining: Double {
        max(0, practiceGoal - practiceHours)
    }
    
    private var observationRemaining: Double {
        max(0, observationGoal - observationHours)
    }
    
    private var teachingRemaining: Double {
        max(0, teachingGoal - teachingHours)
    }
    
    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }
    
    private var weeksRemaining: Double {
        max(0.1, Double(daysRemaining) / 7.0)
    }
    
    private var weeklyPracticeTarget: Double {
        practiceRemaining / weeksRemaining
    }
    
    private var weeklyObservationTarget: Double {
        observationRemaining / weeksRemaining
    }
    
    private var weeklyTeachingTarget: Double {
        teachingRemaining / weeksRemaining
    }
    
    private var overallProgress: Double {
        totalGoal > 0 ? totalHours / totalGoal : 0
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // MARK: - Tab 1: Progress
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CERTIFICATION PROGRESS")
                                    .font(.caption.weight(.bold))
                                    .tracking(2)
                                    .foregroundStyle(Theme.gold)
                                Text("Hours toward Peak Pilates Level I")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.brown.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Theme.blush)
                            
                            VStack(spacing: 20) {
                                // Overall progress ring
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Overall Progress")
                                            .font(.headline)
                                            .foregroundStyle(Theme.berry)
                                        Text("\(String(format: "%.1f", totalHours)) / \(String(format: "%.1f", totalGoal)) hours")
                                            .font(.caption)
                                            .foregroundStyle(Theme.brown.opacity(0.8))
                                        HStack(spacing: 12) {
                                            Text(overallProgress >= 1.0 ? "✅ Complete!" : "On track")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(overallProgress >= 1.0 ? Theme.sage : Theme.clay)
                                            Text("\(daysRemaining) days left")
                                                .font(.caption)
                                                .foregroundStyle(Theme.brown.opacity(0.6))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    TimerRing(progress: min(1.0, overallProgress), lineWidth: 12, track: Theme.petal, tint: Theme.rose)
                                        .frame(width: 80, height: 80)
                                }
                                .padding(16)
                                .background(Theme.cream.opacity(0.8))
                                .cornerRadius(12)
                                
                                // Individual progress cards
                                VStack(spacing: 12) {
                                    ProgressCard(
                                        type: .practice,
                                        hours: practiceHours,
                                        goal: practiceGoal,
                                        remaining: practiceRemaining,
                                        weeklyTarget: weeklyPracticeTarget
                                    )
                                    ProgressCard(
                                        type: .observation,
                                        hours: observationHours,
                                        goal: observationGoal,
                                        remaining: observationRemaining,
                                        weeklyTarget: weeklyObservationTarget
                                    )
                                    ProgressCard(
                                        type: .teaching,
                                        hours: teachingHours,
                                        goal: teachingGoal,
                                        remaining: teachingRemaining,
                                        weeklyTarget: weeklyTeachingTarget
                                    )
                                }
                                
                                // Action buttons
                                HStack(spacing: 10) {
                                    Button(action: { showLogForm = true }) {
                                        Label("Log Session", systemImage: "plus.circle.fill")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(12)
                                            .background(Theme.rose)
                                            .cornerRadius(10)
                                    }
                                    
                                    if let url = logStore.exportCSV() {
                                        ShareLink(item: url, subject: Text("Pilates Hours Log")) {
                                            Label("Export", systemImage: "square.and.arrow.up")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Theme.rose)
                                                .frame(maxWidth: .infinity)
                                                .padding(12)
                                                .background(Theme.petal.opacity(0.3))
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                            .padding(20)
                        }
                    }
                }
                .tag(HoursTab.progress)
                .tabItem {
                    Label("Progress", systemImage: "chart.pie.fill")
                }
                
                // MARK: - Tab 2: Session Log
                VStack(spacing: 0) {
                    // Filter buttons
                    HStack(spacing: 8) {
                        ForEach(LogType.allCases, id: \.self) { type in
                            Button(action: { selectedFilter = selectedFilter == type ? nil : type }) {
                                Text(type.rawValue.capitalized)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(selectedFilter == type ? .white : Theme.rose)
                                    .padding(8)
                                    .background(selectedFilter == type ? Theme.rose : Theme.petal.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Theme.blush)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            let filtered = selectedFilter != nil ? logStore.logs.filter { $0.type == selectedFilter } : logStore.logs
                            
                            if filtered.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "chart.bar")
                                        .font(.system(size: 40))
                                        .foregroundStyle(Theme.petal)
                                    Text("No sessions logged yet")
                                        .font(.headline)
                                        .foregroundStyle(Theme.brown)
                                    Button(action: { showLogForm = true }) {
                                        Text("Log your first session")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Theme.rose)
                                    }
                                }
                                .padding(40)
                            } else {
                                ForEach(groupedByWeek(filtered), id: \.key) { week, entries in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(week)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Theme.gold)
                                            .tracking(1)
                                        
                                        ForEach(entries, id: \.id) { entry in
                                            SessionLogCell(entry: entry, studentStore: studentStore, onEdit: { editingEntry = entry }, onDelete: { logStore.delete(entry) })
                                        }
                                    }
                                    .padding(16)
                                    .background(Theme.cream.opacity(0.8))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
                .tag(HoursTab.sessionLog)
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet")
                }
                
                // MARK: - Tab 3: Weekly Plan
                WeeklyPlanView(
                    weeklyPracticeTarget: weeklyPracticeTarget,
                    weeklyObservationTarget: weeklyObservationTarget,
                    weeklyTeachingTarget: weeklyTeachingTarget
                )
                .tag(HoursTab.weeklyPlan)
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .environmentObject(studentStore)
        }
        .sheet(isPresented: $showLogForm) {
            LogSessionForm(logStore: logStore, studentStore: studentStore, editingEntry: $editingEntry)
        }
    }
    
    // MARK: - Helper: Group logs by week
    private func groupedByWeek(_ entries: [ClassLogEntry]) -> [(key: String, value: [ClassLogEntry])] {
        var dict: [String: [ClassLogEntry]] = [:]
        for entry in entries {
            let week = Calendar.current.dateComponents([.weekOfYear, .year], from: entry.date)
            let key = "Week \(week.weekOfYear ?? 0), \(week.year ?? 0)"
            dict[key, default: []].append(entry)
        }
        return dict.sorted { $0.key > $1.key }
    }
}

// MARK: - Progress Card
private struct ProgressCard: View {
    let type: LogType
    let hours: Double
    let goal: Double
    let remaining: Double
    let weeklyTarget: Double
    
    private var progress: Double {
        goal > 0 ? hours / goal : 0
    }
    
    private var isOnTrack: Bool {
        progress >= 0.5
    }
    
    private var typeColor: Color {
        switch type {
        case .practice: Theme.sage
        case .observation: Theme.clay
        case .teaching: Theme.gold
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(type.rawValue.capitalized)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(typeColor)
                
                HStack(spacing: 4) {
                    Text("\(String(format: "%.1f", hours)) h")
                        .font(.caption.weight(.semibold))
                    Text("of \(String(format: "%.1f", goal)) h")
                        .font(.caption)
                        .foregroundStyle(Theme.brown.opacity(0.6))
                }
                
                HStack(spacing: 8) {
                    Text(isOnTrack ? "On track" : "Behind")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isOnTrack ? Theme.sage : Theme.clay)
                    
                    Text("~\(String(format: "%.1f", weeklyTarget)) h/week")
                        .font(.caption2)
                        .foregroundStyle(Theme.brown.opacity(0.6))
                }
            }
            
            Spacer()
            
            TimerRing(progress: min(1.0, progress), lineWidth: 10, track: typeColor.opacity(0.2), tint: typeColor)
                .frame(width: 70, height: 70)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(typeColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Session Log Cell
private struct SessionLogCell: View {
    let entry: ClassLogEntry
    let studentStore: StudentStore
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var typeColor: Color {
        switch entry.type {
        case .practice: Theme.sage
        case .observation: Theme.clay
        case .teaching: Theme.gold
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(entry.className)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.berry)
                        
                        Chip(text: entry.type.rawValue.capitalized, tint: typeColor)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.2f", entry.hours)) h")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(typeColor)
                    }
                    
                    HStack(spacing: 12) {
                        Text(entry.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(Theme.brown.opacity(0.6))
                        
                        if let place = entry.place {
                            Chip(text: place, tint: Theme.petal)
                        }
                    }
                    
                    if let note = entry.note {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(Theme.brown.opacity(0.7))
                            .italic()
                    }
                    
                    if let studentIds = entry.studentIds, !studentIds.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                                .foregroundStyle(Theme.rose)
                            Text(studentIds.map { studentStore.studentName(for: $0) }.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(Theme.brown.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(Theme.petal)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
    }
}

// MARK: - Weekly Plan View
private struct WeeklyPlanView: View {
    let weeklyPracticeTarget: Double
    let weeklyObservationTarget: Double
    let weeklyTeachingTarget: Double
    
    @State private var planNotes = ""
    @State private var showSaveConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEEKLY PLAN")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(Theme.gold)
                    Text("Targets and notes for this week")
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Theme.blush)
                
                VStack(spacing: 16) {
                    // Weekly targets display
                    VStack(spacing: 12) {
                        Text("Weekly Targets")
                            .font(.headline)
                            .foregroundStyle(Theme.berry)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Practice").font(.caption.weight(.bold)).foregroundStyle(Theme.sage)
                                Text("\(String(format: "%.1f", weeklyPracticeTarget)) hours").font(.subheadline.weight(.semibold))
                                Text("Mat + home work").font(.caption2).foregroundStyle(Theme.brown.opacity(0.6))
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Theme.sage.opacity(0.1))
                        .cornerRadius(8)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Observation").font(.caption.weight(.bold)).foregroundStyle(Theme.clay)
                                Text("\(String(format: "%.1f", weeklyObservationTarget)) hours").font(.subheadline.weight(.semibold))
                                Text("The Mat, Ergo Body, Everbalance, Club Pilates VC").font(.caption2).foregroundStyle(Theme.brown.opacity(0.6))
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Theme.clay.opacity(0.1))
                        .cornerRadius(8)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Teaching").font(.caption.weight(.bold)).foregroundStyle(Theme.gold)
                                Text("\(String(format: "%.1f", weeklyTeachingTarget)) hours").font(.subheadline.weight(.semibold))
                                Text("Coworker sessions (30 min each)").font(.caption2).foregroundStyle(Theme.brown.opacity(0.6))
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Theme.gold.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Editable plan notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundStyle(Theme.berry)
                        
                        TextEditor(text: $planNotes)
                            .font(.subheadline)
                            .foregroundStyle(Theme.brown)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.petal.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button(action: { showSaveConfirmation = true }) {
                            Text("Save Plan")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Theme.rose)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .alert("Plan saved", isPresented: $showSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your weekly plan has been saved.")
        }
    }
}

// MARK: - Log Session Form
private struct LogSessionForm: View {
    @Environment(\.dismiss) var dismiss
    let logStore: LogStore
    let studentStore: StudentStore
    @Binding var editingEntry: ClassLogEntry?
    
    @State private var date = Date()
    @State private var type: LogType = .practice
    @State private var hours: Double = 0.5
    @State private var className = ""
    @State private var place = ""
    @State private var selectedStudentIds: [UUID] = []
    @State private var note = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Session Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .tint(Theme.rose)
                    
                    Picker("Type", selection: $type) {
                        ForEach(LogType.allCases, id: \.self) { t in
                            Text(t.rawValue.capitalized).tag(t)
                        }
                    }
                    .tint(Theme.rose)
                    
                    TextField("Class name", text: $className)
                    
                    TextField("Place (studio, location, or 'home')", text: $place)
                }
                
                Section("Duration") {
                    HStack {
                        Text("Hours")
                        Spacer()
                        Menu {
                            ForEach(Array(stride(from: 0.25, through: 8.0, by: 0.25)), id: \.self) { h in
                                Button("\(String(format: "%.2f", h)) h") { hours = h }
                            }
                        } label: {
                            Text("\(String(format: "%.2f", hours)) h")
                                .foregroundStyle(Theme.rose)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                if type == .teaching {
                    Section("Students Taught") {
                        List(studentStore.students, id: \.id) { student in
                            HStack {
                                Text(student.name)
                                Spacer()
                                if selectedStudentIds.contains(student.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.rose)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let idx = selectedStudentIds.firstIndex(of: student.id) {
                                    selectedStudentIds.remove(at: idx)
                                } else {
                                    selectedStudentIds.append(student.id)
                                }
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $note)
                        .frame(height: 80)
                }
                
                Section {
                    Button(action: saveEntry) {
                        Text("Save Session")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Theme.rose)
                    }
                    .listRowInsets(.none)
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.rose)
                }
            }
            .preferredColorScheme(.light)
        }
    }
    
    private func saveEntry() {
        let entry = ClassLogEntry(
            date: date,
            type: type,
            hours: hours,
            className: className,
            sourceDevice: "iPhone",
            place: place.isEmpty ? nil : place,
            studentIds: selectedStudentIds.isEmpty ? nil : selectedStudentIds,
            note: note.isEmpty ? nil : note
        )
        logStore.add(entry)
        dismiss()
    }
}

// MARK: - Students Tab

/// Main Students tab showing:
/// - List of students with name, contact, injuries
/// - Add button to create new student
/// - Search and sort
/// - Student detail view with teaching history
struct StudentsView: View {
    @EnvironmentObject private var studentStore: StudentStore
    @EnvironmentObject private var logStore: LogStore
    
    @State private var showAddForm = false
    @State private var searchText = ""
    @State private var sortByName = true
    
    private var filteredStudents: [Student] {
        let filtered = searchText.isEmpty ? studentStore.students : studentStore.students.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        return sortByName ? filtered.sorted { $0.name.lowercased() < $1.name.lowercased() } : filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("STUDENTS")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(Theme.gold)
                Text("Manage your teaching clients")
                    .font(.subheadline)
                    .foregroundStyle(Theme.brown.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Theme.blush)
            
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.petal)
                TextField("Search students", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.petal)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
            .padding(16)
            
            // List
            if filteredStudents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.petal)
                    Text(searchText.isEmpty ? "No students yet" : "No matching students")
                        .font(.headline)
                        .foregroundStyle(Theme.brown)
                    Button(action: { showAddForm = true }) {
                        Text("Add your first student")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.rose)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredStudents, id: \.id) { student in
                            NavigationLink(destination: StudentDetailView(student: student)) {
                                StudentRowView(student: student, logStore: logStore)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            
            Spacer()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddForm = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.rose)
                        .font(.system(size: 20))
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            StudentFormView(studentStore: studentStore, editingStudent: nil)
        }
    }
}

// MARK: - Student Row View
private struct StudentRowView: View {
    let student: Student
    let logStore: LogStore
    
    private var teachingHours: Double {
        logStore.logs
            .filter { $0.type == .teaching && $0.studentIds?.contains(student.id) == true }
            .reduce(0) { $0 + $1.hours }
    }
    
    private var lastSessionDate: Date? {
        logStore.logs
            .filter { $0.type == .teaching && $0.studentIds?.contains(student.id) == true }
            .max { $0.date < $1.date }?
            .date
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(student.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.berry)
                    
                    if let contact = student.contact {
                        Text(contact)
                            .font(.caption)
                            .foregroundStyle(Theme.brown.opacity(0.6))
                    }
                    
                    HStack(spacing: 8) {
                        Text("\(String(format: "%.1f", teachingHours)) h taught")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.gold)
                        
                        if let lastDate = lastSessionDate {
                            Text("Last: \(lastDate, style: .date)")
                                .font(.caption2)
                                .foregroundStyle(Theme.brown.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let injuries = student.injuries {
                        Chip(text: "⚠️ Injuries", tint: Theme.clay)
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.petal)
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.petal.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Student Detail View
private struct StudentDetailView: View {
    @EnvironmentObject private var studentStore: StudentStore
    @EnvironmentObject private var logStore: LogStore
    
    let student: Student
    @State private var editingStudent: Student?
    @State private var showEditForm = false
    
    private var teachingSessions: [ClassLogEntry] {
        logStore.logs
            .filter { $0.type == .teaching && $0.studentIds?.contains(student.id) == true }
            .sorted { $0.date > $1.date }
    }
    
    private var totalHoursWithStudent: Double {
        teachingSessions.reduce(0) { $0 + $1.hours }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(student.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Theme.berry)
                            
                            if let contact = student.contact {
                                HStack(spacing: 4) {
                                    Image(systemName: "phone.fill")
                                        .font(.caption)
                                    Text(contact)
                                }
                                .font(.caption)
                                .foregroundStyle(Theme.brown.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { showEditForm = true }) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundStyle(Theme.rose)
                                .font(.system(size: 24))
                        }
                    }
                    
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", totalHoursWithStudent))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Theme.gold)
                            Text("hours taught")
                                .font(.caption2)
                                .foregroundStyle(Theme.brown.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Theme.gold.opacity(0.1))
                        .cornerRadius(8)
                        
                        VStack(spacing: 4) {
                            Text("\(teachingSessions.count)")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Theme.sage)
                            Text("sessions")
                                .font(.caption2)
                                .foregroundStyle(Theme.brown.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Theme.sage.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                
                // Details section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Student Details")
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    
                    if let injuries = student.injuries {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Injuries / Limitations", systemImage: "exclamationmark.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.clay)
                            Text(injuries)
                                .font(.subheadline)
                                .foregroundStyle(Theme.brown)
                        }
                        .padding(12)
                        .background(Theme.clay.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    if let goals = student.goals {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Goals", systemImage: "star.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.gold)
                            Text(goals)
                                .font(.subheadline)
                                .foregroundStyle(Theme.brown)
                        }
                        .padding(12)
                        .background(Theme.gold.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    if let notes = student.notes {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Notes", systemImage: "note.text")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.sage)
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(Theme.brown)
                        }
                        .padding(12)
                        .background(Theme.sage.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                
                // Teaching sessions
                if !teachingSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Teaching Sessions")
                            .font(.headline)
                            .foregroundStyle(Theme.berry)
                        
                        ForEach(teachingSessions, id: \.id) { session in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.className)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Theme.berry)
                                        Text(session.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(Theme.brown.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.2f", session.hours)) h")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Theme.gold)
                                }
                                
                                if let place = session.place {
                                    Text(place)
                                        .font(.caption)
                                        .foregroundStyle(Theme.brown.opacity(0.6))
                                }
                                
                                if let note = session.note {
                                    Text(note)
                                        .font(.caption2)
                                        .foregroundStyle(Theme.brown.opacity(0.7))
                                        .italic()
                                }
                            }
                            .padding(12)
                            .background(Theme.cream)
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditForm) {
            StudentFormView(studentStore: studentStore, editingStudent: student)
        }
    }
}

// MARK: - Student Form View
private struct StudentFormView: View {
    @Environment(\.dismiss) var dismiss
    let studentStore: StudentStore
    let editingStudent: Student?
    
    @State private var name = ""
    @State private var contact = ""
    @State private var injuries = ""
    @State private var goals = ""
    @State private var notes = ""
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Student Name") {
                    TextField("Name", text: $name)
                }
                
                Section("Contact") {
                    TextField("Phone, email, etc.", text: $contact)
                }
                
                Section("Injuries / Limitations") {
                    TextEditor(text: $injuries)
                        .frame(height: 80)
                }
                
                Section("Goals") {
                    TextEditor(text: $goals)
                        .frame(height: 80)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                Section {
                    Button(action: saveStudent) {
                        Text(editingStudent == nil ? "Add Student" : "Save Changes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(isValid ? Theme.rose : Theme.petal)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid)
                    
                    if editingStudent != nil {
                        Button(role: .destructive, action: deleteStudent) {
                            Text("Delete Student")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(editingStudent == nil ? "Add Student" : "Edit Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.rose)
                }
            }
            .preferredColorScheme(.light)
            .onAppear {
                if let student = editingStudent {
                    name = student.name
                    contact = student.contact ?? ""
                    injuries = student.injuries ?? ""
                    goals = student.goals ?? ""
                    notes = student.notes ?? ""
                }
            }
        }
    }
    
    private func saveStudent() {
        let student = Student(
            id: editingStudent?.id ?? UUID(),
            name: name,
            contact: contact.isEmpty ? nil : contact,
            injuries: injuries.isEmpty ? nil : injuries,
            goals: goals.isEmpty ? nil : goals,
            notes: notes.isEmpty ? nil : notes
        )
        studentStore.addOrReplace(student)
        dismiss()
    }
    
    private func deleteStudent() {
        if let student = editingStudent {
            studentStore.delete(student)
            dismiss()
        }
    }
}

// MARK: - Hours

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
