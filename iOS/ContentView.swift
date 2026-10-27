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
            .tabItem { Label("Classes", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                LogsView()
            }
            .tabItem { Label("Logs", systemImage: "clock.badge.checkmark") }
        }
        .environmentObject(classStore)
        .environmentObject(logStore)
        .environmentObject(connectivity)
        .onChange(of: connectivity.latestWatchLogs) { _, logs in
            logStore.mergeRemote(logs)
        }
    }
}

struct ClassListView: View {
    @EnvironmentObject private var classStore: ClassStore
    @EnvironmentObject private var connectivity: PhoneConnectivityManager

    @State private var statusText = ""
    @State private var showImporter = false

    var body: some View {
        List {
            Section {
                Button("Paste class") {
                    if let text = UIPasteboard.general.string {
                        do {
                            let parsed = try classStore.importFromClipboard(text)
                            statusText = "Imported: \(parsed.name) (\(parsed.items.count) items)"
                        } catch {
                            statusText = error.localizedDescription
                        }
                    } else {
                        statusText = "Clipboard is empty."
                    }
                }

                Button("Import JSON from Files") {
                    showImporter = true
                }

                Button("Send to Watch") {
                    connectivity.sendClasses(classStore.classes)
                }
            }

            Section("Saved classes") {
                ForEach(classStore.classes, id: \.id) { classValue in
                    NavigationLink(classValue.name) {
                        ClassDetailView(plan: classValue)
                    }
                }
            }
        }
        .navigationTitle("PilatesTimer")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        let parsed = try classStore.importFile(url)
                        statusText = "Imported: \(parsed.name) (\(parsed.items.count) items)"
                    } catch {
                        statusText = error.localizedDescription
                    }
                }
            case .failure(let error):
                statusText = error.localizedDescription
            }
        }
        .overlay(alignment: .bottom) {
            VStack {
                if !connectivity.syncStatus.isEmpty { 
                    Text(connectivity.syncStatus)
                        .font(.caption)
                        .padding(8)
                        .background(.thinMaterial, in: Capsule())
                }
                if !statusText.isEmpty {
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding(.bottom, 10)
        }
    }
}

struct ClassDetailView: View {
    let plan: PilatesClass

    var body: some View {
        List {
            Section {
                Text("Bring: \(plan.props.joined(separator: ", "))")
                NavigationLink("Start class on iPhone") {
                    PhoneRunView(plan: plan)
                }
            }

            ForEach(Array(plan.items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 6) {
                    if !item.section.isEmpty { Text(item.section).font(.caption).foregroundStyle(.secondary) }
                    Text(item.name).font(.headline)
                    if !item.reps.isEmpty { Text(item.reps) }
                    Text("Seconds: \(item.seconds)")
                    if !item.cue.isEmpty { Text(item.cue) }
                    if !item.buildingBlock.isEmpty { Text("Building Block: \(item.buildingBlock)") }
                    if !item.modification.isEmpty { Text("Modification: \(item.modification)").foregroundStyle(.red) }
                    if !item.props.isEmpty { Text("Props: \(item.props.joined(separator: ", "))") }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(plan.name)
    }
}

struct PhoneRunView: View {
    @EnvironmentObject private var logStore: LogStore
    @StateObject private var controller: RunSessionController
    @State private var promptVisible = false
    @State private var suggestedHours: Double = 0

    init(plan: PilatesClass) {
        _controller = StateObject(wrappedValue: RunSessionController(plan: plan))
    }

    var body: some View {
        VStack(spacing: 12) {
            if let item = controller.currentItem {
                Text(item.section).font(.caption).foregroundStyle(.secondary)
                Text(item.name).font(.title2).multilineTextAlignment(.center)
                if !item.reps.isEmpty { Text(item.reps).font(.headline) }
                Text(TimeFormat.mmss(controller.snapshot.currentItemRemaining))
                    .font(.system(size: 58, weight: .semibold, design: .monospaced))
                ProgressView(value: Double(controller.snapshot.currentItemElapsed), total: Double(max(item.seconds, 1)))
                Text("Whole class: \(TimeFormat.mmss(controller.snapshot.classElapsed)) of \(TimeFormat.mmss(controller.snapshot.totalClassSeconds))")
                Text("Time left: \(TimeFormat.mmss(controller.snapshot.classRemaining))")
                Text("Next: \(controller.nextItemName)")
            }

            HStack {
                Button("Back") { controller.back() }
                Button(controller.snapshot.isPaused ? "Resume" : "Pause") { controller.pauseResume() }
                Button("Next") { controller.next() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Run")
        .onAppear {
            controller.start()
        }
        .onDisappear {
            controller.stop()
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

struct LogsView: View {
    @EnvironmentObject private var logStore: LogStore
    @State private var exportURL: URL?
    @State private var showShare = false

    var body: some View {
        List {
            Section("Totals") {
                GoalRow(label: "Practice", current: logStore.totalHours(for: .practice), goal: 20)
                GoalRow(label: "Observation", current: logStore.totalHours(for: .observation), goal: 10)
                GoalRow(label: "Teaching", current: logStore.totalHours(for: .teaching), goal: 20)
            }

            Section("Entries") {
                ForEach(logStore.logs) { log in
                    VStack(alignment: .leading) {
                        Text(log.className).font(.headline)
                        Text("\(log.type.rawValue.capitalized) • \(String(format: "%.2f", log.hours)) h • \(log.date.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Logs")
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
}

private struct GoalRow: View {
    let label: String
    let current: Double
    let goal: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label): \(String(format: "%.2f", current)) / \(String(format: "%.0f", goal)) h")
            ProgressView(value: current, total: goal)
        }
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
