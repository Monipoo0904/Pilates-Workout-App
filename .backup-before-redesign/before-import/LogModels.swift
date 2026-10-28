import Foundation
import SwiftUI

enum LogType: String, Codable, CaseIterable, Identifiable {
    case teaching
    case practice
    case observation

    var id: String { rawValue }
}

struct ClassLogEntry: Codable, Identifiable, Hashable {
    // MARK: - Original Fields
    /// Unique identifier for this log entry
    var id: UUID
    /// Date the class was done
    var date: Date
    /// Type of session: practice, observation, or teaching
    var type: LogType
    /// Hours spent (0.25 increments)
    var hours: Double
    /// Name of the class taken or taught
    var className: String
    /// Device that logged the session (e.g., "iPhone", "Watch")
    var sourceDevice: String
    
    // MARK: - New Extended Fields (backward compatible with decodeIfPresent)
    /// Where the class was held (studio name, location, or "home")
    /// Example: "The Mat", "Ergo Body", "home practice"
    var place: String?
    /// UUIDs of students taught (for teaching sessions)
    /// Empty or nil = personal practice
    var studentIds: [UUID]?
    /// Notes on the session (how it went, what to focus on next, etc.)
    var note: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: LogType,
        hours: Double,
        className: String,
        sourceDevice: String,
        place: String? = nil,
        studentIds: [UUID]? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.hours = hours
        self.className = className
        self.sourceDevice = sourceDevice
        self.place = place
        self.studentIds = studentIds
        self.note = note
    }

    // MARK: - Custom Decoding for Backward Compatibility
    /// Allows old saved logs (without place, studentIds, note) to load without errors.
    /// New fields are optional; old saves will have nil values for new fields.
    enum CodingKeys: String, CodingKey {
        case id, date, type, hours, className, sourceDevice, place, studentIds, note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        type = try container.decode(LogType.self, forKey: .type)
        hours = try container.decode(Double.self, forKey: .hours)
        className = try container.decode(String.self, forKey: .className)
        sourceDevice = try container.decode(String.self, forKey: .sourceDevice)
        // decodeIfPresent: gracefully handle missing fields from old saves
        place = try container.decodeIfPresent(String.self, forKey: .place)
        studentIds = try container.decodeIfPresent([UUID].self, forKey: .studentIds)
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }
}

enum TimeFormat {
    static func mmss(_ seconds: Int) -> String {
        let s = max(seconds, 0)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func hoursRoundedQuarter(from seconds: Int) -> Double {
        let raw = Double(max(seconds, 0)) / 3600.0
        return (raw * 4.0).rounded() / 4.0
    }
}

extension PilatesClass {
    var minutesLabel: String { "\(Int((Double(totalSeconds) / 60).rounded())) min" }
}

// MARK: - Theme (matches the Fall Into Pilates flyer and MyVillage Project colors)

enum Theme {
    static let blush = Color(hex: 0xFBE4EA)
    static let petal = Color(hex: 0xF6C1D1)
    static let rose = Color(hex: 0xD1457A)
    static let berry = Color(hex: 0x7D2350)
    static let cream = Color(hex: 0xFFF7F5)
    static let gold = Color(hex: 0xB88D2D)
    static let brown = Color(hex: 0x4E3729)
    static let sage = Color(hex: 0x5F7D5A)
    static let lightSage = Color(hex: 0xA8C3A0)
    static let clay = Color(hex: 0xB5532F)
    static let peach = Color(hex: 0xF4A582)

    /// Serif italic headline, like the flyer.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .serif).italic()
    }

    static let background = LinearGradient(colors: [cream, blush], startPoint: .top, endPoint: .bottom)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

struct Chip: View {
    let text: String
    var tint: Color = Theme.rose

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct TimerRing: View {
    /// Fraction elapsed, 0...1.
    let progress: Double
    var lineWidth: CGFloat = 14
    var track: Color = Theme.petal
    var tint: Color = Theme.rose

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
        }
    }
}

struct LabeledNote: View {
    let title: String
    let text: String
    let icon: String
    let color: Color
    var textColor: Color = Theme.brown

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.bold)).foregroundStyle(color)
                Text(text).font(.footnote).foregroundStyle(textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

enum ClassAlerts {
    static let tenMinutes = 600

    /// True at the moment the class crosses the 10-minutes-left mark.
    static func crossedTenMinutes(old: Int, new: Int, total: Int) -> Bool {
        total > tenMinutes && old > tenMinutes && new <= tenMinutes && new > 0
    }
}

// MARK: - Student Model
struct Student: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var contact: String?
    var injuries: String?
    var goals: String?
    var notes: String?

    init(id: UUID = UUID(), name: String, contact: String? = nil, injuries: String? = nil, goals: String? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.contact = contact
        self.injuries = injuries
        self.goals = goals
        self.notes = notes
    }
}

