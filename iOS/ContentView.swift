// ======================================================================
// ContentView.swift  (iPhone app)
// WHAT THIS FILE DOES: Every iPhone screen: the tab bar, Classes (list, detail, builders, edit), the class timer (run screen), Hours (progress, log, weekly plan), Library, and Students.
// TO CHANGE: Use Cmd+F to jump to a screen name below (e.g. "struct HoursView"). Each screen has a WHAT / TO CHANGE note above it.
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import SwiftUI
import UIKit
import UniformTypeIdentifiers

// WHAT: The iPhone tab bar (Classes, Hours, Students, Library) and the shared data every tab uses.
// TO CHANGE: Tab names, icons or order: edit the .tabItem lines below.
struct ContentView: View {
    @StateObject private var classStore = ClassStore()
    @StateObject private var logStore = LogStore()
    @StateObject private var studentStore = StudentStore()
    @StateObject private var libraryStore = LibraryStore()
    @StateObject private var connectivity = PhoneConnectivityManager()
    @StateObject private var examPrepStore = ExamPrepStore()

    var body: some View {
        TabView {
            NavigationStack {
                ClassListView()
            }
            .tabItem { Label("Classes", systemImage: "figure.pilates") }

            NavigationStack {
                ExamPrepHomeView()
            }
            .tabItem { Label("Exam Prep", systemImage: "checklist") }

            HoursView()
                .tabItem { Label("Hours", systemImage: "clock.badge.checkmark") }

            NavigationStack {
                StudentsView()
            }
            .tabItem { Label("Students", systemImage: "person.2") }

            NavigationStack {
                LibraryView()
            }
            .tabItem { Label("Library", systemImage: "books.vertical") }
        }
        .tint(Theme.rose)
        .preferredColorScheme(.light)
        .environmentObject(classStore)
        .environmentObject(logStore)
        .environmentObject(studentStore)
        .environmentObject(libraryStore)
        .environmentObject(connectivity)
        .environmentObject(examPrepStore)
        .onChange(of: connectivity.latestWatchLogs) { _, logs in
            logStore.mergeRemote(logs)
        }
        // WHAT: keeps the watch up to date. Any new, edited or deleted class is sent to the watch automatically.
        .onChange(of: classStore.classes) { _, classes in
            connectivity.sendClasses(classes)
        }
        .task { connectivity.sendClasses(classStore.classes) }
    }
}

// MARK: - Class list

// WHAT: Classes tab home screen: title, Paste / Import / Send to Watch buttons, and your class cards.
// TO CHANGE: Header text: the Text("Pilates Timer") lines. Buttons: the ActionTile lines.
struct ClassListView: View {
    @EnvironmentObject private var classStore: ClassStore
    @EnvironmentObject private var libraryStore: LibraryStore
    @EnvironmentObject private var connectivity: PhoneConnectivityManager
    @EnvironmentObject private var examPrepStore: ExamPrepStore

    @State private var statusText = ""
    @State private var showImporter = false
    @State private var builder: BuilderStart?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CLASSES")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(Theme.gold)
                    Text("Plan & teach Peak Pilates Level I")
                        .font(Theme.display(30))
                        .foregroundStyle(Theme.berry)
                    Text("Build, customize, and run your class.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown.opacity(0.8))
                }
                .padding(.top, 8)

                HStack(spacing: 10) {
                    ActionTile(title: "New class", icon: "plus") { builder = .blank }
                    ActionTile(title: "Level I", icon: "list.bullet.clipboard") { builder = .levelI }
                    ActionTile(title: "Import", icon: "square.and.arrow.down") { showImporter = true }
                    ActionTile(title: "Watch", icon: "applewatch") {
                        connectivity.sendClasses(classStore.classes)
                    }
                }

                if !statusText.isEmpty || connectivity.syncStatus != "Not synced yet" {
                    Text(statusText.isEmpty ? connectivity.syncStatus : statusText)
                        .font(.caption)
                        .foregroundStyle(Theme.sage)
                }

                NavigationLink {
                    ExamPrepHomeView()
                } label: {
                    ExamPrepSummaryCard()
                        .environmentObject(examPrepStore)
                }
                .buttonStyle(.plain)

                Text("Your classes")
                    .font(.headline)
                    .foregroundStyle(Theme.berry)
                    .padding(.top, 4)

