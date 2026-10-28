// ======================================================================
// PilatesModels.swift  (Shared by iPhone + Watch)
// WHAT THIS FILE DOES: What a class and a move are made of (name, reps, seconds, cue, Building Block, Modification, transition, props), JSON import, and the Level I mat template.
// TO CHANGE: Add a new field to every move: PilatesClassItem. Level I exercise list: LevelIMatTemplate.
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import Foundation

// WHAT: Groups moves into Lunge / Squat / Arms / Abs for the workout builder.
// TO CHANGE: Which words put a move in a group: infer(from:) below.
enum WorkoutSeries: String, Codable, CaseIterable, Identifiable {
    case lunge
    case squat
    case arms
    case abs

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lunge: return "Lunge"
        case .squat: return "Squat"
        case .arms: return "Arms"
        case .abs: return "Abs"
        }
    }

    // TO CHANGE: the words that put a move in Lunge / Squat / Arms / Abs.
    static func infer(from name: String, section: String = "") -> WorkoutSeries {
        let text = "\(name.lowercased()) \(section.lowercased())"

        if text.contains("lunge") || text.contains("split squat") || text.contains("curtsy") || text.contains("reverse lunge") {
            return .lunge
        }
        if text.contains("squat") || text.contains("deadlift") || text.contains("sumo") || text.contains("chair squat") {
            return .squat
        }
        if text.contains("pushup") || text.contains("push-up") || text.contains("push up") || text.contains("press") || text.contains("triceps") || text.contains("arm") || text.contains("punch") || text.contains("dips") || text.contains("shoulder tap") || text.contains("plank") {
            return .arms
        }
        if text.contains("crunch") || text.contains("ab") || text.contains("leg lift") || text.contains("leg lifts") || text.contains("heel tap") || text.contains("bicycle") || text.contains("v-up") || text.contains("dead bug") || text.contains("pulse") || text.contains("roll up") {
            return .abs
        }

        return .abs
    }

    var defaultSuggestions: [String] {
        switch self {
        case .lunge:
            return [
                "Reverse lunge pulse",
                "Alternating split squat pulse",
                "Curtsy lunge hold",
                "Walking lunge",
                "Side lunge reach",
                "Front foot elevated lunge",
                "Skater lunge"
            ]
        case .squat:
            return [
                "Squat pulse",
                "Sumo squat",
                "Chair squat hold",
                "Jump squat",
                "Single-leg squat",
                "Goblet squat hold",
                "Wall sit pulse",
                "Narrow squat pulse"
            ]
        case .arms:
            return [
                "Incline push-up",
                "Diamond push-up",
                "Wide push-up",
                "Push-up plus",
                "Plank shoulder taps",
                "Triceps dips",
                "Bear crawl hold",
                "Tempo push-up",
                "Single-arm press"
            ]
        case .abs:
            return [
                "Single-leg lift",
                "Double-leg lift",
                "Heel taps",
                "Bicycle crunch",
                "Dead bug",
                "V-up pulse",
                "Toe taps",
                "Crunch pulse",
                "Lower leg lift",
                "Candle pulse"
            ]
        }
    }

    var defaultModification: String {
        switch self {
        case .lunge:
            return "Shorten the range or hold onto a wall for balance."
        case .squat:
            return "Reduce the depth and keep the chest lifted; use a chair for support."
        case .arms:
            return "Move to an incline or do the variation on knees to keep the form clean."
        case .abs:
            return "Keep the lower back anchored and bend the knees if needed to protect the spine."
        }
    }
}

// WHAT: A whole class: name, props, and its moves in teaching order.
// TO CHANGE: Never sort items: the order here is the order you teach.
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
        self.items = items.map { item in
            var normalized = item
            if normalized.series == .abs && normalized.name.lowercased().contains("pushup") {
                normalized.series = .arms
            }
            return normalized
        }
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

    /// Moves in teaching order: exactly the order the class was written in.
    /// (Never sort here; the timer, the class screen and the watch all follow this order.)
    var orderedItems: [PilatesClassItem] {
        items
    }

    var seriesBreakdown: [WorkoutSeries: [PilatesClassItem]] {
        Dictionary(grouping: orderedItems, by: { $0.series }).mapValues { $0.sorted { $0.name < $1.name } }
    }

    func suggestionsFor(series: WorkoutSeries) -> [String] {
        let existing = Set(items.filter { $0.series == series }.map { $0.name.lowercased() })
        return series.defaultSuggestions.filter { suggestion in
            !existing.contains(suggestion.lowercased())
        }
    }

    func reorderedBySeries() -> PilatesClass {
        var copy = self
        copy.items = copy.orderedItems
        return copy
    }
}

// WHAT: One move in a class: section, name, reps, seconds, setup, cue, Building Block, Modification, transition, props.
struct PilatesClassItem: Codable, Hashable {
    var section: String
    var name: String
    var reps: String
    var seconds: Int
    var setup: String
    var cue: String
    var buildingBlock: String
    var modification: String
    var transition: String
    var props: [String]
    var series: WorkoutSeries

