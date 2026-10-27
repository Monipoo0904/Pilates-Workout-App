import Foundation

struct PilatesClass: Codable, Identifiable, Hashable {
    var version: Int
    var id: String
    var name: String
    var props: [String]
    var items: [PilatesClassItem]

    init(
        version: Int = 1,
        id: String = UUID().uuidString,
        name: String,
        props: [String] = [],
        items: [PilatesClassItem]
    ) {
        self.version = version
        self.id = id
        self.name = name
        self.props = props.compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        id = try container.decodeIfPresent(String.self, forKey: .id)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? (try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString)
            : UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? (try container.decodeIfPresent(String.self, forKey: .name) ?? "Untitled Class")
            : "Untitled Class"
        props = (try container.decodeIfPresent([String].self, forKey: .props) ?? []).compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        items = try container.decodeIfPresent([PilatesClassItem].self, forKey: .items) ?? []
    }

    var totalSeconds: Int {
        items.reduce(0) { $0 + max($1.seconds, 0) }
    }
}

struct PilatesClassItem: Codable, Hashable {
    var section: String
    var name: String
    var reps: String
    var seconds: Int
    var cue: String
    var buildingBlock: String
    var modification: String
    var transition: String
    var props: [String]

    init(
        section: String = "",
        name: String = "Untitled Exercise",
        reps: String = "",
        seconds: Int = 30,
        cue: String = "",
        buildingBlock: String = "",
        modification: String = "",
        transition: String = "",
        props: [String] = []
    ) {
        self.section = section
        self.name = name
        self.reps = reps
        self.seconds = max(seconds, 0)
        self.cue = cue
        self.buildingBlock = buildingBlock
        self.modification = modification
        self.transition = transition
        self.props = props.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        section = (try c.decodeIfPresent(String.self, forKey: .section))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        name = (try c.decodeIfPresent(String.self, forKey: .name))?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (try c.decodeIfPresent(String.self, forKey: .name) ?? "Untitled Exercise") : "Untitled Exercise"
        reps = (try c.decodeIfPresent(String.self, forKey: .reps))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        seconds = max(try c.decodeIfPresent(Int.self, forKey: .seconds) ?? 0, 0)
        cue = (try c.decodeIfPresent(String.self, forKey: .cue))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        buildingBlock = (try c.decodeIfPresent(String.self, forKey: .buildingBlock))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        modification = (try c.decodeIfPresent(String.self, forKey: .modification))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        transition = (try c.decodeIfPresent(String.self, forKey: .transition))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        props = (try c.decodeIfPresent([String].self, forKey: .props) ?? []).compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }
}

struct ClassImportEnvelope: Codable {
    var version: Int
    var id: String
    var name: String
    var props: [String]
    var items: [PilatesClassItem]

    func asPilatesClass() -> PilatesClass {
        PilatesClass(version: version, id: id, name: name, props: props, items: items)
    }
}

enum ClassImportError: LocalizedError {
    case invalidJSON
    case noItems

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Clipboard/file JSON is not valid for a Pilates class."
        case .noItems:
            return "The class has no items."
        }
    }
}

enum ClassImportValidator {
    static func parseClass(from data: Data) throws -> PilatesClass {
        do {
            let decoder = JSONDecoder()
            let envelope = try decoder.decode(ClassImportEnvelope.self, from: data)
            let parsed = envelope.asPilatesClass()
            guard !parsed.items.isEmpty else { throw ClassImportError.noItems }
            return parsed
        } catch let error as ClassImportError {
            throw error
        } catch {
            throw ClassImportError.invalidJSON
        }
    }
}
