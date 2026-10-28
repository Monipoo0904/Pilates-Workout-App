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
        CourseModule(id: "s01", title: "Section 1: Welcome to Level I Classical Mat"),
        CourseModule(id: "s02", title: "Section 2: The Mat is the Method"),
        CourseModule(id: "s03", title: "Section 3: Peak Pilates® Foundations"),
        CourseModule(id: "s04", title: "Section 4: The Science of Movement"),
        CourseModule(id: "s05", title: "Section 5: Mat Technique Basics"),
        CourseModule(id: "s06", title: "Section 6: Optional Class Add-Ins"),
        CourseModule(id: "s07", title: "Section 7: The Art of Teaching"),
        CourseModule(id: "s08", title: "Section 8: Theoretical Exam"),
        CourseModule(id: "s09", title: "Section 9: Practical Assessment"),
        CourseModule(id: "s10", title: "Conclusion: feedback & evaluation"),
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

// MARK: - Web tracker import (one time)
/// Data copied from the Pilates hours web tracker on Oct 27, 2026.
/// Each store adds it once on first launch after this update; your later edits are kept.
enum WebTrackerImport {
    static func day(_ ymd: String) -> Date {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.date(from: ymd + " 12:00") ?? Date()
    }

    static let sessions: [ClassLogEntry] = [
        ClassLogEntry(id: UUID(uuidString: "2cb528bc-358a-543f-9bca-fa08edefe956")!, date: day("2026-10-09"), type: .practice, hours: 1, className: "Practices at home", sourceDevice: "Web tracker"),
        ClassLogEntry(id: UUID(uuidString: "201aec20-1ede-5eba-9e2a-d60a6733af89")!, date: day("2026-10-12"), type: .observation, hours: 1, className: "Observed Emily’s class", sourceDevice: "Web tracker"),
        ClassLogEntry(id: UUID(uuidString: "c6291e33-da2f-529d-817a-665c0ea27e09")!, date: day("2026-10-12"), type: .practice, hours: 1, className: "Monday Mat class", sourceDevice: "Web tracker"),
        ClassLogEntry(id: UUID(uuidString: "2ceac210-5f06-5f61-b0a8-4a11a320be85")!, date: day("2026-10-13"), type: .practice, hours: 1, className: "Reformer class", sourceDevice: "Web tracker"),
        ClassLogEntry(id: UUID(uuidString: "bcb2ff92-8f06-5be8-a508-5f902238191e")!, date: day("2026-10-18"), type: .practice, hours: 0.25, className: "20-min Glute & Core with ball and block", sourceDevice: "Web tracker")
    ]

    static let students: [Student] = [
        Student(id: UUID(uuidString: "15e7a28e-0b45-5275-8154-b93f98cbb7e2")!, name: "Jada"),
        Student(id: UUID(uuidString: "c64461d6-92ec-5c27-abc3-fe428bd0d854")!, name: "Veronica")
    ]

    /// Real Peak Pilates Level I Classical Mat course sections and my progress.
    static let modules: [CourseModule] = [
        CourseModule(id: "s01", title: "Section 1: Welcome to Level I Classical Mat", done: true, notes: "15 items · study guide, exercise charts, required hours log, observation journal"),
        CourseModule(id: "s02", title: "Section 2: The Mat is the Method", done: true, notes: "3 items · course overview, history"),
        CourseModule(id: "s03", title: "Section 3: Peak Pilates® Foundations", done: true, notes: "In progress · 6 items left incl. The Fundamentals video (34 min) + Quiz 1 · Target: by Sun Oct 4"),
        CourseModule(id: "s04", title: "Section 4: The Science of Movement", done: true, notes: "8 items · ~75 min anatomy video + Quiz 2 · Target: week of Oct 5"),
        CourseModule(id: "s05", title: "Section 5: Mat Technique Basics", done: true, notes: "31 items · every exercise video (~85 min), workout, drill work + Quiz 3. Pairs well with home practice. · Target: weeks of Oct 12 and Oct 19"),
        CourseModule(id: "s06", title: "Section 6: Optional Class Add-Ins", done: true, notes: "14 items · short videos (~17 min) + Quiz 5 · Target: week of Oct 26"),
        CourseModule(id: "s07", title: "Section 7: The Art of Teaching", done: true, notes: "12 items · 5-Part Formula, cueing, class planning + Quiz 6, self assessment. Use it in your coworker sessions. · Target: week of Oct 26"),
        CourseModule(id: "s08", title: "Section 8: Theoretical Exam", done: false, notes: "Practice exam, then the theoretical exam · Target: week of Nov 2"),
        CourseModule(id: "s09", title: "Section 9: Practical Assessment", done: false, notes: "Prepare + set up practical, technique & teaching assessments, submit 50 logged hours. Read the setup article early. · Target: week of Nov 9 (submit by Nov 13)"),
        CourseModule(id: "s10", title: "Conclusion: feedback & evaluation", done: false, notes: "2 items · Target: by Nov 13")
    ]
}