    init(
        section: String = "",
        name: String = "Untitled Exercise",
        reps: String = "",
        seconds: Int = 30,
        setup: String = "",
        cue: String = "",
        buildingBlock: String = "",
        modification: String = "",
        transition: String = "",
        props: [String] = [],
        series: WorkoutSeries? = nil
    ) {
        self.section = section
        self.name = name
        self.reps = reps
        self.seconds = max(seconds, 0)
        self.setup = setup
        self.cue = cue
        self.buildingBlock = buildingBlock
        self.modification = modification.isEmpty ? WorkoutSeries.infer(from: name, section: section).defaultModification : modification
        self.transition = transition
        self.props = props.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        self.series = series ?? WorkoutSeries.infer(from: name, section: section)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        section = (try c.decodeIfPresent(String.self, forKey: .section))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        name = (try c.decodeIfPresent(String.self, forKey: .name))?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (try c.decodeIfPresent(String.self, forKey: .name) ?? "Untitled Exercise") : "Untitled Exercise"
        reps = (try c.decodeIfPresent(String.self, forKey: .reps))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        seconds = max(try c.decodeIfPresent(Int.self, forKey: .seconds) ?? 0, 0)
        setup = (try c.decodeIfPresent(String.self, forKey: .setup))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        cue = (try c.decodeIfPresent(String.self, forKey: .cue))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        buildingBlock = (try c.decodeIfPresent(String.self, forKey: .buildingBlock))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let decodedModification = (try c.decodeIfPresent(String.self, forKey: .modification))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        modification = decodedModification.isEmpty ? WorkoutSeries.infer(from: name, section: section).defaultModification : decodedModification
        transition = (try c.decodeIfPresent(String.self, forKey: .transition))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        props = (try c.decodeIfPresent([String].self, forKey: .props) ?? []).compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        series = try c.decodeIfPresent(WorkoutSeries.self, forKey: .series) ?? WorkoutSeries.infer(from: name, section: section)
    }
}

// WHAT: The JSON shape used by Paste / Import.
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

// WHAT: Error messages shown when an import fails.
// TO CHANGE: Edit the message text below.
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

// WHAT: Checks pasted/imported JSON before adding a class.
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

// MARK: - Level I Mat Class Template
/// Pre-built Level I Classical Pilates Mat class with full exercise progression
// WHAT: The classical Level I mat exercises used by the Level I builder, in classical order.
// TO CHANGE: Keep them in classical order.
enum LevelIMatTemplate {
    static let exercises: [PilatesClassItem] = [
        PilatesClassItem(
            name: "The Hundred",
            reps: "100 pumps",
            seconds: 60,
            setup: "Lie on your back with legs extended (or knees bent). Arms at your sides.",
            cue: "Pump your arms while breathing in for 5 counts, out for 5.",
            buildingBlock: "Chest lift with pumping arms.",
            modification: "Keep feet on mat or knees bent.",
            transition: "Lower your head and extend your legs.",
            series: .abs
        ),
        PilatesClassItem(
            name: "Roll Up",
            reps: "3-5x",
            seconds: 45,
            setup: "Lie on your back with legs extended and arms overhead.",
            cue: "Articulate one vertebra at a time, stacking up with control.",
            buildingBlock: "Peel the spine off the mat.",
            modification: "Bend knees or use a hold on the back of the thighs.",
            transition: "Return to lying and prepare for Single Leg Circles.",
            series: .abs
        ),
        PilatesClassItem(
            name: "Single Leg Circles",
            reps: "5-10x each",
            seconds: 45,
            setup: "Lie on your back with one leg extended toward the ceiling.",
            cue: "Keep your hips stable and circle only from the hip.",
            buildingBlock: "Stable pelvis while one leg circles.",
            modification: "Smaller circles or hand under glutes for support.",
            transition: "Switch legs and repeat.",
            series: .abs
        ),
        PilatesClassItem(
            name: "Rolling Like a Ball",
            reps: "5-10 sets",
            seconds: 45,
            setup: "Sit in a ball position, holding behind your thighs.",
            cue: "Move as one unit, holding behind the thighs with control.",
            buildingBlock: "Imprint and roll massage the spine.",
            modification: "Small rolls or stay in the ball position.",
            transition: "Return to sitting and prepare for Single Leg Stretch.",
            series: .abs
        ),
        PilatesClassItem(
            name: "Single Leg Stretch",
            reps: "5-10x each",
            seconds: 45,
            setup: "Lie on your back in crunch position with one knee pulled in.",
            cue: "Lengthen the bottom leg while drawing the knee toward the chest.",
            buildingBlock: "Crunch position with alternating pulls.",
            modification: "Hands behind the head or smaller range.",
            transition: "Release and prepare for Double Leg Stretch.",
            series: .abs
        ),
        PilatesClassItem(
            name: "Double Leg Stretch",
            reps: "3-5x",
            seconds: 45,
            setup: "Lie on your back with both knees pulled to chest.",
            cue: "Circle the arms as you extend the legs, then gather back in.",
            buildingBlock: "Both legs extend while arms circle.",
            modification: "Feet remain on mat or smaller range.",
            transition: "Hug knees and prepare for Spine Stretch Forward.",
            series: .abs
        ),
        PilatesClassItem(
            name: "Spine Stretch Forward",
            reps: "3-5x",
            seconds: 30,
            setup: "Sit with legs extended and feet hip-width apart.",
            cue: "Flex the spine and fold forward with a long spine.",
            buildingBlock: "Seated flexion, stacking vertebrae.",
            modification: "Bent knees or hands on thighs.",
            transition: "Roll up to sitting and return to lying for rest.",
            series: .abs
        ),
    ]
}
