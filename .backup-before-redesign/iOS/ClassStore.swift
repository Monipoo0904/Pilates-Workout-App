// xcode: set sdk=iOS

import Foundation
import Combine

@MainActor
final class ClassStore: ObservableObject {
    @Published private(set) var classes: [PilatesClass] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "classes.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([PilatesClass].self, from: data) else {
            classes = [SampleData.starterClass]
            save()
            return
        }
        classes = decoded.isEmpty ? [SampleData.starterClass] : decoded
    }

    func save() {
        do {
            let data = try encoder.encode(classes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write classes: \(error)")
        }
    }

    func addOrReplace(_ classValue: PilatesClass) {
        if let index = classes.firstIndex(where: { $0.id == classValue.id }) {
            classes[index] = classValue
        } else {
            classes.append(classValue)
        }
        save()
    }

    func importFromClipboard(_ text: String) throws -> PilatesClass {
        guard let data = text.data(using: .utf8) else { throw ClassImportError.invalidJSON }
        let parsed = try ClassImportValidator.parseClass(from: data)
        addOrReplace(parsed)
        return parsed
    }

    func importFile(_ url: URL) throws -> PilatesClass {
        let data = try Data(contentsOf: url)
        let parsed = try ClassImportValidator.parseClass(from: data)
        addOrReplace(parsed)
        return parsed
    }
}