                if classStore.classes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "document.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.petal)
                        Text("No classes yet")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.brown)
                        Text("Create a Level I class or build a custom routine.")
                            .font(.caption)
                            .foregroundStyle(Theme.brown.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(Theme.cream)
                    .cornerRadius(12)
                } else {
                    ForEach(classStore.classes, id: \.id) { classValue in
                        NavigationLink {
                            ClassDetailView(plan: classValue)
                        } label: {
                            ClassCard(plan: classValue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $builder) { start in
            ClassBuilderView(start: start)
                .environmentObject(classStore)
                .environmentObject(libraryStore)
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
}

// WHAT: One square button on the Classes screen (icon + label).
// TO CHANGE: Size/colors: the padding and Theme values below.
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

// WHAT: One class card in the list: name, minutes, number of moves, props.
// TO CHANGE: What the card shows: edit the Chip / Text lines.
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

// WHAT: One class: name, minutes, props, the Start class button, and every move card in teaching order.
// TO CHANGE: Button text: "Start class". Note under it: the Text below the button.
struct ClassDetailView: View {
    @EnvironmentObject private var classStore: ClassStore
    @EnvironmentObject private var libraryStore: LibraryStore
    @Environment(\.dismiss) private var dismiss

    /// The class as it was when you opened it. `plan` below always reads the latest saved version.
    let opened: PilatesClass
    @State private var builder: BuilderStart?
    @State private var confirmDelete = false

    init(plan: PilatesClass) { opened = plan }

    // WHAT: the latest saved copy of this class, so edits show up right away.
    private var plan: PilatesClass {
        classStore.classes.first { $0.id == opened.id } ?? opened
    }

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

                HStack(spacing: 12) {
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
                    
                    Button(action: { builder = .edit(plan) }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(Theme.rose)
                            .font(.system(size: 24))
                    }
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
                    // Add series header if series changes
                    if index == 0 || plan.orderedItems[index - 1].series != item.series {
                        HStack(spacing: 8) {
                            Chip(text: item.series.label, tint: Theme.gold)
                            Text("series")
                                .font(.caption)
                                .foregroundStyle(Theme.brown.opacity(0.6))
                        }
                        .padding(.top, 4)
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
        .sheet(item: $builder) { start in
            ClassBuilderView(start: start)
                .environmentObject(classStore)
                .environmentObject(libraryStore)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { builder = .edit(plan) } label: { Label("Edit class", systemImage: "pencil") }
                    Button { classStore.duplicate(plan) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete class", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Delete \(plan.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete class", role: .destructive) {
                classStore.delete(plan)
                dismiss()
            }
        } message: {
            Text("It will also be removed from your watch. Built-in classes come back the next time the app opens.")
        }
    }
}

// WHAT: One move on the class screen: name, time, reps, cue, Building Block, Modification, Transition, props.
// TO CHANGE: Label names/colors: the LabeledNote lines.
private struct MoveCard: View {
    let item: PilatesClassItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    if !item.series.label.isEmpty {
                        Chip(text: item.series.label, tint: Theme.gold)
                    }
                }
                Spacer()
                Text(TimeFormat.mmss(item.seconds))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.rose)
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
            if !item.displayLayers.isEmpty {
                LabeledNote(title: "Layer up", text: item.displayLayers, icon: "plus.square.on.square", color: Theme.berry)
            }
            if let noProps = NoProps.version(of: item.name) {
                LabeledNote(title: "No props", text: "\(noProps.name): \(noProps.cue)", icon: "hand.raised.fill", color: Theme.sage)
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

// WHAT: The iPhone class timer: big ring for the current move, whole-class progress, next move, controls, 10-minutes-left banner, and the "Log this class?" prompt at the end.
// TO CHANGE: Ring size: .frame(width: 240...). Banner text: "10 minutes left". Log choices: the Button lines in .alert.
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
            controller.start { snapshot, previous in
                handleRunHaptics(snapshot: snapshot, previous: previous)
            }
            // WHAT: starting a class on the iPhone also starts it on the Apple Watch.
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

    // WHAT: vibrates the phone and shows the "10 minutes left" banner for 6 seconds.
    // TO CHANGE: the banner text is in .overlay above; the timing is ClassAlerts in Shared/LogModels.swift.
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

    private func handleRunHaptics(snapshot: TimerSnapshot, previous: TimerSnapshot?) {
        guard !snapshot.isPaused else { return }
        if previous == nil || previous?.currentIndex != snapshot.currentIndex {
            AppHaptics.runTransition()
        }
        if previous?.currentItemRemaining != 10 && snapshot.currentItemRemaining == 10 {
            AppHaptics.tenSecondWarning()
        }
    }
}

// WHAT: The round back / play-pause / next buttons on the timer.
// TO CHANGE: Sizes are set where it is used (size: 58 / 78).
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
// WHAT: Hours tab: progress toward 20 / 10 / 20 hours, the session log, and the weekly plan.
// TO CHANGE: Goals and deadline: practiceGoal ... deadline just below.
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
    // TO CHANGE: your hour goals and deadline. Also update WatchHoursGlanceView in watchOS/WatchContentView.swift.
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
// WHAT: One progress card on the Hours tab.
// TO CHANGE: Look of the card: padding/colors below.
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
// WHAT: One logged session in the Hours list.
// TO CHANGE: What it shows: the Text lines below.
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
// WHAT: Weekly plan page: weekly targets and your plan notes.
// TO CHANGE: Default plan text: the planNotes value.
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
// WHAT: Form to log or edit a session: date, type, hours, class, place, students, note.
// TO CHANGE: Default hours: hours = 0.5.
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

// MARK: - Class Builder (build and edit classes on the iPhone)

// WHAT: How a builder starts: a blank class, the Level I mat template, or an existing class to edit.
enum BuilderStart: Identifiable {
    case blank
    case levelI
    case edit(PilatesClass)

    var id: String {
        switch self {
        case .blank: "blank"
        case .levelI: "levelI"
        case .edit(let plan): "edit-\(plan.id)"
        }
    }
}

// WHAT: One move while you're building. The id lets the list drag, delete and edit the right row.
// WHAT: the mat-only version of a move (same time and section), or nil if it needs no props.
extension DraftMove {
    func withoutProps() -> DraftMove? {
        guard let version = NoProps.version(of: item.name) else { return nil }
        var copy = self
        copy.item.name = version.name
        copy.item.cue = version.cue
        copy.item.setup = ""
        copy.item.buildingBlock = version.buildingBlock
        copy.item.modification = version.modification
        copy.item.layers = version.displayLayers
        copy.item.props = []
        copy.perSide = perSide || Sidedness.isOneSided(version.name)
        return copy
    }
}

struct DraftMove: Identifiable, Equatable {
    let id = UUID()
    var item: PilatesClassItem
    /// Taught one side at a time. Saved as two timed moves: "(right)" then "(left)".
    var perSide = false
    /// How many timed blocks this move plays (2 when done right and left).
    var blocks: Int { perSide ? 2 : 1 }
}

// WHAT: The one class builder: name the class, add moves (from the Library or your own), set each move's time/reps/cues,
//       drag to reorder, swipe to delete, then Save. Saving also sends the class to your Apple Watch.
// TO CHANGE: Default time for a new move: defaultSeconds. Button text: the Label lines in "Add moves".
struct ClassBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var classStore: ClassStore
    @EnvironmentObject private var libraryStore: LibraryStore

    let start: BuilderStart

    @State private var name = ""
    @State private var extraProps = "Mat"
    @State private var sectionForNewMoves = ""
    @State private var moves: [DraftMove] = []
    @State private var editingMove: DraftMove?
    @State private var showLibraryPicker = false
    @State private var editMode: EditMode = .inactive
    @State private var loaded = false

    // TO CHANGE: starting time for each new move (seconds) and the starting class length (minutes).
    @State private var defaultSeconds = 60
    @State private var targetMinutes = 45

    private var editingClass: PilatesClass? {
        if case .edit(let plan) = start { return plan }
        return nil
    }

    private var totalSeconds: Int { moves.reduce(0) { $0 + $1.item.seconds * $1.blocks } }
    private var targetSeconds: Int { targetMinutes * 60 }
    /// e.g. "13:00 left to fill" or "2:30 over".
    private var fitText: String {
        let gap = targetSeconds - totalSeconds
        if gap == 0 { return "Exactly \(targetMinutes) min" }
        return gap > 0 ? "\(TimeFormat.mmss(gap)) left to fill" : "\(TimeFormat.mmss(-gap)) over"
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !moves.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                // --- Class name and props
                Section("Class") {
                    TextField("Class name (e.g. Tuesday Core Flow)", text: $name)
                        .font(.headline)
                    TextField("Props to bring (comma separated)", text: $extraProps)
                }

                // --- Time: how long the class is and how the moves fill it
                Section {
                    Stepper(value: $targetMinutes, in: 5...120, step: 5) {
                        HStack {
                            Text("Class length")
                            Spacer()
                            Text("\(targetMinutes) min").foregroundStyle(Theme.rose).monospacedDigit()
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(TimeFormat.mmss(totalSeconds)) planned")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Theme.berry)
                            Spacer()
                            Text(fitText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(totalSeconds > targetSeconds ? Theme.clay : Theme.sage)
                        }
                        ProgressView(value: Double(min(totalSeconds, targetSeconds)), total: Double(max(targetSeconds, 1)))
                            .tint(totalSeconds > targetSeconds ? Theme.clay : Theme.rose)
                    }
                    if !moves.isEmpty {
                        Button {
                            withAnimation { arrangeForClass() }
                        } label: {
                            Label("Arrange in class order", systemImage: "list.number")
                        }
                        .foregroundStyle(Theme.rose)
                        Button {
                            spreadEvenly()
                        } label: {
                            Label("Spread \(targetMinutes) min evenly across \(moves.count) moves", systemImage: "equal.circle")
                        }
                        .foregroundStyle(Theme.rose)
                    }
                } header: {
                    Text("Time")
                } footer: {
                    Text("Arrange in class order: warm-up stretches first, then each series together (standing, arms, core, glutes), cool-down stretches last. One-sided moves run on the right, then the same moves on the left. Every move runs on time.")
                }

                // --- The moves, in teaching order (top runs first)
                Section {
                    if moves.isEmpty {
                        Text("No moves yet. Add some below.")
                            .foregroundStyle(Theme.brown.opacity(0.6))
                    }
                    ForEach(Array(moves.enumerated()), id: \.element.id) { index, move in
                        Button {
                            editingMove = move
                        } label: {
                            BuilderMoveRow(
                                number: index + 1,
                                item: move.item,
                                perSide: move.perSide,
                                showSection: !move.item.section.isEmpty &&
                                    (index == 0 || moves[index - 1].item.section != move.item.section)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .onMove { from, to in moves.move(fromOffsets: from, toOffset: to) }
                    .onDelete { moves.remove(atOffsets: $0) }
                } header: {
                    HStack {
                        Text("Moves in teaching order")
                        Spacer()
                        if !moves.isEmpty {
                            Button(editMode == .active ? "Done" : "Reorder") {
                                withAnimation { editMode = editMode == .active ? .inactive : .active }
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.rose)
                            .textCase(nil)
                        }
                    }
                } footer: {
                    Text("Tap a move to change its time or cues. Swipe left to delete. Tap Reorder to drag moves.")
                }

                // --- Adding moves (each button is in its own row so one tap = one action)
                Section("Add moves") {
                    TextField("Section for new moves (e.g. Warm-Up)", text: $sectionForNewMoves)
                    Stepper(value: $defaultSeconds, in: 15...600, step: 15) {
                        HStack {
                            Text("Time for each new move").foregroundStyle(Theme.brown)
                            Spacer()
                            Text(TimeFormat.mmss(defaultSeconds)).monospacedDigit()
                        }
                    }
                    if !moves.isEmpty {
                        Button("Set every move to \(TimeFormat.mmss(defaultSeconds))") {
                            for i in moves.indices { moves[i].item.seconds = defaultSeconds }
                        }
                    }
                    Button {
                        showLibraryPicker = true
                    } label: {
                        Label("Add from Library", systemImage: "books.vertical")
                    }
                    Button {
                        let move = DraftMove(item: PilatesClassItem(
                            section: sectionForNewMoves.trimmingCharacters(in: .whitespaces),
                            name: "",
                            seconds: defaultSeconds,
                            modification: " "
                        ))
                        moves.append(move)
                        editingMove = move
                    } label: {
                        Label("Write my own move", systemImage: "square.and.pencil")
                    }
                    let propMoves = moves.filter { $0.withoutProps() != nil }.count
                    if propMoves > 0 {
                        Button {
                            withAnimation {
                                moves = moves.map { $0.withoutProps() ?? $0 }
                                if !moves.contains(where: { !$0.item.props.isEmpty }) { extraProps = "Mat" }
                            }
                        } label: {
                            Label("Make it prop-free (swap \(propMoves) moves)", systemImage: "hand.raised")
                        }
                    }
                }
                .foregroundStyle(Theme.rose)

                // --- Save
                Section {
                    Button(action: save) {
                        Text(editingClass == nil ? "Save class & send to watch" : "Save changes & send to watch")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(canSave ? Theme.rose : Theme.petal, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .listRowBackground(Color.clear)
                } footer: {
                    if !canSave {
                        Text("Give the class a name and at least one move to save.")
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(editingClass == nil ? "New class" : "Edit class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            // When the move editor closes, drop any "write my own" move that never got a name.
            .sheet(item: $editingMove, onDismiss: {
                moves.removeAll { $0.item.name.trimmingCharacters(in: .whitespaces).isEmpty }
            }) { move in
                MoveEditorView(move: move) { updated in
                    if let i = moves.firstIndex(where: { $0.id == updated.id }) { moves[i] = updated }
                } onDelete: {
                    moves.removeAll { $0.id == move.id }
                }
            }
            .sheet(isPresented: $showLibraryPicker) {
                LibraryPickerView(moves: libraryStore.moves) { picked in
                    let section = sectionForNewMoves.trimmingCharacters(in: .whitespaces)
                    moves += picked.map { libraryMove in
                        DraftMove(item: PilatesClassItem(
                            section: section,
                            name: libraryMove.name,
                            seconds: defaultSeconds,
                            cue: libraryMove.cue,
                            buildingBlock: libraryMove.buildingBlock,
                            modification: libraryMove.modification.isEmpty ? " " : libraryMove.modification,
                            layers: libraryMove.displayLayers,
                            props: libraryMove.props
                        ), perSide: Sidedness.isOneSided(libraryMove.name))
                    }
                }
            }
            .onAppear(perform: loadStart)
        }
        .preferredColorScheme(.light)
    }

    // WHAT: fills the builder from the starting point (blank, Level I template, or the class being edited).
    private func loadStart() {
        guard !loaded else { return }
        loaded = true
        switch start {
        case .blank:
            break
        case .levelI:
            name = "Level I Mat"
            moves = LevelIMatTemplate.exercises.map { DraftMove(item: $0, perSide: Sidedness.isOneSided($0.name)) }
        case .edit(let plan):
            name = plan.name
            targetMinutes = max(5, Int((Double(plan.totalSeconds) / 60 / 5).rounded()) * 5)
            extraProps = plan.props.joined(separator: ", ")
            // Older classes saved a section heading as a blank "Untitled Exercise" move.
            // Turn those back into section names for the moves after them, so they don't play as moves.
            var carriedSection = ""
            moves = plan.items.compactMap { item in
                let blank = item.name.trimmingCharacters(in: .whitespaces).isEmpty || item.name == "Untitled Exercise"
                if blank && item.reps.isEmpty && item.cue.isEmpty && item.buildingBlock.isEmpty {
                    carriedSection = item.section
                    return nil
                }
                var fixed = item
                if fixed.section.isEmpty && !carriedSection.isEmpty { fixed.section = carriedSection }
                return DraftMove(item: fixed)
            }
            moves = collapseSides(moves)
        }
    }

    // WHAT: puts the moves in the order you'd teach them:
    //   1 Warm-Up (breathing, warm-ups, opening stretches)  2 Standing  3 Arms  4 Classical mat (classical order)
    //   5 Core  6 Glutes  7 Cool-Down (closing stretches, thank you).
    //   Moves stay in your order inside each group; one-sided moves are kept together so you switch sides once.
    //   Each move's section becomes its group name.
    // TO CHANGE: group order: the numbers in classGroup(). Opening stretches: openers.
    private func arrangeForClass() {
        let ranked = moves.enumerated().map { (offset, draft) -> (Int, Int, Int, String, DraftMove) in
            let group = classGroup(for: draft.item.name)
            let inner = group.rank == 4 ? classicalIndex(draft.item.name) : offset
            return (group.rank, draft.perSide ? 1 : 0, inner, group.label, draft)
        }
        moves = ranked
            .sorted { ($0.0, $0.1, $0.2) < ($1.0, $1.1, $1.2) }
            .map { rank, _, _, label, draft in
                var copy = draft
                copy.item.section = label
                return copy
            }
    }

    private let openers: Set<String> = ["cat & cow", "standing roll down", "neck & shoulder release", "seated side bend", "thread the needle"]

    private func classGroup(for name: String) -> (rank: Int, label: String) {
        let key = MoveNames.key(name)
        let library = libraryStore.moves.first { MoveNames.key($0.name) == key }
            ?? LibraryMoveSet.all.first { MoveNames.key($0.name) == key }
        if key.contains("welcome") || key.contains("check-in") { return (0, "Warm-Up") }
        if key.contains("thank you") || key.contains("closing") || key.contains("gift") { return (8, "Cool-Down") }
        if key.contains("breath") || key.contains("imprint") || openers.contains(key) || library?.area == .warmup {
            return (1, "Warm-Up")
        }
        if library?.style == .classical { return (4, "Classical Mat") }
        if library?.area == .stretch || key.contains("stretch") || key.contains("child's pose") || key.contains("roll down") {
            return (7, "Cool-Down")
        }
        let standingWords = ["hinge", "squat", "lunge", "plié", "relevé", "deadlift", "skater", "curtsy", "chair pose", "standing", "walkout", "arabesque", "attitude", "balance"]
        if library?.style == .barre || library?.style == .standing || standingWords.contains(where: key.contains) {
            return (2, "Standing")
        }
        if let area = library?.area {
            switch area {
            case .arms: return (3, "Arms")
            case .core: return (5, "Core")
            case .glutes: return (6, "Glutes")
            default: break
            }
        }
        switch WorkoutSeries.infer(from: name) {
        case .lunge, .squat: return (2, "Standing")
        case .arms: return (3, "Arms")
        case .abs: return (5, "Core")
        }
    }

    /// Position of a classical move in the classical mat order (unknown moves go last, in your order).
    private func classicalIndex(_ name: String) -> Int {
        let key = MoveNames.key(name)
        let order = LibraryMoveSet.all.filter { $0.style == .classical }.map { MoveNames.key($0.name) }
        return order.firstIndex(of: key) ?? 1000
    }

    // WHAT: turns one-sided moves into timed blocks: all of a group's one-sided moves on the right, then the same moves on the left.
    //       Example: Clamshell, Side Kick → Clamshell (right), Side Kick (right), Clamshell (left), Side Kick (left).
    private func expandSides(_ drafts: [DraftMove]) -> [PilatesClassItem] {
        var result: [PilatesClassItem] = []
        var run: [DraftMove] = []
        func flush() {
            guard !run.isEmpty else { return }
            for (i, d) in run.enumerated() {
                var right = d.item
                right.name += " (right)"
                if i == run.count - 1 && right.transition.isEmpty { right.transition = "Switch to the left side." }
                result.append(right)
            }
            for d in run {
                var left = d.item
                left.name += " (left)"
                result.append(left)
            }
            run = []
        }
        for d in drafts {
            if d.perSide, run.isEmpty || run.last?.item.section == d.item.section {
                run.append(d)
            } else {
                flush()
                if d.perSide { run.append(d) } else { result.append(d.item) }
            }
        }
        flush()
        return result
    }

    // WHAT: when editing, shows "Move (right)" + "Move (left)" as one row marked R + L.
    private func collapseSides(_ drafts: [DraftMove]) -> [DraftMove] {
        var result: [DraftMove] = []
        var usedLeft = Set<Int>()
        for (i, d) in drafts.enumerated() {
            if usedLeft.contains(i) { continue }
            let name = d.item.name
            if name.hasSuffix(" (right)") {
                let base = String(name.dropLast(" (right)".count))
                if let j = drafts.indices.first(where: { $0 > i && !usedLeft.contains($0) && drafts[$0].item.name == base + " (left)" }) {
                    usedLeft.insert(j)
                    var merged = d
                    merged.item.name = base
                    if merged.item.transition == "Switch to the left side." { merged.item.transition = "" }
                    merged.perSide = true
                    result.append(merged)
                    continue
                }
            }
            result.append(d)
        }
        return result
    }

    // WHAT: gives every move the same time so the class adds up to the class length (rounded to 5 seconds).
    private func spreadEvenly() {
        guard !moves.isEmpty else { return }
        let blocks = moves.reduce(0) { $0 + $1.blocks }
        let each = max(15, Int((Double(targetSeconds) / Double(blocks) / 5).rounded()) * 5)
        for i in moves.indices { moves[i].item.seconds = each }
    }

    // WHAT: saves the class (keeping the same class when editing) and closes the builder.
    //       The class list notices the change and sends everything to the watch.
    private func save() {
        guard canSave else { return }
        let cleaned = moves.map { draft -> DraftMove in
            var copy = draft
            copy.item.name = copy.item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if copy.item.name.isEmpty { copy.item.name = "Untitled move" }
            copy.item.modification = copy.item.modification.trimmingCharacters(in: .whitespacesAndNewlines)
            return copy
        }
        let items = expandSides(cleaned)
        // Props = what you typed + every prop the moves use (no duplicates).
        var props: [String] = []
        let typed = extraProps.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for prop in typed + items.flatMap(\.props) where !prop.isEmpty {
            if !props.contains(where: { $0.lowercased() == prop.lowercased() }) { props.append(prop) }
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let plan = PilatesClass(
            version: (editingClass?.version ?? 0) + 1,
            id: editingClass?.id ?? UUID().uuidString,
            name: trimmedName,
            props: props,
            items: items
        )
        classStore.addOrReplace(plan)
        dismiss()
    }
}

// WHAT: One row in the builder: number, move name, time, reps, and a section label when a new section starts.
private struct BuilderMoveRow: View {
    let number: Int
    let item: PilatesClassItem
    var perSide = false
    let showSection: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showSection {
                Text(item.section.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.gold)
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(number)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.rose)
                    .frame(width: 22, alignment: .trailing)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name.isEmpty ? "New move" : item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.berry)
                    if !item.cue.isEmpty {
                        Text(item.cue)
                            .font(.caption)
                            .foregroundStyle(Theme.brown.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                Spacer()
                if perSide {
                    Text("R + L")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.gold.opacity(0.2), in: Capsule())
                        .foregroundStyle(Theme.brown)
                }
                Text(TimeFormat.mmss(item.seconds) + (perSide ? " each" : ""))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.rose)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.petal)
            }
        }
        .contentShape(Rectangle())
    }
}

// WHAT: Edit one move: section, name, time, reps, setup, cue, Building Block, Modification, transition, props.
// TO CHANGE: time steps: the Stepper "step:" value (15 seconds). Longest move: the "in:" range (up to 30 min).
private struct MoveEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var move: DraftMove
    let onSave: (DraftMove) -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Move") {
                    TextField("Move name", text: $move.item.name)
                        .font(.headline)
                    TextField("Section (e.g. Warm-Up, Mat flow)", text: $move.item.section)
                    Toggle("One side at a time (right, then left)", isOn: $move.perSide)
                        .tint(Theme.rose)
                    Stepper(value: $move.item.seconds, in: 0...1800, step: 15) {
                        HStack {
                            Text(move.perSide ? "Time per side" : "Time")
                            Spacer()
                            Text(TimeFormat.mmss(move.item.seconds))
                                .monospacedDigit()
                                .foregroundStyle(Theme.rose)
                        }
                    }
                    // TO CHANGE: the quick time buttons (in seconds).
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([30, 45, 60, 90, 120, 180, 300], id: \.self) { secs in
                                Button(TimeFormat.mmss(secs)) { move.item.seconds = secs }
                                    .font(.caption.weight(.semibold).monospacedDigit())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(move.item.seconds == secs ? Theme.rose : Theme.blush, in: Capsule())
                                    .foregroundStyle(move.item.seconds == secs ? .white : Theme.berry)
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Section("Coaching notes (shown on the watch)") {
                    TextField("Setup", text: $move.item.setup, axis: .vertical)
                    TextField("Cue", text: $move.item.cue, axis: .vertical)
                    TextField("Building Block", text: $move.item.buildingBlock, axis: .vertical)
                    TextField("Modification (easier version)", text: $move.item.modification, axis: .vertical)
                    TextField("Layer up (harder options, easiest first)", text: $move.item.layers, axis: .vertical)
                    TextField("Transition to next move", text: $move.item.transition, axis: .vertical)
                }
                Section("Props for this move") {
                    TextField("Comma separated (e.g. Pilates ball)", text: Binding(
                        get: { move.item.props.joined(separator: ", ") },
                        set: { move.item.props = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                }
                if let noProps = NoProps.version(of: move.item.name) {
                    Section("No props?") {
                        Button("Swap to \(noProps.name)") {
                            if let swapped = move.withoutProps() { move = swapped }
                        }
                        .foregroundStyle(Theme.rose)
                    }
                }
                Section {
                    Button("Delete this move", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
            }
            .navigationTitle(move.item.name.isEmpty ? "New move" : move.item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        move.item.props = move.item.props.filter { !$0.isEmpty }
                        onSave(move)
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

// WHAT: Pick several Library moves at once. Filter by search, style, area and prop. Moves are added in the order you tap them.
// TO CHANGE: filters: the three Menu pickers. Library moves themselves: Library tab, or moreStyles in Shared/LogModels.swift.
private struct LibraryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let moves: [LibraryMove]
    let onAdd: ([LibraryMove]) -> Void

    @State private var search = ""
    @State private var style: MoveStyle?
    @State private var area: ExerciseArea?
    @State private var prop: String?
    @State private var picked: [UUID] = []

    private var allProps: [String] {
        var seen: [String] = []
        for p in moves.flatMap(\.props) where !seen.contains(where: { $0.lowercased() == p.lowercased() }) {
            seen.append(p)
        }
        return seen.sorted { $0.lowercased() < $1.lowercased() }
    }

    private var filtered: [LibraryMove] {
        moves.filter { move in
            (search.isEmpty || move.name.localizedCaseInsensitiveContains(search)) &&
            (style == nil || move.style == style) &&
            (area == nil || move.area == area) &&
            (prop == nil || (prop == "No props" ? move.props.isEmpty : move.props.contains { $0.lowercased() == prop!.lowercased() }))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Menu {
                                Button("All styles") { style = nil }
                                ForEach(MoveStyle.allCases, id: \.self) { s in Button(s.label) { style = s } }
                            } label: { filterLabel(style?.label ?? "Style", active: style != nil) }
                            Menu {
                                Button("All areas") { area = nil }
                                ForEach(ExerciseArea.allCases, id: \.self) { a in Button(a.label) { area = a } }
                            } label: { filterLabel(area?.label ?? "Area", active: area != nil) }
                            Menu {
                                Button("Any props") { prop = nil }
                                Button("No props") { prop = "No props" }
                                ForEach(allProps, id: \.self) { p in Button(p) { prop = p } }
                            } label: { filterLabel(prop ?? "Props", active: prop != nil) }
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("\(filtered.count) moves") {
                    if filtered.isEmpty {
                        Text("No moves match. Try clearing a filter.")
                            .foregroundStyle(Theme.brown.opacity(0.6))
                    }
                    ForEach(filtered) { move in
                        Button {
                            if let i = picked.firstIndex(of: move.id) { picked.remove(at: i) } else { picked.append(move.id) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(move.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.berry)
                                    Text([move.style?.label ?? "My move", move.area.label, move.props.joined(separator: ", ")]
                                        .filter { !$0.isEmpty }.joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundStyle(Theme.brown.opacity(0.7))
                                }
                                Spacer()
                                if let n = picked.firstIndex(of: move.id) {
                                    Text("\(n + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Theme.rose, in: Circle())
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(Theme.petal)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $search, prompt: "Search moves")
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Add from Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(picked.isEmpty ? "Add" : "Add \(picked.count)") {
                        let byId = Dictionary(moves.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
                        onAdd(picked.compactMap { byId[$0] })
                        dismiss()
                    }
                    .disabled(picked.isEmpty)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func filterLabel(_ text: String, active: Bool) -> some View {
        HStack(spacing: 4) {
            Text(text)
            Image(systemName: "chevron.down").font(.caption2)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(active ? Theme.rose : Color.white, in: Capsule())
        .foregroundStyle(active ? .white : Theme.berry)
    }
}

// MARK: - Library Tab


/// Main Library tab showing:
/// - Search for exercise moves
/// - Filter by area (warm-up, arms, glutes, core, stretch) and props
/// - Move detail with cue, Building Block, Modification
/// - Add custom moves
// WHAT: Library tab: search moves and filter by Style, Area and Props.
// TO CHANGE: Add filter options: copy one of the chip rows. Styles: MoveStyle in Shared/LogModels.swift.
struct LibraryView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    
    @State private var searchText = ""
    @State private var selectedAreas: Set<ExerciseArea> = []
    @State private var selectedProps: Set<String> = []
    @State private var selectedStyles: Set<MoveStyle> = []
    @State private var showAddForm = false
    
    private var filteredMoves: [LibraryMove] {
        var result = libraryStore.moves
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        
        // Filter by style
        if !selectedStyles.isEmpty {
            result = result.filter { move in
                guard let style = move.style else { return false }
                return selectedStyles.contains(style)
            }
        }

        // Filter by area
        if !selectedAreas.isEmpty {
            result = result.filter { selectedAreas.contains($0.area) }
        }
        
        // Filter by props
        // "No props" shows mat-only moves.
        if !selectedProps.isEmpty {
            let realProps = selectedProps.subtracting(["No props"])
            result = result.filter { move in
                (!selectedProps.contains("No props") || move.props.isEmpty) &&
                realProps.allSatisfy { prop in move.props.contains(prop) }
            }
        }
        
        return result.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    private var allProps: [String] {
        ["No props"] + Array(Set(libraryStore.moves.flatMap { $0.props })).sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("LIBRARY")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(Theme.gold)
                Text("Your exercise reference")
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
                TextField("Search moves", text: $searchText)
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
            
            // Filters
            VStack(alignment: .leading, spacing: 12) {
                // Style filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("STYLE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.gold)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MoveStyle.allCases, id: \.self) { style in
                                Button(action: {
                                    if selectedStyles.contains(style) {
                                        selectedStyles.remove(style)
                                    } else {
                                        selectedStyles.insert(style)
                                    }
                                }) {
                                    Text(style.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(selectedStyles.contains(style) ? .white : Theme.brown)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedStyles.contains(style) ? Theme.gold : Color.white)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedStyles.contains(style) ? Color.clear : Theme.gold.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                // Area filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("AREA")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.gold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ExerciseArea.allCases, id: \.self) { area in
                                Button(action: { 
                                    if selectedAreas.contains(area) {
                                        selectedAreas.remove(area)
                                    } else {
                                        selectedAreas.insert(area)
                                    }
                                }) {
                                    Text(area.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(selectedAreas.contains(area) ? .white : Theme.berry)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedAreas.contains(area) ? Theme.rose : Color.white)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedAreas.contains(area) ? Color.clear : Theme.petal.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Prop filter
                if !allProps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PROPS")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.gold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allProps, id: \.self) { prop in
                                    Button(action: { 
                                        if selectedProps.contains(prop) {
                                            selectedProps.remove(prop)
                                        } else {
                                            selectedProps.insert(prop)
                                        }
                                    }) {
                                        Text(prop)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(selectedProps.contains(prop) ? .white : Theme.sage)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedProps.contains(prop) ? Theme.sage : Color.white)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(selectedProps.contains(prop) ? Color.clear : Theme.sage.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            
            // Move list
            if filteredMoves.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.petal)
                    Text(searchText.isEmpty && selectedAreas.isEmpty && selectedProps.isEmpty && selectedStyles.isEmpty ? "No moves yet" : "No matching moves")
                        .font(.headline)
                        .foregroundStyle(Theme.brown)
                    Button(action: { showAddForm = true }) {
                        Text("Add your first move")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.rose)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredMoves, id: \.id) { move in
                            NavigationLink(destination: MoveDetailView(move: move)) {
                                MoveRowView(move: move)
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
            MoveFormView(libraryStore: libraryStore, editingMove: nil)
        }
    }
}

// MARK: - Move Row View
// WHAT: One move in the Library list.
// TO CHANGE: What it shows: the Text lines below.
private struct MoveRowView: View {
    let move: LibraryMove
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(move.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.berry)
                    
                    HStack(spacing: 8) {
                        Chip(text: move.area.label, tint: Theme.gold)
                        
                        if !move.props.isEmpty {
                            Text(move.props.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(Theme.sage)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        if move.seconds > 0 {
                            Label(TimeFormat.mmss(move.seconds), systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(Theme.brown.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.petal)
                    .font(.caption.weight(.semibold))
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

// MARK: - Move Detail View
// WHAT: Full details for one Library move, with an Edit button.
private struct MoveDetailView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    
    let move: LibraryMove
    @State private var editingMove: LibraryMove?
    @State private var showEditForm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(move.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.berry)
                    
                    HStack(spacing: 8) {
                        Chip(text: move.area.label, tint: Theme.gold)
                        
                        if !move.props.isEmpty {
                            ForEach(move.props, id: \.self) { prop in
                                Chip(text: prop, tint: Theme.sage)
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        if move.seconds > 0 {
                            VStack(spacing: 4) {
                                Label("Time", systemImage: "clock")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Theme.rose)
                                Text("\(move.seconds)s")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Theme.brown)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Theme.rose.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                
                // Cue
                VStack(alignment: .leading, spacing: 8) {
                    Label("Cue", systemImage: "speaker.wave.2")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.berry)
                    Text(move.cue)
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                
                // Building Block
                VStack(alignment: .leading, spacing: 8) {
                    Label("Building Block", systemImage: "building.2")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.berry)
                    Text(move.buildingBlock)
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                
                // Modification
                VStack(alignment: .leading, spacing: 8) {
                    Label("Modification", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.berry)
                    Text(move.modification)
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)

                // Without props
                if let noProps = NoProps.version(of: move.name) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Without props: \(noProps.name)", systemImage: "hand.raised.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.berry)
                        Text(noProps.cue)
                            .font(.subheadline)
                            .foregroundStyle(Theme.brown)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                }

                // Layer up (harder options)
                if !move.displayLayers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Layer up", systemImage: "plus.square.on.square")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.berry)
                        Text(move.displayLayers)
                            .font(.subheadline)
                            .foregroundStyle(Theme.brown)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { showEditForm = true }) {
                        Label("Edit", systemImage: "pencil")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.rose)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Theme.rose.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(role: .destructive, action: { libraryStore.delete(move) }) {
                        Label("Delete", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(move.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditForm) {
            MoveFormView(libraryStore: libraryStore, editingMove: move)
        }
    }
}

// MARK: - Move Form View
// WHAT: Form to add or edit a Library move.
// TO CHANGE: Prop choices: the props list near the top.
private struct MoveFormView: View {
    @Environment(\.dismiss) var dismiss
    let libraryStore: LibraryStore
    let editingMove: LibraryMove?
    
    @State private var name = ""
    @State private var selectedArea = ExerciseArea.warmup
    @State private var selectedProps: Set<String> = []
    @State private var reps = ""
    @State private var seconds = ""
    @State private var cue = ""
    @State private var buildingBlock = ""
    @State private var modification = ""
    @State private var layers = ""
    
    // Common props to suggest
    // TO CHANGE: prop choices in this builder. (Library moves use "Stretch band", "Yoga block", "Pilates ball"; match the spelling if you want filters to line up.)
    private let commonProps = ["Resistance Band", "Dumbbells", "Wrist Weights", "Thigh Band", "Yoga Block", "Pilates Ball", "Magic Circle"]
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !cue.trimmingCharacters(in: .whitespaces).isEmpty &&
        !buildingBlock.trimmingCharacters(in: .whitespaces).isEmpty &&
        !modification.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Move Name") {
                    TextField("Name", text: $name)
                }
                
                Section("Area") {
                    Picker("Area", selection: $selectedArea) {
                        ForEach(ExerciseArea.allCases, id: \.self) { area in
                            Text(area.label).tag(area)
                        }
                    }
                }
                
                // TO CHANGE: time steps (15 seconds) and longest time (30 min = 1800).
                Section("Time") {
                    Stepper(value: Binding(get: { Int(seconds) ?? 0 }, set: { seconds = "\($0)" }), in: 0...1800, step: 15) {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(TimeFormat.mmss(Int(seconds) ?? 0))
                                .monospacedDigit()
                                .foregroundStyle(Theme.rose)
                        }
                    }
                }
                
                Section("Props") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(commonProps, id: \.self) { prop in
                            HStack {
                                Text(prop)
                                Spacer()
                                if selectedProps.contains(prop) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.rose)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedProps.contains(prop) {
                                    selectedProps.remove(prop)
                                } else {
                                    selectedProps.insert(prop)
                                }
                            }
                        }
                    }
                }
                
                Section("Cue (what to say)") {
                    TextEditor(text: $cue)
                        .frame(height: 80)
                }
                
                Section("Building Block (progression)") {
                    TextEditor(text: $buildingBlock)
                        .frame(height: 80)
                }
                
                Section("Modification (easier version)") {
                    TextEditor(text: $modification)
                        .frame(height: 80)
                }

                Section("Layer up (harder options, easiest first)") {
                    TextField("e.g. Pulse at the top → add a band → single leg", text: $layers, axis: .vertical)
                }
                
                Section {
                    Button(action: saveMove) {
                        Text(editingMove == nil ? "Add Move" : "Save Changes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(isValid ? Theme.rose : Theme.petal)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid)
                }
            }
            .navigationTitle(editingMove == nil ? "Add Move" : "Edit Move")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.rose)
                }
            }
            .preferredColorScheme(.light)
            .onAppear {
                if let move = editingMove {
                    name = move.name
                    selectedArea = move.area
                    selectedProps = Set(move.props)
                    reps = move.reps
                    seconds = move.seconds > 0 ? "\(move.seconds)" : ""
                    cue = move.cue
                    buildingBlock = move.buildingBlock
                    modification = move.modification
                    layers = move.displayLayers
                }
            }
        }
    }
    
    private func saveMove() {
        let move = LibraryMove(
            id: editingMove?.id ?? UUID(),
            name: name,
            area: selectedArea,
            props: Array(selectedProps).sorted(),
            reps: reps,
            seconds: Int(seconds) ?? 0,
            cue: cue,
            buildingBlock: buildingBlock,
            modification: modification,
            style: editingMove?.style,
            layers: layers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : layers
        )
        libraryStore.addOrReplace(move)
        dismiss()
    }
}

// MARK: - Students Tab


/// Main Students tab showing:
/// - List of students with name, contact, injuries
/// - Add button to create new student
/// - Search and sort
/// - Student detail view with teaching history
// WHAT: Students tab: list of students and the add button.
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
// WHAT: One student in the list.
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
// WHAT: One student: their info, teaching sessions with them, and total hours together.
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
// WHAT: Form to add or edit a student (name, contact, injuries, goals, notes).
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

// MARK: - Exam Prep

// WHAT: Exam Prep home: summary + links to five preparation sections.
struct ExamPrepHomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXAM PREP")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(Theme.gold)
                    Text("Peak Pilates Level I")
                        .font(Theme.display(30))
                        .foregroundStyle(Theme.berry)
                    Text("Theory + practical preparation in one place.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown.opacity(0.8))
                }
                .padding(.top, 8)

                ExamPrepSummaryCard()

                VStack(spacing: 10) {
                    ExamPrepLinkRow(title: "1) Mat Order Drill", subtitle: "Level I Mat (35): sequence, transitions, and recall") {
                        MatOrderDrillView()
                    }
                    ExamPrepLinkRow(title: "2) Technique Self-Check", subtitle: "Run-through, timer, and point-losing reminders") {
                        TechniqueSelfCheckView()
                    }
                    ExamPrepLinkRow(title: "3) Teaching Practice", subtitle: "Segment assignment, cue cards, timer, and rubric") {
                        TeachingPracticeView()
                    }
                    ExamPrepLinkRow(title: "4) Theory Quiz", subtitle: "Shuffled rounds with explanations + missed pile") {
                        TheoryQuizView()
                    }
                    ExamPrepLinkRow(title: "5) Exam Checklist", subtitle: "Final readiness tick-off list") {
                        ExamChecklistView()
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Exam Prep")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ExamPrepLinkRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.berry)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.brown.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.petal, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// WHAT: Compact summary card used on Classes screen and Exam Prep home.
private struct ExamPrepSummaryCard: View {
    @EnvironmentObject private var examPrepStore: ExamPrepStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Exam Prep summary")
                    .font(.headline)
                    .foregroundStyle(Theme.berry)
                Spacer()
                Text("Tap to practice")
                    .font(.caption)
                    .foregroundStyle(Theme.sage)
            }

            summaryRow("Order drill accuracy", "\(examPrepStore.state.orderDrillAccuracy)%")
            summaryRow("Last technique run", examPrepStore.lastTechniqueSummary)
            summaryRow("Last teaching score", examPrepStore.lastTeachingSummary)
            summaryRow("Best theory quiz score", "\(examPrepStore.state.bestTheoryQuizScore)%")
        }
        .padding(14)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.petal, lineWidth: 1))
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.brown)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.rose)
        }
    }
}

struct MatOrderDrillView: View {
    @EnvironmentObject private var examPrepStore: ExamPrepStore
    @State private var mode: ExamPrepMatMode = .whatComesNext

    @State private var currentPromptIndex = 0
    @State private var nextOptions: [Int] = []
    @State private var nextFeedback = ""

    @State private var chunkOrder: [Int] = []
    @State private var chunkFeedback = ""
    @State private var draggedChunkItem: Int?

    @State private var fullRecallInput = ""
    @State private var fullRecallReport: ExamPrepFullRecallReport?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Mode", selection: $mode) {
                    ForEach(ExamPrepMatMode.allCases, id: \.self) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                .pickerStyle(.segmented)

                switch mode {
                case .whatComesNext:
                    whatComesNextCard
                case .putInOrder:
                    putInOrderCard
                case .fullRecall:
                    fullRecallCard
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Most-missed spots")
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    if examPrepStore.topMissedSteps(limit: 5).isEmpty {
                        Text("No misses tracked yet.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.brown.opacity(0.8))
                    } else {
                        ForEach(examPrepStore.topMissedSteps(limit: 5), id: \.index) { item in
                            Text("Step \(item.index + 1): \(ExamPrepData.levelIMat35[item.index]) — \(item.count) misses")
                                .font(.subheadline)
                                .foregroundStyle(Theme.brown)
                        }
                    }
                }
                .padding(14)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Level I Mat (35)")
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    ForEach(Array(ExamPrepData.levelIMat35.enumerated()), id: \.offset) { index, name in
                        Text("\(index + 1). \(name)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.brown)
                    }
                }
                .padding(14)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Mat Order Drill")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if nextOptions.isEmpty { loadWhatComesNextPrompt() }
            if chunkOrder.isEmpty { loadChunk() }
        }
    }

    private var whatComesNextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What comes next?")
                .font(.headline)
                .foregroundStyle(Theme.berry)
            Text("Current: \(ExamPrepData.levelIMat35[currentPromptIndex])")
                .font(.subheadline)
                .foregroundStyle(Theme.brown)

            ForEach(nextOptions, id: \.self) { option in
                Button {
                    let expected = currentPromptIndex + 1
                    let isCorrect = option == expected
                    examPrepStore.recordWhatComesNext(expectedNextIndex: expected, wasCorrect: isCorrect)
                    nextFeedback = isCorrect ? "Correct." : "Not quite. Next is \(expected + 1). \(ExamPrepData.levelIMat35[expected])"
                    if isCorrect {
                        AppHaptics.success()
                    } else {
                        AppHaptics.warning()
                    }
                } label: {
                    Text("\(option + 1). \(ExamPrepData.levelIMat35[option])")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            if !nextFeedback.isEmpty {
                Text(nextFeedback)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(nextFeedback.hasPrefix("Correct") ? Theme.sage : Theme.clay)
            }

            Button("Next prompt") {
                loadWhatComesNextPrompt()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.rose, in: Capsule())
        }
        .padding(14)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
    }

    private var putInOrderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Put in order")
                .font(.headline)
                .foregroundStyle(Theme.berry)
            Text("Drag to reorder this shuffled consecutive chunk.")
                .font(.subheadline)
                .foregroundStyle(Theme.brown.opacity(0.8))

            VStack(spacing: 8) {
                ForEach(chunkOrder, id: \.self) { index in
                    ExamPrepDraggableChunkRow(index: index, isActive: draggedChunkItem == index)
                        .onDrag {
                            draggedChunkItem = index
                            return NSItemProvider(object: "\(index)" as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: ExamPrepChunkDropDelegate(
                                chunkOrder: $chunkOrder,
                                draggedItem: $draggedChunkItem,
                                targetItem: index
                            )
                        )
                }
            }

            HStack {
                Button("Check order") {
                    let expected = chunkOrder.sorted()
                    let isCorrect = chunkOrder == expected
                    examPrepStore.recordChunkResult(expected: expected, actual: chunkOrder)
                    chunkFeedback = isCorrect ? "Correct order." : "Some are out of order."
                    if isCorrect {
                        AppHaptics.success()
                    } else {
                        AppHaptics.warning()
                    }
                }
                .font(.subheadline.weight(.semibold))
                Spacer()
                Button("New chunk") {
                    loadChunk()
                }
                .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Theme.rose)

            if !chunkFeedback.isEmpty {
                Text(chunkFeedback)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(chunkFeedback.hasPrefix("Correct") ? Theme.sage : Theme.clay)
            }
        }
        .padding(14)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
    }

    private var fullRecallCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Full recall")
                .font(.headline)
                .foregroundStyle(Theme.berry)
            Text("Type the full Level I Mat (35) order from memory, one step per line.")
                .font(.subheadline)
                .foregroundStyle(Theme.brown.opacity(0.8))

            TextEditor(text: $fullRecallInput)
                .frame(minHeight: 220)
                .padding(8)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.petal, lineWidth: 1))

            HStack {
                Button("Check recall") {
                    fullRecallReport = buildExamPrepFullRecallReport(input: fullRecallInput)
                    if let report = fullRecallReport {
                        examPrepStore.recordFullRecallMismatches(report.mismatchIndices)
                    }
                }
                .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Clear") {
                    fullRecallInput = ""
                    fullRecallReport = nil
                }
                .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Theme.rose)

            if let report = fullRecallReport {
                Text("Accuracy: \(report.accuracy)%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.berry)
                if report.details.isEmpty {
                    Text("Perfect recall.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.sage)
                } else {
                    ForEach(Array(report.details.enumerated()), id: \.offset) { _, detail in
                        Text(detail)
                            .font(.footnote)
                            .foregroundStyle(Theme.brown)
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
    }

    private func loadWhatComesNextPrompt() {
        currentPromptIndex = examPrepStore.weightedPromptIndex(maxIndex: ExamPrepData.levelIMat35.count - 2)
        let expected = currentPromptIndex + 1
        var candidates: Set<Int> = [expected]
        while candidates.count < 4 {
            candidates.insert(Int.random(in: 1..<ExamPrepData.levelIMat35.count))
        }
        nextOptions = Array(candidates).shuffled()
        nextFeedback = ""
    }

    private func loadChunk() {
        let length = Int.random(in: 4...8)
        let start = examPrepStore.weightedChunkStart(chunkLength: length, totalCount: ExamPrepData.levelIMat35.count)
        let chunk = Array(start..<(start + length))
        chunkOrder = chunk.shuffled()
        draggedChunkItem = nil
        chunkFeedback = ""
    }
}

private struct ExamPrepDraggableChunkRow: View {
    let index: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(Theme.sage)
            Text("\(index + 1). \(ExamPrepData.levelIMat35[index])")
                .font(.subheadline)
                .foregroundStyle(Theme.brown)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Theme.petal.opacity(0.35) : Theme.background)
        )
    }
}

private struct ExamPrepChunkDropDelegate: DropDelegate {
    @Binding var chunkOrder: [Int]
    @Binding var draggedItem: Int?
    let targetItem: Int

    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              draggedItem != targetItem,
              let fromIndex = chunkOrder.firstIndex(of: draggedItem),
              let toIndex = chunkOrder.firstIndex(of: targetItem) else { return }

        withAnimation {
            chunkOrder.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
        AppHaptics.dragStep()
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        AppHaptics.drop()
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

struct TechniqueSelfCheckView: View {
    @EnvironmentObject private var examPrepStore: ExamPrepStore
    @State private var currentIndex = 0
    @State private var timerEnabled = false
    @State private var timerRunning = false
    @State private var elapsedSeconds = 0
    @State private var runStartedAt: Date?

    @State private var checklistSetup = false
    @State private var checklistTransition = false
    @State private var checklistReps = false
    @State private var checklistPrinciples = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                examPrepInfoCard(lines: [
                    "Passing: 93% (112 of 120), scored as a whole; if failed, all technique is repeated.",
                    "Perform every Level I exercise, 3 reps each, with correct transitions, from memory, and with no name prompts.",
                    "Add-In exercises are not assessed.",
                    "Building Blocks are allowed only if they meet the exercise goal, make sense for the body, and are pre-approved by the assessing Master Instructor."
                ])

                VStack(alignment: .leading, spacing: 10) {
                    Text("Run-through mode")
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    Text("Step \(currentIndex + 1) of \(ExamPrepData.levelIMat35.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.rose)
                    Text(ExamPrepData.levelIMat35[currentIndex])
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.brown)

                    Toggle("Use timer", isOn: $timerEnabled)
                        .tint(Theme.rose)
                    if timerEnabled {
                        HStack {
                            Text("Elapsed")
                            Spacer()
                            Text(TimeFormat.mmss(elapsedSeconds))
                                .monospacedDigit()
                        }
                        Button(timerRunning ? "Pause timer" : "Start timer") {
                            timerRunning.toggle()
                            if timerRunning, runStartedAt == nil { runStartedAt = Date() }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.rose)
                    }

                    Toggle("Correct setup / starting position", isOn: $checklistSetup).tint(Theme.rose)
                    Toggle("Correct order and transition in", isOn: $checklistTransition).tint(Theme.rose)
                    Toggle("3 controlled reps, no momentum or hoisting", isOn: $checklistReps).tint(Theme.rose)
                    Toggle("Box, Centerline, Frame and Powerhouse applied", isOn: $checklistPrinciples).tint(Theme.rose)

                    HStack {
                        Button("Back") {
                            guard currentIndex > 0 else { return }
                            currentIndex -= 1
                            resetChecklist()
                        }
                        Spacer()
                        Button("Next") {
                            guard currentIndex < ExamPrepData.levelIMat35.count - 1 else { return }
                            if runStartedAt == nil { runStartedAt = Date() }
                            currentIndex += 1
                            resetChecklist()
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.rose)

                    Button("Finish run-through") {
                        timerRunning = false
                        let elapsed = timerEnabled ? elapsedSeconds : Int(Date().timeIntervalSince(runStartedAt ?? Date()))
                        examPrepStore.recordTechniqueRun(
                            completedSteps: currentIndex + 1,
                            totalSteps: ExamPrepData.levelIMat35.count,
                            elapsedSeconds: max(elapsed, 0)
                        )
                        AppHaptics.success()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.rose, in: Capsule())
                }
                .padding(14)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Point-losing reminders for this step")
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    ForEach(TechniqueErrorCatalog.errors(for: ExamPrepData.levelIMat35[currentIndex]), id: \.self) { item in
                        Text("• \(item)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.brown)
                    }
                }
                .padding(14)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Technique Self-Check")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(tick) { _ in
            if timerEnabled && timerRunning { elapsedSeconds += 1 }
        }
    }

    private func resetChecklist() {
        checklistSetup = false
        checklistTransition = false
        checklistReps = false
        checklistPrinciples = false
    }
}

struct TeachingPracticeView: View {
    @EnvironmentObject private var examPrepStore: ExamPrepStore
    @State private var segmentIndices: [Int] = []
    @State private var cardPosition = 0
    @State private var timerSeconds = 900
    @State private var timerRunning = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var rubricValues = Array(repeating: true, count: 13)
    @State private var saveStatus = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                examPrepInfoCard(lines: [
                    "Passing: 13/13.",
                    "Teach 15 minutes of a Level I group mat class to at least 3 students.",
                    "Leaving out, forgetting, or misplacing an exercise in your segment is an automatic fail.",
                    "Readiness target: keeps the group together and moving safely."
                ])

                VStack(alignment: .leading, spacing: 10) {
                    Text("Assigned segment")
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    Button("Assign my segment") {
                        assignSegment()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.rose, in: Capsule())
                    if segmentIndices.isEmpty {
                        Text("No segment assigned yet.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.brown.opacity(0.8))
                    } else {
                        ForEach(Array(segmentIndices.enumerated()), id: \.offset) { offset, index in
                            Text("\(offset + 1). \(ExamPrepData.levelIMat35[index])")
                                .font(.subheadline)
                                .foregroundStyle(Theme.brown)
                        }
                    }
                }
                .padding(14)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 10) {
                    Text("15-minute timer")
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    Text(TimeFormat.mmss(timerSeconds))
                        .font(.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.rose)
                    HStack {
                        Button(timerRunning ? "Pause" : "Start") {
                            timerRunning.toggle()
                        }
                        Spacer()
                        Button("Reset") {
                            timerRunning = false
                            timerSeconds = 900
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.rose)
                }
                .padding(14)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))

                if !segmentIndices.isEmpty {
                    let currentIndex = segmentIndices[cardPosition]
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cue card")
                            .font(.headline)
                            .foregroundStyle(Theme.berry)
                        cueLine("Exercise name", ExamPrepData.levelIMat35[currentIndex])
                        cueLine("Transition", TeachingCueCatalog.transition(for: currentIndex))
                        cueLine("Setup", "Use your prepared setup cue for this exercise.")
                        cueLine("Execution", "Use your prepared execution cue for this exercise.")
                        cueLine("Powerhouse cue", "Add one specific Powerhouse cue for this exercise.")
                        HStack {
                            Button("Previous card") {
                                guard cardPosition > 0 else { return }
                                cardPosition -= 1
                            }
                            Spacer()
                            Button("Next card") {
                                guard cardPosition < segmentIndices.count - 1 else { return }
                                cardPosition += 1
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.rose)
                    }
                    .padding(14)
                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
                }

                examPrepInfoCard(lines: [
                    "Use less setup and transition cueing for familiar introductory exercises, and more for harder ones, with economy of words.",
                    "Use Building Block progressions, fold in Fundamentals where appropriate, and use Add-In and preparatory exercises.",
                    "Assessment emphasis: 5-Part Formula for Success with layering cues."
                ])

                VStack(alignment: .leading, spacing: 8) {
                    Text("13-point rubric (1 = ready, 0 = not ready)")
                        .font(.headline)
                        .foregroundStyle(Theme.berry)
                    ForEach(Array(TeachingRubric.items.enumerated()), id: \.offset) { idx, label in
                        Toggle(label, isOn: $rubricValues[idx])
                            .tint(Theme.rose)
                    }
                    Button("Save practice score") {
                        let score = rubricValues.filter { $0 }.count
                        examPrepStore.recordTeachingPractice(segmentIndices: segmentIndices, score: score)
                        saveStatus = "Saved \(score)/13."
                        AppHaptics.success()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.rose, in: Capsule())
                    if !saveStatus.isEmpty {
                        Text(saveStatus)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.sage)
                    }
                }
                .padding(14)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Teaching Practice")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(tick) { _ in
            if timerRunning && timerSeconds > 0 {
                timerSeconds -= 1
                if timerSeconds == 0 {
                    AppHaptics.warning()
                }
            }
        }
    }

    private func assignSegment() {
        let count = Int.random(in: 6...9)
        let start = Int.random(in: 0...(ExamPrepData.levelIMat35.count - count))
        segmentIndices = Array(start..<(start + count))
        cardPosition = 0
        saveStatus = ""
    }

    private func cueLine(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.sage)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.brown)
        }
    }
}

struct TheoryQuizView: View {
    @EnvironmentObject private var examPrepStore: ExamPrepStore
    @State private var roundQuestions: [TheoryQuestion] = []
    @State private var currentQuestion = 0
    @State private var selectedOption: Int?
    @State private var roundScore = 0
    @State private var roundMissed: [String] = []
    @State private var roundScoreSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if roundQuestions.isEmpty {
                    VStack(spacing: 10) {
                        Button("Start shuffled round") {
                            startRound(missedOnly: false)
                        }
                        .examPrimaryButton()
                        Button("Retry missed pile (\(examPrepStore.state.missedQuestionIDs.count))") {
                            startRound(missedOnly: true)
                        }
                        .examSecondaryButton(disabled: examPrepStore.state.missedQuestionIDs.isEmpty)
                        .disabled(examPrepStore.state.missedQuestionIDs.isEmpty)
                    }
                    .padding(14)
                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
                } else if currentQuestion < roundQuestions.count {
                    let question = roundQuestions[currentQuestion]
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Question \(currentQuestion + 1) of \(roundQuestions.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.rose)
                        Text(question.prompt)
                            .font(.headline)
                            .foregroundStyle(Theme.berry)

                        ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                            Button {
                                guard selectedOption == nil else { return }
                                selectedOption = idx
                                let correct = idx == question.correctIndex
                                if correct {
                                    roundScore += 1
                                    examPrepStore.resolveMissedQuestion(id: question.id)
                                    AppHaptics.success()
                                } else {
                                    roundMissed.append(question.id)
                                    examPrepStore.markMissedQuestion(id: question.id)
                                    AppHaptics.warning()
                                }
                            } label: {
                                Text(option)
                                    .font(.subheadline)
                                    .foregroundStyle(answerColor(for: idx, question: question))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }

                        if let selectedOption {
                            let isCorrect = selectedOption == question.correctIndex
                            Text(isCorrect ? "Correct." : "Incorrect.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isCorrect ? Theme.sage : Theme.clay)
                            Text("Right answer: \(question.options[question.correctIndex])")
                                .font(.subheadline)
                            Text(question.explanation)
                                .font(.footnote)
                                .foregroundStyle(Theme.brown.opacity(0.8))
                            Button("Next question") {
                                self.selectedOption = nil
                                currentQuestion += 1
                            }
                            .examPrimaryButton()
                        }
                    }
                    .padding(14)
                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    let percent = Int((Double(roundScore) / Double(max(roundQuestions.count, 1)) * 100.0).rounded())
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Round complete")
                            .font(.headline)
                            .foregroundStyle(Theme.berry)
                        Text("Score: \(roundScore)/\(roundQuestions.count) (\(percent)%)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.rose)
                        if !roundScoreSaved {
                            Color.clear
                                .frame(height: 0)
                                .onAppear {
                                    roundScoreSaved = true
                                    examPrepStore.recordTheoryQuizScore(percent)
                                }
                        }
                        Button("Start new shuffled round") {
                            startRound(missedOnly: false)
                        }
                        .examPrimaryButton()
                        Button("Retry missed from this round (\(roundMissed.count))") {
                            startRoundFrom(ids: roundMissed)
                        }
                        .examSecondaryButton(disabled: roundMissed.isEmpty)
                        .disabled(roundMissed.isEmpty)
                    }
                    .padding(14)
                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Theory Quiz")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startRound(missedOnly: Bool) {
        if missedOnly {
            startRoundFrom(ids: examPrepStore.state.missedQuestionIDs)
            return
        }
        roundQuestions = ExamPrepData.theoryQuestions.shuffled()
        resetRound()
    }

    private func startRoundFrom(ids: [String]) {
        let set = Set(ids)
        roundQuestions = ExamPrepData.theoryQuestions.filter { set.contains($0.id) }.shuffled()
        resetRound()
    }

    private func resetRound() {
        currentQuestion = 0
        selectedOption = nil
        roundScore = 0
        roundMissed = []
        roundScoreSaved = false
        if roundQuestions.isEmpty {
            roundQuestions = ExamPrepData.theoryQuestions.shuffled()
        }
    }

    private func answerColor(for index: Int, question: TheoryQuestion) -> Color {
        guard let selectedOption else { return Theme.brown }
        if index == question.correctIndex { return Theme.sage }
        if index == selectedOption && selectedOption != question.correctIndex { return Theme.clay }
        return Theme.brown.opacity(0.7)
    }
}

struct ExamChecklistView: View {
    @EnvironmentObject private var examPrepStore: ExamPrepStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(ExamChecklistItem.items) { item in
                    Toggle(item.text, isOn: binding(for: item.id))
                        .tint(Theme.rose)
                        .padding(12)
                        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Exam Checklist")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { examPrepStore.state.checklist[id] ?? false },
            set: { newValue in
                examPrepStore.state.checklist[id] = newValue
                examPrepStore.save()
            }
        )
    }
}

private func examPrepInfoCard(lines: [String]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(lines, id: \.self) { line in
            Text("• \(line)")
                .font(.subheadline)
                .foregroundStyle(Theme.brown)
        }
    }
    .padding(14)
    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16))
}

