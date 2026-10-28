// ======================================================================
// ClassStore.swift  (iPhone app)
// WHAT THIS FILE DOES: Saves and loads your data on the iPhone: classes, students, course modules, and library moves (each in its own JSON file).
// TO CHANGE: Built-in content is in Shared/SampleData.swift and Shared/LogModels.swift; edit it there, not here.
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

// xcode: set sdk=iOS

import Foundation
import Combine

// WHAT: Your classes on the iPhone. Loads them, adds built-in classes you don't have, saves imports and edits.
// TO CHANGE: Built-in classes live in Shared/SampleData.swift.
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
            classes = SampleData.builtIns
            save()
            return
        }
        let merged = SampleData.mergingBuiltIns(into: decoded)
        classes = merged
        if merged.count != decoded.count { save() }
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
        let normalized = classValue.reorderedBySeries()
        if let index = classes.firstIndex(where: { $0.id == normalized.id }) {
            classes[index] = normalized
        } else {
            classes.append(normalized)
        }
        classes.sort { lhs, rhs in
            lhs.name.lowercased() < rhs.name.lowercased()
        }
        save()
    }

    // WHAT: removes a class (and the watch copy, via auto-sync).
    func delete(_ classValue: PilatesClass) {
        classes.removeAll { $0.id == classValue.id }
        save()
    }

    // WHAT: makes a copy named "... (copy)" that you can change without touching the original.
    func duplicate(_ classValue: PilatesClass) {
        var copy = classValue
        copy.id = UUID().uuidString
        copy.version = 1
        copy.name = classValue.name + " (copy)"
        addOrReplace(copy)
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

// MARK: - StudentStore
// WHAT: Your students on the iPhone (saved in students.json).
@MainActor
final class StudentStore: ObservableObject {
    @Published private(set) var students: [Student] = []
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "students.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
        importWebTrackerIfNeeded()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([Student].self, from: data) else {
            students = []
            return
        }
        students = decoded
    }

    /// Adds the students from the web tracker, once.
    private func importWebTrackerIfNeeded() {
        let key = "didImportWebTrackerStudents.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let names = Set(students.map { $0.name.lowercased() })
        let new = WebTrackerImport.students.filter { !names.contains($0.name.lowercased()) }
        if !new.isEmpty {
            students = (students + new).sorted { $0.name.lowercased() < $1.name.lowercased() }
            save()
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    func save() {
        do {
            let data = try encoder.encode(students)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write students: \(error)")
        }
    }

    func addOrReplace(_ student: Student) {
        if let index = students.firstIndex(where: { $0.id == student.id }) {
            students[index] = student
        } else {
            students.append(student)
        }
        students.sort { lhs, rhs in
            lhs.name.lowercased() < rhs.name.lowercased()
        }
        save()
    }

    func delete(_ student: Student) {
        students.removeAll { $0.id == student.id }
        save()
    }

    func studentName(for id: UUID) -> String {
        students.first { $0.id == id }?.name ?? "Unknown"
    }
}

// MARK: - CourseStore
// WHAT: Your course modules and progress (saved in course.json).
// TO CHANGE: Module names: CourseModuleSet in Shared/LogModels.swift.
@MainActor
final class CourseStore: ObservableObject {
    @Published private(set) var modules: [CourseModule] = []
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "course.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
        importWebTrackerIfNeeded()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([CourseModule].self, from: data) else {
            modules = CourseModuleSet.standard
            save()
            return
        }
        modules = mergeBuiltIns(into: decoded)
        if modules.count != decoded.count { save() }
    }

    /// Uses the real Peak course section names and the progress from the web tracker, once.
    private func importWebTrackerIfNeeded() {
        let key = "didImportWebTrackerCourse.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        for module in WebTrackerImport.modules {
            if let index = modules.firstIndex(where: { $0.id == module.id }) {
                modules[index].title = module.title
                modules[index].notes = module.notes
                if module.done { modules[index].done = true }
            } else {
                modules.append(module)
            }
        }
        save()
        UserDefaults.standard.set(true, forKey: key)
    }

    func save() {
        do {
            let data = try encoder.encode(modules)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write course modules: \(error)")
        }
    }

    func toggleModule(_ module: CourseModule) {
        if let index = modules.firstIndex(where: { $0.id == module.id }) {
            modules[index].done = !modules[index].done
            if modules[index].done {
                modules[index].completedDate = Date()
            } else {
                modules[index].completedDate = nil
            }
            save()
        }
    }

    func addOrReplace(_ module: CourseModule) {
        if let index = modules.firstIndex(where: { $0.id == module.id }) {
            modules[index] = module
        } else {
            modules.append(module)
        }
        save()
    }

    var completionProgress: Double {
        guard !modules.isEmpty else { return 0 }
        let done = modules.filter { $0.done }.count
        return Double(done) / Double(modules.count)
    }

    private func mergeBuiltIns(into saved: [CourseModule]) -> [CourseModule] {
        let standard = CourseModuleSet.standard
        var result = saved
        for standard in standard {
            if !result.contains(where: { $0.id == standard.id }) {
                result.append(standard)
            }
        }
        return result
    }
}

// MARK: - LibraryStore
// WHAT: Your exercise library (saved in library.json). Adds built-in moves you don't have and removes duplicate copies.
// TO CHANGE: Built-in moves: LibraryMoveSet in Shared/LogModels.swift.
@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var moves: [LibraryMove] = []
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "library.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([LibraryMove].self, from: data) else {
            moves = LibraryMoveSet.all
            save()
            return
        }
        moves = mergeBuiltIns(into: decoded)
        if moves != decoded { save() }
    }

    func save() {
        do {
            let data = try encoder.encode(moves)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write library: \(error)")
        }
    }

    func addOrReplace(_ move: LibraryMove) {
        if let index = moves.firstIndex(where: { $0.id == move.id }) {
            moves[index] = move
        } else {
            moves.append(move)
        }
        save()
    }

    func delete(_ move: LibraryMove) {
        moves.removeAll { $0.id == move.id }
        save()
    }

    func moves(in area: ExerciseArea) -> [LibraryMove] {
        moves.filter { $0.area == area }
            .sorted { lhs, rhs in lhs.name.lowercased() < rhs.name.lowercased() }
    }

    /// Adds built-in moves you don't have yet (matched by name), removes duplicate
    /// copies of built-ins, and fills in the style on older saved copies.
    private func mergeBuiltIns(into saved: [LibraryMove]) -> [LibraryMove] {
        let builtIns = Dictionary(LibraryMoveSet.all.map { ($0.name.lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
        var seenBuiltIns = Set<String>()
        var result: [LibraryMove] = []
        for var move in saved {
            let key = move.name.lowercased()
            if let builtIn = builtIns[key] {
                if seenBuiltIns.contains(key) { continue }
                seenBuiltIns.insert(key)
                if move.style == nil { move.style = builtIn.style }
            }
            result.append(move)
        }
        for move in LibraryMoveSet.all where !seenBuiltIns.contains(move.name.lowercased()) {
            result.append(move)
        }
        return result
    }
}
