// xcode: set sdk=iOS

import Foundation
import Combine

// MARK: - CourseStore
/// Manages persistence of CourseModule data (Peak Pilates Level I certification progress).
/// On first launch, initializes with all 12 standard modules (s01–s10 + Theoretical + Practical).
/// Loads/saves from Documents/course.json.
/// Never overwrites user edits: if a module already exists (by id), keeps its completion state.
///
/// USAGE:
///   @StateObject private var courseStore = CourseStore()
///   List(courseStore.modules) { module in ... }
///   courseStore.toggleModule(module)
///   var progress = courseStore.completionProgress  // percentage 0...1
@MainActor
final class CourseStore: ObservableObject {
    // MARK: - Published State
    /// The current list of course modules.
    /// Modify via toggleModule() or addOrReplace() to auto-save.
    @Published private(set) var modules: [CourseModule] = []

    // MARK: - File Persistence
    /// Path to Documents/course.json
    private let fileURL: URL
    /// Encoders/decoders for JSON serialization
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init & Loading
    /// Initializes the store and loads modules from disk.
    /// On first launch (file doesn't exist), seeds with CourseModuleSet.standard.
    /// On subsequent launches, loads saved modules and merges by id (preserves user edits).
    /// - Parameter filename: Name of the JSON file (default: "course.json")
    init(filename: String = "course.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    /// Loads modules from disk or seeds with defaults on first launch.
    /// If file exists, merges by id with the standard set (preserves edits).
    /// If file is missing, seeds with all standard modules and saves.
    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([CourseModule].self, from: data) else {
            // First launch: initialize with all standard modules
            modules = CourseModuleSet.standard
            save()
            return
        }
        // Subsequent launches: merge decoded modules with standard set by id
        // This preserves user edits (completion status) and adds any new modules from CourseModuleSet.standard
        modules = mergeBuiltIns(into: decoded)
        if modules.count != decoded.count { save() }
    }

    /// Saves the current modules array to disk.
    /// Called automatically by toggleModule() and addOrReplace().
    func save() {
        do {
            let data = try encoder.encode(modules)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write course modules: \(error)")
        }
    }

    // MARK: - CRUD Operations
    /// Toggles a module's completion status.
    /// If module is marked done, sets completedDate to now.
    /// If marking incomplete, clears completedDate.
    /// Automatically saves to disk.
    /// - Parameter module: The module to toggle
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

    /// Adds or replaces a module (by id).
    /// Automatically saves to disk.
    /// - Parameter module: The module to add or update
    func addOrReplace(_ module: CourseModule) {
        if let index = modules.firstIndex(where: { $0.id == module.id }) {
            modules[index] = module
        } else {
            modules.append(module)
        }
        save()
    }

    /// Updates a module's notes field.
    /// Automatically saves to disk.
    /// - Parameters:
    ///   - id: The module id to update
    ///   - notes: The new notes text
    func updateNotes(for id: String, notes: String) {
        if let index = modules.firstIndex(where: { $0.id == id }) {
            modules[index].notes = notes
            save()
        }
    }

    // MARK: - Progress Tracking
    /// Calculates overall completion progress: 0...1
    /// Returns number of completed modules / total modules
    var completionProgress: Double {
        guard !modules.isEmpty else { return 0 }
        let done = modules.filter { $0.done }.count
        return Double(done) / Double(modules.count)
    }

    /// Counts how many modules are marked complete
    var completedCount: Int {
        modules.filter { $0.done }.count
    }

    /// Counts total modules (should be 12)
    var totalCount: Int {
        modules.count
    }

    // MARK: - Helper: Merge with Built-Ins
    /// Merges saved modules with CourseModuleSet.standard by id.
    /// Keeps completion status from saved data, adds any new modules from standard.
    /// Used on launch to ensure new modules are available without losing user progress.
    /// - Parameter saved: The modules loaded from disk
    /// - Returns: Merged modules array (preserves edits, adds new ones)
    private func mergeBuiltIns(into saved: [CourseModule]) -> [CourseModule] {
        let standard = CourseModuleSet.standard
        var result = saved

        // Add any standard modules not in saved (new modules added in app updates)
        for standard in standard {
            if !result.contains(where: { $0.id == standard.id }) {
                result.append(standard)
            }
        }

        return result
    }
}