private extension View {
    func examPrimaryButton() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.rose, in: Capsule())
    }

    func examSecondaryButton(disabled: Bool) -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(disabled ? Theme.brown.opacity(0.5) : Theme.rose)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.background, in: Capsule())
            .overlay(Capsule().stroke(Theme.petal, lineWidth: 1))
    }
}

private enum ExamPrepMatMode: String, CaseIterable {
    case whatComesNext = "What comes next?"
    case putInOrder = "Put in order"
    case fullRecall = "Full recall"
}

private struct ExamPrepFullRecallReport {
    let accuracy: Int
    let mismatchIndices: [Int]
    let details: [String]
}

@MainActor
final class ExamPrepStore: ObservableObject {
    @Published var state = ExamPrepState()

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "exam-prep.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode(ExamPrepState.self, from: data) else {
            state = ExamPrepState()
            save()
            return
        }
        state = decoded
    }

    func save() {
        do {
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save exam prep data: \(error)")
        }
    }

    func recordWhatComesNext(expectedNextIndex: Int, wasCorrect: Bool) {
        state.orderDrillAttempts += 1
        if wasCorrect {
            state.orderDrillCorrect += 1
        } else {
            state.missCounts[expectedNextIndex, default: 0] += 1
        }
        save()
    }

    func recordChunkResult(expected: [Int], actual: [Int]) {
        for i in 0..<min(expected.count, actual.count) where expected[i] != actual[i] {
            state.missCounts[expected[i], default: 0] += 1
        }
        save()
    }

    func recordFullRecallMismatches(_ indices: [Int]) {
        for index in indices {
            state.missCounts[index, default: 0] += 1
        }
        save()
    }

    func weightedPromptIndex(maxIndex: Int) -> Int {
        let candidates = Array(0...max(0, maxIndex))
        return weightedPick(in: candidates) ?? 0
    }

    func weightedChunkStart(chunkLength: Int, totalCount: Int) -> Int {
        let maxStart = max(0, totalCount - chunkLength)
        let candidates = Array(0...maxStart)
        return weightedPick(in: candidates) ?? 0
    }

    func topMissedSteps(limit: Int) -> [(index: Int, count: Int)] {
        state.missCounts
            .sorted {
                if $0.value == $1.value { return $0.key < $1.key }
                return $0.value > $1.value
            }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    func recordTechniqueRun(completedSteps: Int, totalSteps: Int, elapsedSeconds: Int) {
        state.lastTechniqueRun = TechniqueRunRecord(
            date: Date(),
            completedSteps: completedSteps,
            totalSteps: totalSteps,
            elapsedSeconds: elapsedSeconds
        )
        save()
    }

    func recordTeachingPractice(segmentIndices: [Int], score: Int) {
        state.lastTeachingPractice = TeachingPracticeRecord(
            date: Date(),
            segmentIndices: segmentIndices,
            score: score
        )
        save()
    }

    func markMissedQuestion(id: String) {
        if !state.missedQuestionIDs.contains(id) {
            state.missedQuestionIDs.append(id)
            save()
        }
    }

    func resolveMissedQuestion(id: String) {
        let originalCount = state.missedQuestionIDs.count
        state.missedQuestionIDs.removeAll(where: { $0 == id })
        if state.missedQuestionIDs.count != originalCount {
            save()
        }
    }

    func recordTheoryQuizScore(_ percent: Int) {
        if percent > state.bestTheoryQuizScore {
            state.bestTheoryQuizScore = percent
            save()
        }
    }

    var lastTechniqueSummary: String {
        guard let run = state.lastTechniqueRun else { return "None" }
        return "\(run.completedSteps)/\(run.totalSteps) • \(TimeFormat.mmss(run.elapsedSeconds))"
    }

    var lastTeachingSummary: String {
        guard let teaching = state.lastTeachingPractice else { return "None" }
        return "\(teaching.score)/13"
    }

    private func weightedPick(in values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        let weighted = values.map { value in
            let misses = state.missCounts[value, default: 0]
            return max(1, 1 + misses * 3)
        }
        let total = weighted.reduce(0, +)
        guard total > 0 else { return values.randomElement() }
        var threshold = Int.random(in: 1...total)
        for (idx, value) in values.enumerated() {
            threshold -= weighted[idx]
            if threshold <= 0 { return value }
        }
        return values.last
    }
}

