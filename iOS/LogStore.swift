// ======================================================================
// LogStore.swift  (iPhone app)
// WHAT THIS FILE DOES: Saves and loads your logged hours (practice / observation / teaching) and exports them as CSV.
// TO CHANGE: Change the CSV columns in exportCSV().
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import Foundation
import Combine

// WHAT: Your logged hours on the iPhone (saved in logs.json).
@MainActor
final class LogStore: ObservableObject {
    @Published private(set) var logs: [ClassLogEntry] = []
    private let fileURL: URL

    init(filename: String = "logs.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
        // Your own web-tracker data (hours, students, course progress) is added only in builds you run from Xcode,
        // never in the TestFlight / App Store version, so other people don't get your data.
        #if DEBUG
        importWebTrackerIfNeeded()
        #endif
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ClassLogEntry].self, from: data) else {
            logs = []
            return
        }
        logs = decoded.sorted { $0.date > $1.date }
    }

    func add(_ entry: ClassLogEntry) {
        logs.insert(entry, at: 0)
        save()
    }

    func mergeRemote(_ entries: [ClassLogEntry]) {
        var dict = Dictionary(uniqueKeysWithValues: logs.map { ($0.id, $0) })
        for entry in entries { dict[entry.id] = entry }
        logs = Array(dict.values).sorted { $0.date > $1.date }
        save()
    }

    func totalHours(for type: LogType) -> Double {
        logs.filter { $0.type == type }.reduce(0) { $0 + $1.hours }
    }

    func delete(_ entry: ClassLogEntry) {
        logs.removeAll { $0.id == entry.id }
        save()
    }

    func exportCSV() -> URL? {
        var csv = "date,type,hours,class name\n"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for log in logs {
            let safeName = log.className.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\(formatter.string(from: log.date)),\(log.type.rawValue),\(log.hours),\"\(safeName)\"\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PilatesTimerLogs.csv")
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            print("CSV export failed: \(error)")
            return nil
        }
    }

    /// Adds the sessions logged in the web tracker, once.
    private func importWebTrackerIfNeeded() {
        let key = "didImportWebTrackerLogs.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let existing = Set(logs.map(\.id))
        let new = WebTrackerImport.sessions.filter { !existing.contains($0.id) }
        if !new.isEmpty {
            logs = (logs + new).sorted { $0.date > $1.date }
            save()
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(logs)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save logs: \(error)")
        }
    }
}
