import Foundation
import Combine

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