struct ExamPrepState: Codable {
    var orderDrillAttempts: Int = 0
    var orderDrillCorrect: Int = 0
    var missCounts: [Int: Int] = [:]
    var lastTechniqueRun: TechniqueRunRecord?
    var lastTeachingPractice: TeachingPracticeRecord?
    var bestTheoryQuizScore: Int = 0
    var missedQuestionIDs: [String] = []
    var checklist: [String: Bool] = [:]

    var orderDrillAccuracy: Int {
        guard orderDrillAttempts > 0 else { return 0 }
        let value = (Double(orderDrillCorrect) / Double(orderDrillAttempts) * 100.0).rounded()
        return Int(value)
    }
}

struct TechniqueRunRecord: Codable {
    var date: Date
    var completedSteps: Int
    var totalSteps: Int
    var elapsedSeconds: Int
}

struct TeachingPracticeRecord: Codable {
    var date: Date
    var segmentIndices: [Int]
    var score: Int
}

private struct ExamChecklistItem: Identifiable {
    let id: String
    let text: String

    static let items: [ExamChecklistItem] = [
        .init(id: "online_assignments", text: "100% of online assignments complete"),
        .init(id: "hours_done", text: "All required technique practice, practice teaching and observation hours done"),
        .init(id: "theory_passed", text: "Online theoretical exam passed (required before scheduling the practical)"),
        .init(id: "students_ready", text: "3 students lined up for the teaching portion"),
        .init(id: "practical_scheduled", text: "Practical scheduled (about 45–60 min; in person if within an hour of a Master Instructor or Educational Center, otherwise virtual). Teaching comes first, then technique.")
    ]
}

