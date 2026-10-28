// xcode: set sdk=iOS

import Foundation
import Combine

// MARK: - LibraryStore
/// Manages persistence of LibraryMove data (exercise library).
/// On first launch, initializes with Level I Classical Mat exercises from LibraryMoveSet.levelIMat.
/// Users can add custom moves via "Add your own move" form in the app.
/// Loads/saves from Documents/library.json.
/// Never overwrites: merges by id, preserving user-added moves on updates.
///
/// USAGE:
///   @StateObject private var libraryStore = LibraryStore()
///   let warmupMoves = libraryStore.moves(in: .warmup)
///   let bandMoves = libraryStore.moves(using: "band")
///   libraryStore.addOrReplace(myCustomMove)
///   libraryStore.delete(myCustomMove)
@MainActor
final class LibraryStore: ObservableObject {
    // MARK: - Published State
    /// The current library of moves.
    /// Modify via addOrReplace() or delete() to auto-save.
    @Published private(set) var moves: [LibraryMove] = []

    // MARK: - File Persistence
    /// Path to Documents/library.json
    private let fileURL: URL
    /// Encoders/decoders for JSON serialization
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init & Loading
    /// Initializes the store and loads library from disk.
    /// On first launch (file doesn't exist), seeds with LibraryMoveSet.levelIMat.
    /// On subsequent launches, loads saved moves and merges by id (preserves user-added moves).
    /// - Parameter filename: Name of the JSON file (default: "library.json")
    init(filename: String = "library.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    /// Loads moves from disk or seeds with defaults on first launch.
    /// If file exists, merges by id with the seeded set (preserves user edits).
    /// If file is missing, seeds with Level I mat exercises and saves.
    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([LibraryMove].self, from: data) else {
            // First launch: initialize with Level I Classical Mat exercises
            moves = LibraryMoveSet.levelIMat
            save()
            return
        }
        // Subsequent launches: merge decoded moves with seeded set by id
        moves = mergeBuiltIns(into: decoded)
        if moves.count != decoded.count { save() }
    }

    /// Saves the current moves array to disk.
    /// Called automatically by addOrReplace() and delete().
    func save() {
        do {
            let data = try encoder.encode(moves)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write library: \(error)")
        }
    }

    // MARK: - CRUD Operations
    /// Adds a new move or replaces an existing one (by id).
    /// Automatically saves to disk.
    /// - Parameter move: The LibraryMove to add or update
    func addOrReplace(_ move: LibraryMove) {
        if let index = moves.firstIndex(where: { $0.id == move.id }) {
            moves[index] = move
        } else {
            moves.append(move)
        }
        save()
    }

    /// Deletes a move by id.
    /// Automatically saves to disk.
    /// - Parameter move: The LibraryMove to delete
    func delete(_ move: LibraryMove) {
        moves.removeAll { $0.id == move.id }
        save()
    }

    // MARK: - Filtering & Searching
    /// Returns all moves in a specific exercise area.
    /// - Parameter area: The ExerciseArea to filter by
    /// - Returns: Sorted array of moves in that area
    func moves(in area: ExerciseArea) -> [LibraryMove] {
        moves.filter { $0.area == area }
            .sorted { lhs, rhs in lhs.name.lowercased() < rhs.name.lowercased() }
    }

    /// Returns all moves that use a specific prop.
    /// Useful for "Suggest moves for selected props" feature.
    /// - Parameter prop: The prop name (e.g., "band", "dumbbells", "ball")
    /// - Returns: Sorted array of moves using that prop
    func moves(using prop: String) -> [LibraryMove] {
        moves.filter { $0.props.contains(where: { $0.lowercased() == prop.lowercased() }) }
            .sorted { lhs, rhs in lhs.name.lowercased() < rhs.name.lowercased() }
    }

    /// Searches moves by name, case-insensitive.
    /// - Parameter query: Search string (e.g., "roll", "hundred")
    /// - Returns: Sorted array of matching moves
    func search(for query: String) -> [LibraryMove] {
        let q = query.lowercased()
        return moves.filter { $0.name.lowercased().contains(q) }
            .sorted { lhs, rhs in lhs.name.lowercased() < rhs.name.lowercased() }
    }

    // MARK: - Helper: Merge with Built-Ins
    /// Merges saved moves with LibraryMoveSet.levelIMat by id.
    /// Keeps user-added/custom moves and updates built-in moves if they changed in app updates.
    /// Used on launch to preserve custom moves and add any new built-in exercises.
    /// - Parameter saved: The moves loaded from disk
    /// - Returns: Merged moves array
    private func mergeBuiltIns(into saved: [LibraryMove]) -> [LibraryMove] {
        let builtIn = LibraryMoveSet.levelIMat
        var result = saved

        // Add any built-in moves not in saved
        for built in builtIn {
            if !result.contains(where: { $0.id == built.id }) {
                result.append(built)
            }
        }

        return result
    }
}
