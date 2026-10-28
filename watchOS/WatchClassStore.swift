import Foundation
import Combine

@MainActor
final class WatchClassStore: ObservableObject {
    @Published private(set) var classes: [PilatesClass] = []
    private let fileURL: URL

    init(filename: String = "watch-classes.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([PilatesClass].self, from: data) else {
            classes = SampleData.builtIns
            save()
            return
        }
        let merged = SampleData.mergingBuiltIns(into: decoded)
        classes = merged
        if merged.count != decoded.count { save() }
    }

    func replaceAll(_ values: [PilatesClass]) {
        classes = values.isEmpty ? SampleData.builtIns : values
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(classes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Watch class save failed: \(error)")
        }
    }
}