private enum TeachingRubric {
    static let items: [String] = [
        "1. Taught exercises in correct order",
        "2. Exercise name given first",
        "3. Teaches through transitions",
        "4. Corrects student setups; less setup for introductory exercises",
        "5. Correct technique / direct cueing",
        "6. Keeps group moving together",
        "7. Powerhouse cue for each exercise",
        "8. Major priority corrections (gross movement patterns), broad to narrow",
        "9. Voice: volume appropriate, voice sets rhythm",
        "10. Safety: environment, mindful of students",
        "11. Posture: stands to be seen, Pilates posture, moves with purpose (\"do the walk\")",
        "12. Touch: at least 1, moving into touch and out to see; avoids over-touching",
        "13. Progression: teaches to the student's ideal, appropriate tempo"
    ]
}

private enum TechniqueErrorCatalog {
    static func errors(for step: String) -> [String] {
        var items: [String] = [
            "Forgetting an exercise or doing it out of order",
            "Incorrect body setup",
            "Improper gross movement pattern"
        ]
        if step.contains("Hundred") || step.contains("Swan I") {
            items.append("Improper neck/head alignment in spinal flexion and extension")
        }
        if step == "Hundred"
            || step == "Single Leg Stretch"
            || step == "Double Leg Stretch"
            || step == "Single Straight Leg Stretch / Scissors"
            || step == "Double Straight Leg \"Lower Lift\""
            || step == "Criss Cross" {
            items.append("Losing the Powerhouse and letting the low back lift with the head up (Hundred, abdominal series)")
        }
        if step == "One Leg Circle" {
            items.append("Lumbo-pelvic instability (e.g., rocking side to side)")
        }
        if step == "Spine Stretch Forward" || step == "Roll Up" {
            items.append("Hinging from the hips instead of a C-curve")
        }
        if step == "Teaser I" {
            items.append("Momentum or hoisting up (e.g., Teaser I)")
        }
        return items
    }
}

