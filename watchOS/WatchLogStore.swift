// ======================================================================
// WatchLogStore.swift  (Apple Watch app)
// WHAT THIS FILE DOES: Saves classes you log on the watch until they sync to the iPhone.
// TO CHANGE: Rarely needed.
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import Foundation
import Combine

// WHAT: Logs made on the watch, kept until they sync to the iPhone.
@MainActor
final class WatchLogStore: ObservableObject {
    @Published private(set) var logs: [ClassLogEntry] = []
    private let fileURL: URL

    init(filename: String = "watch-logs.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ClassLogEntry].self, from: data) else {
            logs = []
            return
        }
        logs = decoded
    }

    func add(_ entry: ClassLogEntry) {
        logs.append(entry)
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(logs)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Watch log save failed: \(error)")
        }
    }
}