// MARK: - CourseModule Model
struct CourseModule: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var done: Bool
    var completedDate: Date?
    var notes: String?

    init(id: String, title: String, done: Bool = false, completedDate: Date? = nil, notes: String? = nil) {
        self.id = id
        self.title = title
        self.done = done
        self.completedDate = completedDate
        self.notes = notes
    }
}

enum CourseModuleSet {
    static let standard: [CourseModule] = [
        CourseModule(id: "s01", title: "Principles of Movement"),
        CourseModule(id: "s02", title: "Basic Mat Work"),
        CourseModule(id: "s03", title: "Breathing Techniques"),
        CourseModule(id: "s04", title: "Core Engagement"),
        CourseModule(id: "s05", title: "Flow & Transitions"),
        CourseModule(id: "s06", title: "Modifications & Progressions"),
        CourseModule(id: "s07", title: "Class Structure & Cueing"),
        CourseModule(id: "s08", title: "Common Injuries & Adaptations"),
        CourseModule(id: "s09", title: "Music & Pacing"),
        CourseModule(id: "s10", title: "Teaching Strategies"),
        CourseModule(id: "theoretical", title: "Theoretical Exam (50 questions, 60 min, pass 40)"),
        CourseModule(id: "practical", title: "Practical Assessment"),
    ]
}

// MARK: - Exercise Area & LibraryMove
enum ExerciseArea: String, Codable, CaseIterable {
    case warmup = "warm-up"
    case arms
    case glutes
    case core
    case stretch

    var label: String {
        switch self {
        case .warmup: "Warm-Up"
        case .arms: "Arms"
        case .glutes: "Glutes"
        case .core: "Core"
        case .stretch: "Stretch"
        }
    }
}

struct LibraryMove: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var area: ExerciseArea
    var props: [String]
    var reps: String
    var seconds: Int
    var cue: String
    var buildingBlock: String
    var modification: String

    init(id: UUID = UUID(), name: String, area: ExerciseArea, props: [String] = [], reps: String = "", seconds: Int = 0, cue: String, buildingBlock: String, modification: String) {
        self.id = id
        self.name = name
        self.area = area
        self.props = props
        self.reps = reps
        self.seconds = seconds
        self.cue = cue
        self.buildingBlock = buildingBlock
        self.modification = modification
    }
}

enum LibraryMoveSet {
    static let levelIMat: [LibraryMove] = [
        LibraryMove(name: "The Hundred", area: .warmup, reps: "100 pumps", cue: "Pump your arms while breathing in for 5 counts, out for 5.", buildingBlock: "Chest lift with pumping arms.", modification: "Feet on mat or knees bent."),
        LibraryMove(name: "Roll Up", area: .stretch, reps: "3-5x", cue: "Articulate one vertebra at a time, stacking up with control.", buildingBlock: "Peel the spine off the mat.", modification: "Bend knees or use a hold on the back of the thighs."),
        LibraryMove(name: "Single Leg Circles", area: .core, reps: "5-10x", cue: "Keep your hips stable and circle only from the hip.", buildingBlock: "Stable pelvis while one leg circles.", modification: "Smaller circles or hand under glutes for support."),
        LibraryMove(name: "Rolling Like a Ball", area: .core, reps: "5-10 sets", cue: "Move as one unit, holding behind the thighs with control.", buildingBlock: "Imprint and roll massage the spine.", modification: "Small rolls or stay in the ball position."),
        LibraryMove(name: "Single Leg Stretch", area: .core, reps: "5-10x", cue: "Lengthen the bottom leg while drawing the knee toward the chest.", buildingBlock: "Crunch position with alternating pulls.", modification: "Hands behind the head or smaller range."),
        LibraryMove(name: "Double Leg Stretch", area: .core, reps: "3-5x", cue: "Circle the arms as you extend the legs, then gather back in.", buildingBlock: "Both legs extend while arms circle.", modification: "Feet remain on mat or smaller range."),
        LibraryMove(name: "Spine Stretch Forward", area: .stretch, reps: "3-5x", cue: "Flex the spine and fold forward with a long spine.", buildingBlock: "Seated flexion, stacking vertebrae.", modification: "Bent knees or hands on thighs."),
    ]
}