private enum TeachingCueCatalog {
    static func transition(for index: Int) -> String {
        let step = ExamPrepData.levelIMat35[index]
        if step.hasPrefix("(") {
            return step
        }
        if step == "Side Kick Series: Front and Back"
            || step == "Side Kick Series: Up and Down"
            || step == "Side Kick Series: Circles"
            || step == "Side Kick Series: Inner Thigh Lift and Circles" {
            return "(Beats on Belly Transition) between sides"
        }
        return "Use the listed transition into this exercise."
    }
}

private struct TheoryQuestion: Identifiable {
    let id: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

private enum ExamPrepData {
    static let levelIMat35: [String] = [
        "Hundred",
        "Roll Up",
        "One Leg Circle",
        "Rolling Like a Ball",
        "Single Leg Stretch",
        "Double Leg Stretch",
        "Single Straight Leg Stretch / Scissors",
        "Double Straight Leg \"Lower Lift\"",
        "Criss Cross",
        "Spine Stretch Forward",
        "Open Leg Rocker Prep",
        "Open Leg Rocker",
        "Corkscrew I",
        "Corkscrew II",
        "Saw",
        "Swan I – Neck Roll",
        "Single Leg Kick",
        "(Rest Transition)",
        "Neck Pull",
        "Shoulder Bridge Prep",
        "Spine Twist",
        "Side Kick Series: Front and Back",
        "Side Kick Series: Up and Down",
        "Side Kick Series: Circles",
        "Side Kick Series: Inner Thigh Lift and Circles",
        "(Beats on Belly Transition)",
        "Teaser – One Leg",
        "Teaser Prep",
        "Teaser I",
        "Swimming – Prep",
        "Leg Pull Front",
        "Leg Pull Back Prep",
        "Mermaid Stretch",
        "Seal",
        "Push-Up Series"
    ]

