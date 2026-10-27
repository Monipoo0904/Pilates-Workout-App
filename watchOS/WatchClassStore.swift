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
            classes = [SampleData.starterClass]
            save()
            return
        }
        classes = decoded.isEmpty ? [SampleData.starterClass] : decoded
    }

    func replaceAll(_ values: [PilatesClass]) {
        classes = values.isEmpty ? [SampleData.starterClass] : values
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