    static let theoryQuestions: [TheoryQuestion] = [
        .init(id: "fundamentals", prompt: "True or false: Fundamentals are mini exercises that improve basic biomechanical patterns.", options: ["True", "False"], correctIndex: 0, explanation: "True. Fundamentals are mini exercises that improve basic biomechanical patterns."),
        .init(id: "rib-arm", prompt: "Rib Cage Arms teaches:", options: ["Moving the arms from the back and connecting ribs to scapula", "Pelvic tuck only", "Breath retention", "Speed cueing"], correctIndex: 0, explanation: "Rib Cage Arms teaches arm movement from the back and the rib-to-scapula connection."),
        .init(id: "principles", prompt: "Which list is the six Peak principles?", options: ["breath, concentration, centering, control, precision, flowing movement", "breath, speed, strength, stretch, stamina, precision", "concentration, rhythm, safety, posture, breath, cueing", "control, progression, flow, setup, touch, precision"], correctIndex: 0, explanation: "The six principles are breath, concentration, centering, control, precision, and flowing movement."),
        .init(id: "precision", prompt: "Precision corrects:", options: ["faulty movement patterns", "class attendance", "equipment setup only", "homework compliance"], correctIndex: 0, explanation: "Precision is used to correct faulty movement patterns."),
        .init(id: "five-part", prompt: "Which is NOT one of the 5-Part Formula for Success?", options: ["Flowing Movement", "Session Format", "Presentation Skills", "Progression Guidelines"], correctIndex: 0, explanation: "Flowing Movement is a principle, not one of the five parts."),
        .init(id: "methodology", prompt: "Teaching methodology tenets include setup, execution, flow, cueing, rhythm and voice, and:", options: ["breath dynamics", "maximal loading", "performance testing", "competition prep"], correctIndex: 0, explanation: "Breath dynamics is one of the teaching methodology tenets."),
        .init(id: "first-cue", prompt: "First thing to cue in communication order:", options: ["Exercise name", "Transition", "Setup", "Powerhouse cue"], correctIndex: 0, explanation: "Communication starts with the exercise name."),
        .init(id: "touch", prompt: "Touch techniques include:", options: ["moving-into, moving-away, guiding, stabilizing", "forcing and pulling", "spotting only", "visual cues only"], correctIndex: 0, explanation: "Touch techniques are moving-into, moving-away, guiding, and stabilizing."),
        .init(id: "progressions", prompt: "True or false: Progression guidelines include teaching transitions as exercises.", options: ["True", "False"], correctIndex: 0, explanation: "True. Teaching transitions as exercises is listed in progression guidelines."),
        .init(id: "learning", prompt: "Stages of learning are:", options: ["cognitive, associative, autonomous", "novice, intermediate, expert", "setup, execution, flow", "slow, medium, fast"], correctIndex: 0, explanation: "The stages are cognitive, associative, and autonomous."),
        .init(id: "fourS", prompt: "The Four S's are:", options: ["stability, strength, stretch, stamina", "stability, setup, stretch, speed", "strength, stamina, speed, symmetry", "safety, setup, strength, stamina"], correctIndex: 0, explanation: "The Four S's are stability, strength, stretch, and stamina."),
        .init(id: "mind", prompt: "Five parts of the mind:", options: ["will, intelligence, intuition, imagination, memory", "focus, control, precision, flow, memory", "breath, will, rhythm, safety, memory", "intelligence, pace, will, setup, touch"], correctIndex: 0, explanation: "The five parts are will, intelligence, intuition, imagination, and memory."),
        .init(id: "box", prompt: "Box means:", options: ["shoulder to shoulder, hip to hip", "head to feet line only"], correctIndex: 0, explanation: "Box is shoulder to shoulder and hip to hip."),
        .init(id: "powerhouse", prompt: "Powerhouse is supported by:", options: ["inner thighs and seat (4-inch band)", "soleus and calves"], correctIndex: 0, explanation: "Powerhouse support is from the inner thighs and seat (4-inch band)."),
        .init(id: "soleus", prompt: "True or false: The soleus is part of the Powerhouse.", options: ["True", "False"], correctIndex: 1, explanation: "False. Spinal erectors are part of it; soleus is not."),
        .init(id: "core", prompt: "Core and Powerhouse are:", options: ["not the same", "the same"], correctIndex: 0, explanation: "Core and Powerhouse are not the same."),
        .init(id: "breath-exhale", prompt: "When cueing breath, emphasis should be on:", options: ["exhalation", "inhalation"], correctIndex: 0, explanation: "Cueing breath should emphasize exhalation."),
        .init(id: "neutral", prompt: "True or false: Neutral pelvis and neutral spine are the same.", options: ["True", "False"], correctIndex: 1, explanation: "False. They are not the same."),
        .init(id: "tilt", prompt: "Anterior pelvic tilt means:", options: ["pelvis tips forward and the low back arches", "pelvis tips back and low back flattens"], correctIndex: 0, explanation: "Anterior tilt is forward tip of pelvis with lumbar arching."),
        .init(id: "circumduction", prompt: "Circumduction combines:", options: ["flexion, extension, lateral flexion and slight rotation", "rotation only"], correctIndex: 0, explanation: "Circumduction combines flexion, extension, lateral flexion and slight rotation."),
        .init(id: "ideal", prompt: "True or false: The ideal version of an exercise is exactly as pictured in Joseph Pilates' books.", options: ["True", "False"], correctIndex: 1, explanation: "False. The ideal version is not exactly as pictured."),
        .init(id: "matfirst", prompt: "Joseph Pilates created:", options: ["Mat first", "Apparatus first"], correctIndex: 0, explanation: "Joseph Pilates created the Mat first."),
        .init(id: "animals", prompt: "Joseph Pilates based his work on:", options: ["animals", "Olympic lifting"], correctIndex: 0, explanation: "His work was based on animals."),
        .init(id: "benefits", prompt: "True or false: Pilates benefits include increasing maximal strength.", options: ["True", "False"], correctIndex: 1, explanation: "False. Increasing maximal strength is not listed as a benefit here."),
        .init(id: "endings", prompt: "Endings are:", options: ["postural exercises", "high intensity intervals"], correctIndex: 0, explanation: "Endings are postural exercises."),
        .init(id: "wall", prompt: "The wall can be used to:", options: ["measure postural progress", "increase cardio intensity"], correctIndex: 0, explanation: "The wall can measure postural progress."),
        .init(id: "homework", prompt: "Appropriate homework includes:", options: ["Lunges and Splits", "Teaser only"], correctIndex: 0, explanation: "Lunges and Splits are appropriate homework."),
        .init(id: "roll-seal", prompt: "Rolling Like a Ball and Seal are:", options: ["introductory exercises not taught in the first session", "first-session essentials"], correctIndex: 0, explanation: "They are introductory but not taught in the first session."),
        .init(id: "beats", prompt: "Side Kick transition between sides is:", options: ["Beats on Belly", "Rest Transition"], correctIndex: 0, explanation: "The transition is Beats on Belly."),
        .init(id: "hundred-head", prompt: "First body part lifted in the Hundred:", options: ["head", "legs"], correctIndex: 0, explanation: "The head is lifted first in the Hundred."),
        .init(id: "session-format", prompt: "Session format fact:", options: ["Parts A and B are interchangeable; Part D = Endings", "Part D = Warm-up only"], correctIndex: 0, explanation: "Parts A and B are interchangeable, and Part D is Endings.")
    ]
}

private func buildExamPrepFullRecallReport(input: String) -> ExamPrepFullRecallReport {
    let expected = ExamPrepData.levelIMat35
    let entered = input
        .split(whereSeparator: \.isNewline)
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    let normalizedExpected = expected.map(normalizeExamEntry)
    let normalizedEntered = entered.map(normalizeExamEntry)

    var mismatchIndices: [Int] = []
    var details: [String] = []
    var correct = 0

    for idx in 0..<expected.count {
        let expectedText = normalizedExpected[idx]
        guard idx < normalizedEntered.count else {
            mismatchIndices.append(idx)
            details.append("Step \(idx + 1): missed “\(expected[idx])”.")
            continue
        }
        let enteredText = normalizedEntered[idx]
        if enteredText == expectedText {
            correct += 1
        } else {
            mismatchIndices.append(idx)
            if let actualPosition = normalizedEntered.firstIndex(of: expectedText) {
                details.append("Step \(idx + 1): swapped. Expected “\(expected[idx])”; appeared at step \(actualPosition + 1).")
            } else {
                details.append("Step \(idx + 1): expected “\(expected[idx])”, found “\(entered[idx])”.")
            }
        }
    }

    if normalizedEntered.count > expected.count {
        for idx in expected.count..<normalizedEntered.count {
            details.append("Extra entry at step \(idx + 1): “\(entered[idx])”.")
        }
    }

    let accuracy = Int((Double(correct) / Double(expected.count) * 100.0).rounded())
    return ExamPrepFullRecallReport(accuracy: accuracy, mismatchIndices: mismatchIndices, details: details)
}

private func normalizeExamEntry(_ value: String) -> String {
    value
        .lowercased()
        .replacingOccurrences(of: "“", with: "\"")
        .replacingOccurrences(of: "”", with: "\"")
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private enum AppHaptics {
    static func dragStep() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func drop() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func runTransition() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func tenSecondWarning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

// MARK: - Hours

// WHAT: The iPhone share sheet used for CSV export.
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
