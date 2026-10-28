// ======================================================================
// LogModels.swift  (Shared by iPhone + Watch)
// WHAT THIS FILE DOES: The look of the app (Theme colors and fonts), small reusable pieces (Chip, TimerRing, LabeledNote), the 10-minute alert, hour logs, students, course modules, the exercise library (all styles), and your web tracker data.
// TO CHANGE: Colors: enum Theme. Alert time: ClassAlerts. Course names: CourseModuleSet. New library moves: moreStyles.
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import Foundation
import SwiftUI

// WHAT: The three kinds of hours: teaching, practice, observation.
enum LogType: String, Codable, CaseIterable, Identifiable {
    case teaching
    case practice
    case observation

    var id: String { rawValue }
}

// WHAT: One logged session: date, type, hours, class, where it came from, place, students, note.
// TO CHANGE: New fields must be optional (?) so older saved logs still load.
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

// WHAT: Turns seconds into "m:ss" and rounds hours to quarter hours.
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

// WHAT: The app's colors and heading font, matched to the Fall Into Pilates flyer and MyVillage colors.
// TO CHANGE: Change a color by editing its 6-character hex code after 0x.
enum Theme {
    // TO CHANGE: colors. blush/cream = backgrounds, rose = buttons and rings, berry = headings, gold = accents, sage = Building Blocks, clay = Modifications.
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
    // TO CHANGE: heading font. .serif can be .default or .rounded; remove .italic() for upright.
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

// WHAT: Small rounded label (e.g. "45 min", "Pilates ball").
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

// WHAT: The circular progress ring used by the timers and hour goals.
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

// WHAT: Icon + title + text block used for Cue, Building Block, Modification and Transition.
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

// WHAT: When the "10 minutes left" alert fires.
// TO CHANGE: Change tenMinutes (in seconds): 600 = 10 min, 300 = 5 min.
enum ClassAlerts {
    // TO CHANGE: alert time in seconds.
    static let tenMinutes = 600

    /// True at the moment the class crosses the 10-minutes-left mark.
    static func crossedTenMinutes(old: Int, new: Int, total: Int) -> Bool {
        total > tenMinutes && old > tenMinutes && new <= tenMinutes && new > 0
    }
}

// MARK: - Student Model
// WHAT: One student: name, contact, injuries, goals, notes.
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
// WHAT: One course section with done / date / notes.
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

// WHAT: The Peak Pilates Level I course sections shown on a new install.
// TO CHANGE: Edit titles here.
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
// WHAT: Body areas used to filter the Library.
// TO CHANGE: Add an area: add a case AND its label below.
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

// WHAT: One move in the exercise library.
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
    /// Classical, contemporary, barre... nil for moves you add yourself.
    var style: MoveStyle?
    /// Harder "layer up" options you wrote. nil = use the built-in list (MoveLayers).
    var layers: String?

    init(id: UUID = UUID(), name: String, area: ExerciseArea, props: [String] = [], reps: String = "", seconds: Int = 0, cue: String, buildingBlock: String, modification: String, style: MoveStyle? = nil, layers: String? = nil) {
        self.id = id
        self.name = name
        self.area = area
        self.props = props
        self.reps = reps
        self.seconds = seconds
        self.cue = cue
        self.buildingBlock = buildingBlock
        self.modification = modification
        self.style = style
        self.layers = layers
    }
}

// WHAT: Built-in library moves.
// TO CHANGE: Add moves to moreStyles (copy a line, edit it). Names must be unique.
enum LibraryMoveSet {
    static let levelIMat: [LibraryMove] = [
        LibraryMove(name: "The Hundred", area: .warmup, reps: "100 pumps", cue: "Pump your arms while breathing in for 5 counts, out for 5.", buildingBlock: "Chest lift with pumping arms.", modification: "Feet on mat or knees bent.", style: .classical),
        LibraryMove(name: "Roll Up", area: .stretch, reps: "3-5x", cue: "Articulate one vertebra at a time, stacking up with control.", buildingBlock: "Peel the spine off the mat.", modification: "Bend knees or use a hold on the back of the thighs.", style: .classical),
        LibraryMove(name: "Single Leg Circles", area: .core, reps: "5-10x", cue: "Keep your hips stable and circle only from the hip.", buildingBlock: "Stable pelvis while one leg circles.", modification: "Smaller circles or hand under glutes for support.", style: .classical),
        LibraryMove(name: "Rolling Like a Ball", area: .core, reps: "5-10 sets", cue: "Move as one unit, holding behind the thighs with control.", buildingBlock: "Imprint and roll massage the spine.", modification: "Small rolls or stay in the ball position.", style: .classical),
        LibraryMove(name: "Single Leg Stretch", area: .core, reps: "5-10x", cue: "Lengthen the bottom leg while drawing the knee toward the chest.", buildingBlock: "Crunch position with alternating pulls.", modification: "Hands behind the head or smaller range.", style: .classical),
        LibraryMove(name: "Double Leg Stretch", area: .core, reps: "3-5x", cue: "Circle the arms as you extend the legs, then gather back in.", buildingBlock: "Both legs extend while arms circle.", modification: "Feet remain on mat or smaller range.", style: .classical),
        LibraryMove(name: "Spine Stretch Forward", area: .stretch, reps: "3-5x", cue: "Flex the spine and fold forward with a long spine.", buildingBlock: "Seated flexion, stacking vertebrae.", modification: "Bent knees or hands on thighs.", style: .classical),
    ]
}

// MARK: - Web tracker import (one time)
/// Data copied from the Pilates hours web tracker on Oct 27, 2026.
/// Each store adds it once on first launch after this update; your later edits are kept.
// WHAT: Your data from the web tracker, added once on first launch (hours, students, course progress).
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

// MARK: - Move styles (more than classical: teach it all)
// WHAT: Teaching styles used to filter the Library (Classical, Contemporary, Props, Barre...).
// TO CHANGE: Add a style: add a case AND its label below.
enum MoveStyle: String, Codable, CaseIterable {
    case classical, contemporary, props, barre, sculpt, mobility, prenatal, standing

    var label: String {
        switch self {
        case .classical: "Classical Mat"
        case .contemporary: "Contemporary Mat"
        case .props: "Props"
        case .barre: "Barre"
        case .sculpt: "Sculpt"
        case .mobility: "Stretch & Mobility"
        case .prenatal: "Prenatal & Gentle"
        case .standing: "Standing Balance"
        }
    }
}

extension LibraryMoveSet {
    /// Every built-in move: the Level I classical set plus all the styles below.
    static var all: [LibraryMove] { levelIMat + moreStyles + NoProps.moves }

    /// Classical, contemporary, props, barre, sculpt, mobility, prenatal and standing moves.
    /// Prenatal moves: clear with a provider; avoid long periods flat on the back after the first trimester.
    // TO CHANGE: add a move by copying one line and editing it. Each line: name, area, props, reps, seconds, cue, buildingBlock, modification, style.
    static let moreStyles: [LibraryMove] = [
        LibraryMove(id: UUID(uuidString: "5a41930a-3075-55eb-871a-fba3cabd9b0f")!, name: "Single Straight Leg Stretch", area: .core, props: [], reps: "8 each leg", seconds: 60, cue: "Head up, scissor the straight legs, double pulse toward you. Hips heavy and still.", buildingBlock: "Bend the bottom knee, foot on the mat.", modification: "Neck strain: head down. Tight hamstrings: hold behind the calf.", style: .classical),
        LibraryMove(id: UUID(uuidString: "2d29471d-6f40-57d8-b47b-4e3ac6bbe67f")!, name: "Double Straight Leg Stretch", area: .core, props: [], reps: "6–8", seconds: 60, cue: "Hands behind the head, legs to the ceiling. Lower only as far as the back stays imprinted, lift with control.", buildingBlock: "Smaller range, legs higher.", modification: "Low back pain: bend the knees or keep legs high.", style: .classical),
        LibraryMove(id: UUID(uuidString: "d8d5755a-f740-54f5-8c6f-e14ea669f69f")!, name: "Criss Cross", area: .core, props: [], reps: "6 each side", seconds: 60, cue: "Elbows wide, rotate the ribs toward the bent knee, hold, switch. Turn from the waist, not the elbow.", buildingBlock: "Feet on the mat, rotate the upper body only.", modification: "Osteoporosis: skip loaded rotation; do Chest Lift instead.", style: .classical),
        LibraryMove(id: UUID(uuidString: "a78ca5a0-421e-5a6d-92b4-dcd49d75b890")!, name: "Open Leg Rocker", area: .core, props: [], reps: "6", seconds: 60, cue: "Balance behind the sit bones holding the ankles, legs in a V. Scoop, roll back to the shoulder blades, roll up and balance.", buildingBlock: "Hold behind the knees, knees bent; balance only.", modification: "Neck or back issues, osteoporosis: balance only, no rolling.", style: .classical),
        LibraryMove(id: UUID(uuidString: "21a62e5d-1c00-589b-8946-cccece07980a")!, name: "Corkscrew", area: .core, props: [], reps: "3 each way", seconds: 60, cue: "Legs to the ceiling, circle them as one: side, down, around, up. Shoulders stay heavy.", buildingBlock: "Smaller circle; hips stay on the mat.", modification: "Low back pain: tiny circles with knees bent.", style: .classical),
        LibraryMove(id: UUID(uuidString: "7aa7c29a-8582-5eab-81ba-3068be11a8ec")!, name: "Saw", area: .stretch, props: [], reps: "4 each side", seconds: 60, cue: "Sit tall, legs wide, arms out. Twist, then reach the little finger past the little toe, sawing three times. Roll up tall.", buildingBlock: "Bend the knees; reach toward the shin.", modification: "Osteoporosis: twist with a flat back, no forward flexion.", style: .classical),
        LibraryMove(id: UUID(uuidString: "8c825392-4f76-52eb-aed9-7cf3d6dcba12")!, name: "Swan Prep", area: .stretch, props: [], reps: "4–5", seconds: 60, cue: "Hands under the shoulders. Lift the chest with the upper back, belly scooped, shoulders away from the ears.", buildingBlock: "Forearms down, small lift.", modification: "Low back pain: keep it small; pubic bone heavy.", style: .classical),
        LibraryMove(id: UUID(uuidString: "e84d8e4e-a2c2-5eee-b5de-fe45992a3f00")!, name: "Single Leg Kick", area: .glutes, props: [], reps: "6 each leg", seconds: 60, cue: "Propped on forearms, belly lifted. Kick the heel to the seat twice, then lengthen the leg down.", buildingBlock: "Forehead on the hands, small kicks.", modification: "Low back pain: forehead down, keep the belly lifted.", style: .classical),
        LibraryMove(id: UUID(uuidString: "a7c41704-d272-58a2-9fd0-d9b3abbbaa76")!, name: "Double Leg Kick", area: .stretch, props: [], reps: "3 each side", seconds: 75, cue: "Cheek on the mat, hands clasped high on the back. Kick both heels three times, then reach the hands back and lift the chest.", buildingBlock: "Forearms down, skip the chest lift.", modification: "Shoulder pain: arms long by the sides.", style: .classical),
        LibraryMove(id: UUID(uuidString: "7e2ce6c7-dadb-5756-9e9c-4cfb33075cb8")!, name: "Neck Pull", area: .core, props: [], reps: "4–5", seconds: 75, cue: "Hands behind the head, legs long. Curl up, round over, stack up tall, then roll down one bone at a time.", buildingBlock: "Bend the knees; hold behind the thighs.", modification: "Neck strain or osteoporosis: replace with Roll Up prep.", style: .classical),
        LibraryMove(id: UUID(uuidString: "f959284a-c558-5d89-aec7-0d5b0dcffcdb")!, name: "Side Kick Front/Back", area: .glutes, props: [], reps: "8 each side", seconds: 60, cue: "Lying on the side, legs slightly forward. Kick front with a double pulse, sweep back long. Waist lifted, hips stacked.", buildingBlock: "Bend the bottom knee for balance.", modification: "Hip pain: smaller range.", style: .classical),
        LibraryMove(id: UUID(uuidString: "eea32395-dc81-59a5-add2-0558c404a331")!, name: "Side Kick Up/Down", area: .glutes, props: [], reps: "6 each side", seconds: 45, cue: "Turn the top leg out, kick up, lower with resistance.", buildingBlock: "Smaller lift.", modification: "Hip pain: keep the leg parallel.", style: .classical),
        LibraryMove(id: UUID(uuidString: "73c110b8-bd4e-59fb-a162-2b424462f1b9")!, name: "Teaser Prep", area: .core, props: [], reps: "4", seconds: 60, cue: "Knees bent, feet down, arms reach. Roll up to a V balance, hold, roll down with control.", buildingBlock: "One leg extended, the other foot down.", modification: "Low back or osteoporosis: hold a small lift only.", style: .classical),
        LibraryMove(id: UUID(uuidString: "31aee3ea-f21d-5a63-8e7a-0000d6563f70")!, name: "Teaser", area: .core, props: [], reps: "3", seconds: 60, cue: "From lying, roll up into a V, arms parallel to the legs. Balance, then roll down bone by bone.", buildingBlock: "Teaser Prep with knees bent.", modification: "Low back pain or osteoporosis: skip; do Teaser Prep.", style: .classical),
        LibraryMove(id: UUID(uuidString: "f6ffc10b-5ffc-542b-acc2-16658bff62cf")!, name: "Seal", area: .core, props: [], reps: "6", seconds: 45, cue: "Balance behind the sit bones, hands through to the ankles. Clap the feet 3 times, roll back, roll up and clap.", buildingBlock: "Rock without the claps.", modification: "Neck or back issues, osteoporosis: skip and hold the balance.", style: .classical),
        LibraryMove(id: UUID(uuidString: "fae22428-d1b7-562c-9bc3-83b27da1058a")!, name: "Swimming", area: .glutes, props: [], reps: "20–30 counts", seconds: 45, cue: "On the stomach, reach long and lift arms and legs. Flutter opposite arm and leg, breathing in for 5 and out for 5.", buildingBlock: "Arms only, or legs only.", modification: "Low back pain: on hands and knees (Bird Dog).", style: .classical),
        LibraryMove(id: UUID(uuidString: "dd7e5700-dcd2-5914-9a0d-ac506ee536da")!, name: "Leg Pull Front", area: .core, props: [], reps: "3 each leg", seconds: 60, cue: "Plank on hands. Lift one leg, press back through the heel, lower.", buildingBlock: "Plank hold on the knees.", modification: "Wrist pain: on the forearms.", style: .classical),
        LibraryMove(id: UUID(uuidString: "f8dc2ffd-fb15-5b97-8634-874fc315875b")!, name: "Leg Pull Back", area: .glutes, props: [], reps: "3 each leg", seconds: 60, cue: "Reverse plank, fingers toward the feet. Kick one leg up, lower long.", buildingBlock: "Reverse tabletop with knees bent.", modification: "Wrist or shoulder pain: skip; do Shoulder Bridge.", style: .classical),
        LibraryMove(id: UUID(uuidString: "ad100684-3b53-5e41-a5c0-5a2a3c9335f8")!, name: "Side Bend", area: .core, props: [], reps: "3 each side", seconds: 60, cue: "Side plank on the hand, top arm arcs overhead as the hips lift high, then lower to sit.", buildingBlock: "Bottom knee down, lift the hips.", modification: "Wrist or shoulder pain: on the forearm.", style: .classical),
        LibraryMove(id: UUID(uuidString: "d758b89a-45cd-5ead-a7d6-4d37e8df4808")!, name: "Spine Twist", area: .stretch, props: [], reps: "3 each side", seconds: 45, cue: "Sit tall, legs together, feet flexed, arms out. Twist with a double pulse, return to center growing taller.", buildingBlock: "Sit on a block, knees bent.", modification: "Osteoporosis: small, gentle range.", style: .classical),
        LibraryMove(id: UUID(uuidString: "73ac810e-3272-5582-95e9-74d4d9cc2af4")!, name: "Shoulder Bridge", area: .glutes, props: [], reps: "6–8", seconds: 60, cue: "Feet hip-width. Peel the spine up, squeeze the seat, roll down bone by bone.", buildingBlock: "Small lift and hold.", modification: "Neck issues: keep the lift low.", style: .classical),
        LibraryMove(id: UUID(uuidString: "d85b8b7e-473d-5c45-98e8-1b06d38aad8a")!, name: "Pilates Push-Up", area: .arms, props: [], reps: "3 sets of 3", seconds: 60, cue: "Roll down to a plank, three push-ups with elbows hugging in, walk back and roll up.", buildingBlock: "Push-ups on the knees.", modification: "Wrist pain: on the fists or against the wall.", style: .classical),
        LibraryMove(id: UUID(uuidString: "11b177e2-60c4-5a5b-88d5-8f9ca0268840")!, name: "Pelvic Curl", area: .warmup, props: [], reps: "6", seconds: 60, cue: "Exhale, tilt the pelvis and peel the spine up one bone at a time; inhale at the top; exhale to roll down.", buildingBlock: "Tilt the pelvis only.", modification: "Neck issues: keep the lift to the shoulder blades.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "2c3fd943-3cc1-55da-9b71-6ea0e63b7daa")!, name: "Chest Lift", area: .core, props: [], reps: "8", seconds: 45, cue: "Hands behind the head, exhale and curl the head and shoulders up, ribs soften toward the hips.", buildingBlock: "Hands supporting the head, small curl.", modification: "Neck strain: head down, breathe into the ribs.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "fb4e3375-9003-59eb-b424-407311dabc1d")!, name: "Chest Lift with Rotation", area: .core, props: [], reps: "6 each side", seconds: 60, cue: "Curl up, rotate the ribs toward one knee, back to center, lower.", buildingBlock: "Rotate the head and shoulders only.", modification: "Osteoporosis: skip rotation.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "83076691-0076-5253-9bce-698224859662")!, name: "Toe Taps", area: .core, props: [], reps: "8 each leg", seconds: 45, cue: "Legs in tabletop, back imprinted. Lower one toe to tap the mat, lift back.", buildingBlock: "Keep the knee bent and the range small.", modification: "Low back pain: one leg stays down.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "54f1e7f9-e8b2-585d-b57b-5391fecbfee7")!, name: "Dead Bug", area: .core, props: [], reps: "8 each side", seconds: 60, cue: "Arms to the ceiling, legs in tabletop. Reach the opposite arm and leg long, back stays heavy.", buildingBlock: "Arms only or legs only.", modification: "Low back pain: smaller reach.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "53df8d6c-a556-5765-b103-42494b7989ad")!, name: "Bird Dog", area: .core, props: [], reps: "8 each side", seconds: 60, cue: "Hands under shoulders, knees under hips. Reach the opposite arm and leg long; belly lifts to the spine.", buildingBlock: "Arms only, or legs only.", modification: "Wrist pain: on the fists or forearms.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "b4146986-b4fb-5fec-b949-f6f285f89529")!, name: "Forearm Plank", area: .core, props: [], reps: "3 × 20 sec", seconds: 60, cue: "Elbows under shoulders, long line from head to heels, belly lifted.", buildingBlock: "Knees down.", modification: "Shoulder pain: plank on the hands, or on the knees.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "978a7103-9050-5597-8413-ebf44d93332c")!, name: "Side Plank (knee)", area: .core, props: [], reps: "20 sec each side", seconds: 60, cue: "Forearm and bottom knee down, lift the hips into one long line.", buildingBlock: "Lower the hips and lift again.", modification: "Shoulder pain: lying side-lying leg lifts instead.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "763e5a21-22ea-57d3-9228-29e2b7dec889")!, name: "Clamshell", area: .glutes, props: [], reps: "10 each side", seconds: 60, cue: "Knees bent, heels in line with the seat, hips stacked. Open the top knee, keep the heels together.", buildingBlock: "Smaller opening.", modification: "Hip pain: smaller range.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "f8240e5f-3fea-57bb-a540-34ed1b104d9b")!, name: "Inner Thigh Lift", area: .glutes, props: [], reps: "10 each side", seconds: 45, cue: "Top foot on the floor in front, lift and lower the bottom leg.", buildingBlock: "Smaller lift.", modification: "Hip pain: place a block under the top knee.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "33b989b9-e5ca-5ee3-9bb4-6503a1cb11ca")!, name: "Windshield Wipers", area: .core, props: [], reps: "6 each side", seconds: 45, cue: "Knees in tabletop, arms wide. Lower both knees to one side, bring them back with the abs.", buildingBlock: "Feet on the mat.", modification: "Low back pain: small range.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "09e82b8d-d364-52d1-825d-088fa57ed953")!, name: "Cat & Cow", area: .stretch, props: [], reps: "5", seconds: 45, cue: "Hands under shoulders, knees under hips. Inhale lift the tail and head; exhale curl the tail under.", buildingBlock: "Smaller movement.", modification: "Wrist pain: on the fists or forearms.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "dca87494-3359-54ad-86b7-00872c96b44e")!, name: "Thread the Needle", area: .stretch, props: [], reps: "3 each side", seconds: 60, cue: "On hands and knees, reach one arm under the body, shoulder toward the mat; reach back up to open.", buildingBlock: "Smaller reach.", modification: "Shoulder pain: stay with the open reach only.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "997100a9-78ae-569c-bc9c-1168c70ad8e3")!, name: "Mermaid", area: .stretch, props: [], reps: "3 each side", seconds: 60, cue: "Sit in a Z, one hand down, the other arm arcs overhead into a side bend. Breathe into the open ribs.", buildingBlock: "Sit cross-legged or on a block.", modification: "Knee pain: sit cross-legged.", style: .contemporary),
        LibraryMove(id: UUID(uuidString: "d3d621b9-deee-50d8-9cc9-50ca79207cfa")!, name: "Band Pull-Apart", area: .arms, props: ["Stretch band"], reps: "10", seconds: 45, cue: "Arms at chest height, pull the band apart squeezing the shoulder blades, return slowly.", buildingBlock: "Lighter band, smaller range.", modification: "Shoulder pain: keep elbows bent.", style: .props),
        LibraryMove(id: UUID(uuidString: "62a41f07-daa3-51a6-8a7d-e75fe7a0a6ce")!, name: "Seated Band Row", area: .arms, props: ["Stretch band"], reps: "10", seconds: 45, cue: "Band around the feet, sit tall. Pull the elbows back past the ribs, shoulders down.", buildingBlock: "Bend the knees; sit on a block.", modification: "Low back pain: sit on a block.", style: .props),
        LibraryMove(id: UUID(uuidString: "23162f60-6519-5813-91a8-b027bb64b1f9")!, name: "Band Leg Press", area: .glutes, props: ["Stretch band"], reps: "10 each leg", seconds: 60, cue: "On your back, band around one foot. Press the leg long against the band, bend back in with control.", buildingBlock: "Lighter tension.", modification: "Knee pain: smaller range.", style: .props),
        LibraryMove(id: UUID(uuidString: "49bca567-9ab6-5f9e-8a45-e5288a81895d")!, name: "Band Hamstring Stretch", area: .stretch, props: ["Stretch band"], reps: "30 sec each leg", seconds: 60, cue: "On your back, band around the foot, leg to the ceiling. Breathe and soften the hip.", buildingBlock: "Bend the bottom knee.", modification: "Sciatica: gentler range.", style: .props),
        LibraryMove(id: UUID(uuidString: "db3ed1f3-6258-5450-b258-1a9bc3e6bae0")!, name: "Kneeling Overhead Press", area: .arms, props: ["Dumbbells"], reps: "8", seconds: 45, cue: "Tall kneel, ribs knit together, press overhead. Abs in so the back doesn't arch.", buildingBlock: "No weights, or one arm at a time.", modification: "Knee pain: seated or standing.", style: .props),
        LibraryMove(id: UUID(uuidString: "248b09a6-8a24-5db2-bdb7-7218551ab142")!, name: "Bicep Curl", area: .arms, props: ["Dumbbells"], reps: "10", seconds: 45, cue: "Elbows glued to the ribs, curl up for 2, down for 3.", buildingBlock: "Lighter weights.", modification: "Wrist pain: palms facing in.", style: .props),
        LibraryMove(id: UUID(uuidString: "f02c5106-2ee6-52c0-9c62-5332c41deb02")!, name: "Triceps Kickback", area: .arms, props: ["Dumbbells"], reps: "10", seconds: 45, cue: "Hinge forward with a long spine, elbows high, straighten the arms back.", buildingBlock: "One arm at a time, the other hand on the thigh.", modification: "Low back pain: stand tall and do overhead triceps instead.", style: .props),
        LibraryMove(id: UUID(uuidString: "95b7e18d-c540-50ad-b4cc-c73cf932e64b")!, name: "Hug a Tree", area: .arms, props: ["Dumbbells"], reps: "8", seconds: 45, cue: "Arms in a wide circle, close them in front as if hugging a tree, open with control.", buildingBlock: "No weights.", modification: "Shoulder pain: smaller circle.", style: .props),
        LibraryMove(id: UUID(uuidString: "95e641a2-1066-525d-b6d9-207297eb487f")!, name: "Dumbbell Deadlift", area: .glutes, props: ["Dumbbells"], reps: "10", seconds: 60, cue: "Hinge from the hips with a long spine, weights slide down the legs, squeeze the seat to stand.", buildingBlock: "Bodyweight hinge, hands on the thighs.", modification: "Low back pain: smaller hinge.", style: .props),
        LibraryMove(id: UUID(uuidString: "7a73f5a4-589f-5484-be20-4ae6533b0d32")!, name: "Chest Press in Bridge", area: .glutes, props: ["Dumbbells"], reps: "8", seconds: 60, cue: "Hold the bridge, press the weights to the ceiling and lower the elbows to the mat.", buildingBlock: "Hips down.", modification: "Neck issues: hips down.", style: .props),
        LibraryMove(id: UUID(uuidString: "039f52ae-00ac-5804-92e4-211a16f5e8de")!, name: "Arm Circles", area: .arms, props: ["Wrist weights"], reps: "10 each way", seconds: 45, cue: "Arms out at shoulder height, small circles forward then back. Shoulders stay down.", buildingBlock: "No weights, smaller circles.", modification: "Shoulder pain: arms lower.", style: .props),
        LibraryMove(id: UUID(uuidString: "76656c73-3607-53f9-8500-c75630d7015b")!, name: "Arm Series: Front Raise", area: .arms, props: ["Wrist weights"], reps: "10", seconds: 45, cue: "Stand tall, lift straight arms to shoulder height and lower slowly.", buildingBlock: "One arm at a time.", modification: "Shoulder pain: lift to chest height only.", style: .props),
        LibraryMove(id: UUID(uuidString: "b174e3b1-330a-5105-b1c6-415c2b66a714")!, name: "Side-Lying Leg Lift with Wrist Weight", area: .glutes, props: ["Wrist weights"], reps: "10 each side", seconds: 60, cue: "Wrist weight on the ankle, hips stacked, lift and lower the top leg.", buildingBlock: "No weight.", modification: "Hip pain: smaller lift.", style: .props),
        LibraryMove(id: UUID(uuidString: "ed65b3b7-4051-554a-a85d-8658617e97c0")!, name: "Banded Clamshell", area: .glutes, props: ["Thigh band"], reps: "12 each side", seconds: 60, cue: "Band above the knees, hips stacked, open the top knee against the band.", buildingBlock: "No band.", modification: "Hip pain: lighter band.", style: .props),
        LibraryMove(id: UUID(uuidString: "3ebfbc9f-507f-5b20-9c04-a952fc13b021")!, name: "Banded Glute Bridge", area: .glutes, props: ["Thigh band"], reps: "10", seconds: 60, cue: "Band above the knees, lift the hips and press the knees out against the band.", buildingBlock: "Small lift.", modification: "Neck issues: keep the lift low.", style: .props),
        LibraryMove(id: UUID(uuidString: "35224582-25da-5c98-8e70-87902761be74")!, name: "Lateral Band Walk", area: .glutes, props: ["Thigh band"], reps: "10 steps each way", seconds: 60, cue: "Band above the knees, mini squat, step side to side keeping the tension.", buildingBlock: "Taller squat, smaller steps.", modification: "Knee pain: band above the knees, stay taller.", style: .props),
        LibraryMove(id: UUID(uuidString: "2e9abb99-7d14-50fd-8cb8-01e0c4a169c4")!, name: "Banded Fire Hydrant", area: .glutes, props: ["Thigh band"], reps: "10 each side", seconds: 60, cue: "On hands and knees, lift the knee out to the side against the band, back flat.", buildingBlock: "No band.", modification: "Wrist pain: on the forearms.", style: .props),
        LibraryMove(id: UUID(uuidString: "027069ba-35e0-5e2f-a38b-17a21739eb8d")!, name: "Bridge with Block Squeeze", area: .glutes, props: ["Yoga block"], reps: "10", seconds: 60, cue: "Block between the thighs, squeeze as you roll up and down.", buildingBlock: "Small lift.", modification: "Neck issues: keep the lift low.", style: .props),
        LibraryMove(id: UUID(uuidString: "8760e7df-6439-56f4-9701-24a8e864dac5")!, name: "Supported Bridge", area: .stretch, props: ["Yoga block"], reps: "5 breaths", seconds: 60, cue: "Lift the hips, slide the block under the sacrum, rest and breathe.", buildingBlock: "Block on its lowest height.", modification: "Low back pain: lowest height, knees bent.", style: .props),
        LibraryMove(id: UUID(uuidString: "b220757b-e678-5673-a7bb-dd50e9cfc433")!, name: "Squat with Block Squeeze", area: .glutes, props: ["Yoga block"], reps: "10", seconds: 45, cue: "Block between the thighs, sit back and press through the heels to stand.", buildingBlock: "Squat to a chair.", modification: "Knee pain: shallower squat.", style: .props),
        LibraryMove(id: UUID(uuidString: "75e7648a-ffdd-5c62-8ae9-508f1ab9bd6e")!, name: "Hundred with Ball Squeeze", area: .core, props: ["Pilates ball"], reps: "100 pumps", seconds: 60, cue: "Ball between the knees; squeeze to find the inner thighs while you pump.", buildingBlock: "Tabletop, head down.", modification: "Neck strain: head down.", style: .props),
        LibraryMove(id: UUID(uuidString: "f32b3218-f2be-5963-820f-9378bcd44d22")!, name: "Ball Roll Back", area: .core, props: ["Pilates ball"], reps: "8", seconds: 45, cue: "Ball behind the low back, curl back into it in a C-Curve, sit tall.", buildingBlock: "Smaller roll back.", modification: "Osteoporosis: sit tall and breathe into the ball.", style: .props),
        LibraryMove(id: UUID(uuidString: "247cc15b-b327-59b2-96b7-37a2bfa84328")!, name: "Bridge with Ball Squeeze", area: .glutes, props: ["Pilates ball"], reps: "10", seconds: 60, cue: "Ball between the knees, squeeze as you roll up one bone at a time.", buildingBlock: "Small lift and hold.", modification: "Neck issues: keep the lift low.", style: .props),
        LibraryMove(id: UUID(uuidString: "fa76686f-dde7-521d-93e0-14032903dd7d")!, name: "V-Sit Ball Pass", area: .core, props: ["Pilates ball"], reps: "8", seconds: 45, cue: "Balance on the sit bones, pass the ball around the knees.", buildingBlock: "Hands behind the thighs, hold only.", modification: "Low back pain: feet on the mat.", style: .props),
        LibraryMove(id: UUID(uuidString: "32a7678e-c4d2-53a8-ace7-b6b908ff2825")!, name: "Ring Inner Thigh Squeeze", area: .glutes, props: ["Pilates ring"], reps: "15", seconds: 45, cue: "Ring between the ankles or knees, squeeze and release slowly.", buildingBlock: "Ring between the knees, smaller squeeze.", modification: "Knee pain: ring above the knees.", style: .props),
        LibraryMove(id: UUID(uuidString: "69c9e353-fcaa-5b47-955c-ed287c7ac79f")!, name: "Ring Chest Press", area: .arms, props: ["Pilates ring"], reps: "12", seconds: 45, cue: "Ring between the palms at chest height, press in and release with control.", buildingBlock: "Lighter press.", modification: "Wrist pain: press with the forearms.", style: .props),
        LibraryMove(id: UUID(uuidString: "781ee5ab-c93a-547a-b82c-2634c3b558df")!, name: "Plié", area: .glutes, props: ["Chair"], reps: "10", seconds: 45, cue: "Heels together, toes turned out, hand on the chair. Bend the knees over the toes, stand tall.", buildingBlock: "Smaller bend.", modification: "Knee pain: parallel feet, small bend.", style: .barre),
        LibraryMove(id: UUID(uuidString: "c6032c27-fbed-58d8-b2db-e196358ce366")!, name: "Plié Pulses", area: .glutes, props: ["Chair"], reps: "20", seconds: 45, cue: "Hold the low plié and pulse an inch up and down, tailbone long.", buildingBlock: "Higher plié.", modification: "Knee pain: parallel feet.", style: .barre),
        LibraryMove(id: UUID(uuidString: "2246407d-45b4-56e9-99c5-38e62bfd51e0")!, name: "Relevé", area: .glutes, props: ["Chair"], reps: "12", seconds: 45, cue: "Rise onto the balls of the feet, lower with control. Ankles stay straight.", buildingBlock: "Both hands on the chair.", modification: "Ankle pain: smaller rise.", style: .barre),
        LibraryMove(id: UUID(uuidString: "e9391002-2f39-5b8f-88bf-986e6a819469")!, name: "Arabesque Lift", area: .glutes, props: ["Chair"], reps: "12 each leg", seconds: 60, cue: "Hinge slightly forward, lift the straight leg back from the seat, lower with control.", buildingBlock: "Toe taps on the floor.", modification: "Low back pain: smaller lift, stay upright.", style: .barre),
        LibraryMove(id: UUID(uuidString: "2559f813-cfbd-5441-bba2-c754cca9082c")!, name: "Attitude Lift", area: .glutes, props: ["Chair"], reps: "12 each leg", seconds: 45, cue: "Knee bent and turned out behind you, lift and lower from the seat.", buildingBlock: "Smaller lift.", modification: "Hip pain: parallel leg.", style: .barre),
        LibraryMove(id: UUID(uuidString: "9fda2166-bbf1-52d4-b47e-2227bbf44fc5")!, name: "Curtsy Lunge", area: .glutes, props: ["Chair"], reps: "8 each side", seconds: 60, cue: "Step one foot back and across, bend both knees, press through the front heel to stand.", buildingBlock: "Hold the chair, shallow lunge.", modification: "Knee pain: straight reverse lunge.", style: .barre),
        LibraryMove(id: UUID(uuidString: "6ab6971c-3a07-5919-b0f8-00ad1c0cba9c")!, name: "Standing Side Leg Lift", area: .glutes, props: ["Chair"], reps: "12 each leg", seconds: 45, cue: "Stand tall, lift the straight leg to the side, hips level.", buildingBlock: "Smaller lift.", modification: "Hip pain: hold the chair with both hands.", style: .barre),
        LibraryMove(id: UUID(uuidString: "679dfff5-80f9-52fe-a9da-9e489e9b4d81")!, name: "Chair Pose Pulses", area: .glutes, props: [], reps: "20", seconds: 45, cue: "Feet together, sit back as if into a chair, arms reach, pulse.", buildingBlock: "Feet hip-width.", modification: "Knee pain: higher squat.", style: .barre),
        LibraryMove(id: UUID(uuidString: "c26d68d5-ec58-58b6-922c-4922df072fa1")!, name: "Bodyweight Squat", area: .glutes, props: [], reps: "12", seconds: 45, cue: "Feet hip-width, sit back, knees over toes, press through the heels and squeeze at the top.", buildingBlock: "Squat to a chair.", modification: "Knee pain: shallower squat.", style: .sculpt),
        LibraryMove(id: UUID(uuidString: "e1212f92-8cfa-5a17-9c0a-808c3bc9acba")!, name: "Reverse Lunge", area: .glutes, props: [], reps: "8 each leg", seconds: 60, cue: "Step back, lower both knees to 90°, push through the front heel to stand.", buildingBlock: "Hold a chair, shallow lunge.", modification: "Knee pain: smaller step, shallow bend.", style: .sculpt),
        LibraryMove(id: UUID(uuidString: "c34987d7-f1df-52ea-8d02-7051ff44d874")!, name: "Glute Bridge March", area: .glutes, props: [], reps: "8 each leg", seconds: 45, cue: "Hold the bridge and lift one foot at a time without the hips dropping.", buildingBlock: "Hips down, alternate toe lifts.", modification: "Low back pain: lower bridge.", style: .sculpt),
        LibraryMove(id: UUID(uuidString: "56bfce5d-55d9-56aa-a41d-05633cb12dba")!, name: "Plank Shoulder Taps", area: .core, props: [], reps: "10 each side", seconds: 45, cue: "Plank on the hands, feet wide. Tap the opposite shoulder without rocking the hips.", buildingBlock: "Knees down.", modification: "Wrist pain: forearm plank hold.", style: .sculpt),
        LibraryMove(id: UUID(uuidString: "b1c3ca80-6045-58df-91e1-b61d4fb2a0ee")!, name: "Slow Mountain Climbers", area: .core, props: [], reps: "10 each leg", seconds: 45, cue: "Plank, draw one knee toward the chest, return. Slow and controlled.", buildingBlock: "Hands on a bench or chair.", modification: "Wrist pain: hands on a chair.", style: .sculpt),
        LibraryMove(id: UUID(uuidString: "0e681840-91c5-5e32-9678-daaf008bdf20")!, name: "Skater Step", area: .glutes, props: [], reps: "10 each side", seconds: 45, cue: "Step wide to the side, sweep the back leg behind, low and controlled.", buildingBlock: "Step and tap, no hop.", modification: "Knee pain: smaller step.", style: .sculpt),
        LibraryMove(id: UUID(uuidString: "27a411a1-82a0-5699-8e3a-0dda0554a0b7")!, name: "Squat to Calf Raise", area: .glutes, props: ["Dumbbells"], reps: "10", seconds: 45, cue: "Squat, stand, rise onto the toes, lower.", buildingBlock: "No weights, hold a chair.", modification: "Ankle pain: skip the raise.", style: .sculpt),
        LibraryMove(id: UUID(uuidString: "aa08f3fb-a843-5063-9689-4328d4792f46")!, name: "Bent-Over Row", area: .arms, props: ["Dumbbells"], reps: "10", seconds: 45, cue: "Hinge forward with a long spine, row the elbows back past the ribs.", buildingBlock: "One arm with a hand on a chair.", modification: "Low back pain: one-arm row with support.", style: .sculpt),
        LibraryMove(id: UUID(uuidString: "ff3becfa-9647-5951-aea6-a5f12d4e36fc")!, name: "Figure-4 Glute Stretch", area: .stretch, props: [], reps: "30 sec each side", seconds: 60, cue: "Ankle over knee, breathe into the hip. Draw the legs in for more.", buildingBlock: "Keep the bottom foot on the floor.", modification: "Knee pain: ankle lower on the thigh.", style: .mobility),
        LibraryMove(id: UUID(uuidString: "99b10cd2-ae53-5c7e-9099-504c70deb116")!, name: "Child's Pose", area: .stretch, props: [], reps: "5 breaths", seconds: 45, cue: "Knees wide, sit back toward the heels, arms long, breathe into the back.", buildingBlock: "Pillow or block under the hips.", modification: "Knee pain: tabletop and rock back gently.", style: .mobility),
        LibraryMove(id: UUID(uuidString: "8bb2219f-c0e0-54f3-982b-2e5b196a0942")!, name: "Low Lunge Hip Flexor Stretch", area: .stretch, props: [], reps: "30 sec each side", seconds: 60, cue: "Back knee down, tuck the tail, shift forward until the front of the hip opens.", buildingBlock: "Hands on blocks.", modification: "Knee pain: pad under the knee.", style: .mobility),
        LibraryMove(id: UUID(uuidString: "7b87a71f-daa8-58ba-9ba8-b981773a68b6")!, name: "Chest Opener", area: .stretch, props: ["Yoga block"], reps: "5 breaths", seconds: 45, cue: "Block under the upper back, arms wide, breathe into the chest.", buildingBlock: "Block on its lowest height.", modification: "Shoulder pain: arms lower.", style: .mobility),
        LibraryMove(id: UUID(uuidString: "8d942fdf-06bd-58b5-9843-b2de8f9344c4")!, name: "Standing Roll Down", area: .stretch, props: [], reps: "3", seconds: 45, cue: "Chin to chest, roll down one bone at a time, knees soft, roll back up.", buildingBlock: "Hands slide down the thighs.", modification: "Osteoporosis: hinge with a flat back instead.", style: .mobility),
        LibraryMove(id: UUID(uuidString: "f83fd871-bcc2-5938-b182-7f107f3e2a1d")!, name: "Seated Side Bend", area: .stretch, props: [], reps: "3 each side", seconds: 45, cue: "Sit cross-legged, one hand down, arc the other arm overhead.", buildingBlock: "Hand on the head.", modification: "Hip pain: sit on a block.", style: .mobility),
        LibraryMove(id: UUID(uuidString: "5c39469a-7967-5a21-9b96-75ff9752657e")!, name: "Neck & Shoulder Release", area: .warmup, props: [], reps: "5 each", seconds: 45, cue: "Shoulder rolls back, then ear toward shoulder with slow breaths.", buildingBlock: "Smaller range.", modification: "Neck pain: tiny range only.", style: .mobility),
        LibraryMove(id: UUID(uuidString: "70b1d847-87a2-57bd-9cae-f744a009f8f9")!, name: "Supine Spinal Twist", area: .stretch, props: [], reps: "30 sec each side", seconds: 60, cue: "Knees fall to one side, arms wide, breathe into the twist.", buildingBlock: "Pillow under the knees.", modification: "Osteoporosis: small range, knees supported.", style: .mobility),
        LibraryMove(id: UUID(uuidString: "c6a11deb-71a9-5cac-a9be-21293864b89b")!, name: "Seated Breathing & Pelvic Floor", area: .warmup, props: ["Pilates ball"], reps: "8 breaths", seconds: 60, cue: "Sit on the ball or a chair. Inhale wide into the ribs; exhale, gently lift the pelvic floor.", buildingBlock: "Sit on a chair.", modification: "Any discomfort: breathe only.", style: .prenatal),
        LibraryMove(id: UUID(uuidString: "752ef507-3370-53c6-9ee0-5836e49b7c86")!, name: "Seated Ball Hip Circles", area: .warmup, props: ["Pilates ball"], reps: "8 each way", seconds: 45, cue: "Sit tall on the ball, circle the hips slowly.", buildingBlock: "Sit on a chair and tilt the pelvis.", modification: "Dizziness: hold a wall.", style: .prenatal),
        LibraryMove(id: UUID(uuidString: "89a959bf-f31a-508e-be17-9cc133658e99")!, name: "Quadruped Arm Reach", area: .core, props: [], reps: "6 each side", seconds: 45, cue: "Hands and knees, belly hugs baby, reach one arm forward.", buildingBlock: "Stay still and breathe.", modification: "Wrist pain: on the fists.", style: .prenatal),
        LibraryMove(id: UUID(uuidString: "3e84fa86-740a-542f-b277-9eac67dfdd33")!, name: "Wall Push-Up", area: .arms, props: [], reps: "10", seconds: 45, cue: "Hands on the wall, body in one line, bend and press.", buildingBlock: "Feet closer to the wall.", modification: "Wrist pain: forearms on the wall.", style: .prenatal),
        LibraryMove(id: UUID(uuidString: "96e7134c-a2f3-5683-9801-975908021c51")!, name: "Supported Squat", area: .glutes, props: ["Chair"], reps: "8", seconds: 45, cue: "Hold the chair, wide stance, sit back slowly and stand.", buildingBlock: "Shallow range.", modification: "Pelvic pain: narrow stance, small range.", style: .prenatal),
        LibraryMove(id: UUID(uuidString: "0495b7f2-3364-5fbb-bf59-3a9242b68f55")!, name: "Side-Lying Leg Lift (pillow)", area: .glutes, props: [], reps: "10 each side", seconds: 60, cue: "Pillow under the belly and between the knees, lift the top leg.", buildingBlock: "Smaller lift.", modification: "Pelvic pain: keep the knees together.", style: .prenatal),
        LibraryMove(id: UUID(uuidString: "ba729793-caf7-5cb5-ae49-2d117b32503d")!, name: "Standing Footwork", area: .warmup, props: [], reps: "10", seconds: 45, cue: "Stand tall, rise to the toes, lower; then heels lift alternately.", buildingBlock: "Hold a chair.", modification: "Ankle pain: small rise.", style: .standing),
        LibraryMove(id: UUID(uuidString: "5ce7bb24-43fa-5aa1-900b-926d8e78ce80")!, name: "Single-Leg Balance", area: .core, props: [], reps: "30 sec each side", seconds: 60, cue: "Stand on one leg, belly lifted, eyes on a fixed point. Add a slow arm reach.", buildingBlock: "Toe touching the floor.", modification: "Balance issues: hold a chair.", style: .standing),
        LibraryMove(id: UUID(uuidString: "449afd8d-9657-5b4d-8830-b9e8039ddf29")!, name: "Standing Knee Lift with Twist", area: .core, props: [], reps: "8 each side", seconds: 45, cue: "Lift one knee, rotate the ribs toward it, lower.", buildingBlock: "No twist.", modification: "Low back pain: no twist.", style: .standing)
    ]
}

// MARK: - Layers and sides

// WHAT: "Layer up" options: harder versions of each move, easiest first, shown under Modification on the phone and watch.
//       A move's own Layers text (written in the builder or Library) wins; otherwise this list is used.
// TO CHANGE: edit the text after a move's name. Use → between layers. Names are lower case; left/right are ignored.
enum MoveLayers {
    static func lookup(_ name: String) -> String {
        byName[MoveNames.key(name)] ?? ""
    }

    static let byName: [String: String] = [
        "the hundred": "Legs in tabletop → legs long at 45° → lower the legs as long as the back stays down.",
        "hundred": "Legs in tabletop → legs long at 45° → lower the legs as long as the back stays down.",
        "roll up": "Arms overhead to start → slower 5-count roll down → hold the flat-back reach at the top.",
        "single leg circles": "Bigger circles → bottom leg long on the mat → pause at the top of each circle.",
        "rolling like a ball": "Heels closer to the seat → hold the balance 2 counts → hands off, arms reach forward.",
        "single leg stretch": "Lower the straight leg → quicker tempo, torso still → classical hand placement (ankle and knee).",
        "double leg stretch": "Arms by the ears → legs lower toward 45° → hold 2 counts at full reach.",
        "spine stretch forward": "Arms start overhead → 3 pulses forward → roll up with arms still reaching.",
        "single straight leg stretch": "Lower the bottom leg → hands off the leg → quick double pulse.",
        "double straight leg stretch": "Lower toward 45° → down in 3 counts, up in 1 → hover just above the mat.",
        "criss cross": "Legs lower → hold each twist 3 counts → slower tempo, longer exhale.",
        "open leg rocker": "Straight legs in a V → hold the V 3 counts → full roll with no momentum.",
        "corkscrew": "Bigger circles → slower 5-count circles → hips lift with each circle (advanced).",
        "saw": "Deeper reach, 3 saws → hold the twist a breath → arms long on the roll up.",
        "swan prep": "Hands hover at the top → lift higher through the upper back → Swan Rock (advanced).",
        "single leg kick": "Knees lift off the mat → crisper double kick → hips lifted between kicks.",
        "double leg kick": "Legs lift as you reach back → hold the reach 3 counts → hands off the back, arms long.",
        "neck pull": "Feet flexed, legs together → slower 5-count roll down → hinge back with a flat spine.",
        "side kick front/back": "Top hand behind the head → double kick forward → bottom leg hovers (advanced).",
        "side kick: front and back": "Top hand behind the head → double kick forward → bottom leg hovers (advanced).",
        "side kick up/down": "Lower in 3 counts → pulse at the top → lift the bottom leg to meet it.",
        "teaser prep": "One leg long → both legs in tabletop → arms reach overhead at the top.",
        "teaser": "Hold at the top 3 breaths → arms overhead → lower legs and torso together.",
        "seal": "Clap 3 times at each end → hold the balance 2 counts → slower roll.",
        "swimming": "Faster flutter, torso still → chest and legs higher → hold the lift 5 breaths.",
        "leg pull front": "Lift each leg 3 times → hold plank 5 breaths between → add a push-up.",
        "leg pull back": "Pointed then flexed foot → hold the lift 3 breaths → dip and lift the hips.",
        "side bend": "Full side plank → reach overhead → twist down and back (advanced).",
        "spine twist": "Pulse 3 times each side → arms long and wide → slower 5-count return.",
        "shoulder bridge": "One leg lifted → kick the leg up and lower → hold the top 3 breaths.",
        "pilates push-up": "From the toes → lower in 3 counts → roll down from standing each rep.",
        "pelvic curl": "Hold the top 3 breaths → lift one heel → march in bridge.",
        "chest lift": "Hold the top and pulse → legs in tabletop → hands behind the head, longer hold.",
        "chest lift with rotation": "Legs in tabletop → hold each twist 3 counts → extend one leg with the twist.",
        "toe taps": "Tap farther from the hips → legs straighter → double toe taps.",
        "dead bug": "Straight-leg reach → ball between hand and knee → slower 4-count reach.",
        "dead bug with ball": "Straight-leg reach → ball between hand and knee → slower 4-count reach.",
        "bird dog": "Hold the reach 3 breaths → elbow to knee under the body → knees hover.",
        "bird dogs": "Hold the reach 3 breaths → elbow to knee under the body → knees hover.",
        "forearm plank": "Hold longer → lift one leg → rock forward and back.",
        "forearm plank hold": "Hold longer → lift one leg → rock forward and back.",
        "side plank (knee)": "Straight legs → lift the top leg → thread the top arm through.",
        "clamshell": "Hips lift off the mat → pulse at the top → add a thigh band.",
        "side-lying clamshells": "Hips lift off the mat → pulse at the top → add a thigh band.",
        "inner thigh lift": "Pulses at the top → small circles → ankle or wrist weight.",
        "windshield wipers": "Straight legs → bigger range → hold low 2 counts each side.",
        "cat & cow": "Hip circles → flow to Child's Pose and back → reach opposite arm and leg.",
        "thread the needle": "Reach to the ceiling first → hold 3 breaths → bind behind the back.",
        "mermaid": "Twist to face the mat → hover the bottom hand → side plank lift (advanced).",
        "band pull-apart": "Shorter grip → hold open 3 counts → overhead pull-apart.",
        "seated band row": "Shorter band → hold the squeeze 3 counts → one arm at a time.",
        "band leg press": "Shorter band → slow 4-count press → leg circles in the band.",
        "band hamstring stretch": "Straighten the bottom leg → open the leg out to the side → cross over the body.",
        "kneeling overhead press": "Heavier weights → half-kneeling lunge → add a twist at the top.",
        "kneeling shoulder presses": "Heavier weights → half-kneeling lunge → add a twist at the top.",
        "kneeling shoulder press to tricep dip": "Heavier weights → slower dip (3 counts) → half-kneeling lunge.",
        "bicep curl": "Lower in 4 counts → hold at 90° and pulse → curl in a squat hold.",
        "triceps kickback": "Hold at the top 2 counts → pulses → one arm in a lunge.",
        "hug a tree": "Heavier weights → pulse in the hug → half-kneeling lunge.",
        "dumbbell deadlift": "Heavier weights → lower in 4 counts → single-leg deadlift.",
        "chest press in bridge": "Higher bridge → alternate arms → single-leg bridge.",
        "chest squeeze": "Hold the squeeze 5 counts → pulses → in a chest lift.",
        "arm circles": "Bigger circles → reverse direction → hold arms out 30 seconds.",
        "arm series: front raise": "Lower in 4 counts → pulse at shoulder height → alternate arms.",
        "side-lying leg lift with wrist weight": "Pulses at the top → circles → bottom leg lifts too.",
        "banded clamshell": "Hips lifted → hold open 3 counts → tighter band.",
        "banded glute bridge": "Pulses at the top → knees open-close at the top → single leg.",
        "lateral band walk": "Lower squat → band at the ankles → pulse each step.",
        "banded fire hydrant": "Pulses at the top → kick the leg out straight → hold 3 counts.",
        "fire hydrants": "Pulses at the top → kick the leg out straight → add a thigh band.",
        "fire hydrants with frog kicks": "Slower kicks → pulse at the top → add a thigh band.",
        "bridge with block squeeze": "Pulses at the top → march → single leg.",
        "bridge with block": "Pulses at the top → march → single leg.",
        "supported bridge": "Lift one leg → circle the leg → both legs up (shoulder stand prep).",
        "squat with block squeeze": "Pulse at the bottom → add a heel lift → hold low 20 seconds.",
        "squats with block squeeze": "Pulse at the bottom → add a heel lift → hold low 20 seconds.",
        "hundred with ball squeeze": "Legs long at 45° → lower the legs → hold the squeeze the whole time.",
        "ball roll back": "Roll farther back → add a twist → arms overhead.",
        "bridge with ball squeeze": "Squeeze pulses at the top → march → single leg.",
        "v-sit ball pass": "Straighter legs → lower down between passes → hold the V 3 breaths.",
        "ring inner thigh squeeze": "Hold 5 counts → in a bridge → in a V-sit.",
        "ring chest press": "Pulses → press overhead → in a chest lift.",
        "plié": "Heels lifted → pulse low → arms overhead.",
        "plié pulses": "Heels lifted → smaller, lower pulses → hold 20 seconds at the end.",
        "relevé": "One hand off the chair → single leg → lower in 4 counts.",
        "arabesque lift": "Hold at the top 3 counts → pulses → standing heel lifted.",
        "attitude lift": "Pulse at the top → hold → standing heel lifted.",
        "curtsy lunge": "Pulse at the bottom → no hands → knee lift between reps.",
        "standing side leg lift": "Pulse at the top → no hands → circles.",
        "chair pose pulses": "Heels lifted → hold 20 seconds → add a twist.",
        "bodyweight squat": "Pulse at the bottom → lower in 4 counts → heel lift at the top.",
        "squats": "Pulse at the bottom → lower in 4 counts → heel lift at the top.",
        "squats with toe lifts": "Lower squat → hold the low squat → add dumbbells.",
        "reverse lunge": "Pulse at the bottom → knee drive up → hold dumbbells.",
        "glute bridge march": "Slower march → straight-leg march → arms reach up.",
        "plank shoulder taps": "Feet closer → slower taps → push-up every 4 taps.",
        "crossover elbow taps": "Slower taps → hold each tap 2 counts → from the toes.",
        "slow mountain climbers": "Quicker tempo → knee to opposite elbow → hold each knee 2 counts.",
        "walkouts": "Add a push-up → shoulder taps in plank → walk farther out.",
        "skater step": "Lower and wider → small hop → touch the floor.",
        "squat to calf raise": "Heavier weights → pause at the top → pulse in the squat.",
        "bent-over row": "Heavier weights → one arm at a time → pause at the top.",
        "v-ups on glute": "Straighter legs → slower lowering → hands off the mat.",
        "side-lying leg lifts": "Pulses at the top → circles → add a ball or ankle weight.",
        "side-lying leg lift circles + pulse": "Bigger circles → slower pulses → ankle weight.",
        "side-lying leg lifts with ball": "Lift the ball higher → pulse → hold 3 counts at the top.",
        "figure-4 glute stretch": "Pull the bottom knee closer → straighten the bottom leg → seated figure-4.",
        "child's pose": "Walk hands to one side → wide knees → thread an arm through.",
        "low lunge hip flexor stretch": "Arms overhead → side bend → hold the back foot (quad stretch).",
        "chest opener": "Higher block → arms wide → longer hold, slow breaths.",
        "standing roll down": "Bend the knees at the bottom → walk out to plank → roll up onto the toes.",
        "roll down & 2 breaths": "Bend the knees at the bottom → walk out to plank → roll up onto the toes.",
        "seated side bend": "Reach farther → add a twist → hold 3 breaths.",
        "neck & shoulder release": "Hand on the head for gentle weight → shoulder rolls → chin to chest.",
        "supine spinal twist": "Straighten the top leg → arms in cactus → hold 5 breaths.",
        "seated breathing & pelvic floor": "Longer exhale → add a pelvic floor lift → add arms.",
        "breathing": "Longer exhale → 3D rib breath (back and sides) → add a pelvic floor lift.",
        "3 breaths": "Longer exhale → 3D rib breath (back and sides) → add a pelvic floor lift.",
        "imprint & iso-abs": "Hold 5 breaths → lift one foot → tabletop legs.",
        "seated ball hip circles": "Bigger circles → figure eights → arms overhead.",
        "quadruped arm reach": "Add the opposite leg → hold 3 breaths → add a band.",
        "wall push-up": "Feet farther from the wall → slower lowering → one arm (advanced).",
        "supported squat": "Lower → hold 20 seconds → heel lift.",
        "side-lying leg lift (pillow)": "Pulses → circles → ankle weight.",
        "standing footwork": "Heels lifted → slower → single leg.",
        "single-leg balance": "Eyes closed → arms overhead → extend the lifted leg.",
        "standing knee lift with twist": "Hold the knee lift → quicker tempo → add weights.",
    ]
}

// WHAT: Moves taught one side at a time (right side first, then left). The builder turns these on automatically.
// TO CHANGE: add a move's lower-case name to the list.
enum Sidedness {
    static func isOneSided(_ name: String) -> Bool {
        let key = MoveNames.key(name)
        return names.contains(key) || key.contains("side-lying") || key.contains("clamshell") || key.contains("fire hydrant")
    }

    static let names: Set<String> = [
        "supine leg press", "supine hamstring stretch", "freestanding arabesque lift", "freestanding attitude lift",
        "curtsy lunge (no chair)", "freestanding side leg lift",
        "arabesque lift",
        "attitude lift",
        "band hamstring stretch",
        "band leg press",
        "banded clamshell",
        "banded fire hydrant",
        "clamshell",
        "curtsy lunge",
        "figure-4 glute stretch",
        "fire hydrants",
        "fire hydrants with frog kicks",
        "inner thigh lift",
        "low lunge hip flexor stretch",
        "mermaid",
        "seated side bend",
        "side bend",
        "side kick front/back",
        "side kick up/down",
        "side kick: front and back",
        "side plank (knee)",
        "side-lying clamshells",
        "side-lying leg lift (pillow)",
        "side-lying leg lift circles + pulse",
        "side-lying leg lift with wrist weight",
        "side-lying leg lifts",
        "side-lying leg lifts with ball",
        "single leg circles",
        "single-leg balance",
        "squats with toe lifts",
        "standing side leg lift",
        "thread the needle",
        "v-ups on glute",
    ]
}

// WHAT: Matches a move name to the lists above: lower case, without (right)/(left) or the words right/left.
enum MoveNames {
    static func key(_ name: String) -> String {
        var s = name.lowercased()
        for token in ["(right)", "(left)", "(r)", "(l)", " r/l", "right ", "left "] {
            s = s.replacingOccurrences(of: token, with: "")
        }
        return s.split(separator: " ").joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
}

extension PilatesClassItem {
    /// Layer-up options for this move: its own text, or the built-in list.
    var displayLayers: String {
        let own = layers.trimmingCharacters(in: .whitespacesAndNewlines)
        return own.isEmpty ? MoveLayers.lookup(name) : own
    }
}

extension LibraryMove {
    /// Layer-up options for this Library move: its own text, or the built-in list.
    var displayLayers: String {
        let own = (layers ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return own.isEmpty ? MoveLayers.lookup(name) : own
    }
}

// MARK: - No-props versions

// WHAT: A mat-only version of every move that uses a band, weights, ball, block, ring or chair.
//       New mat-only moves are added to the Library; the builder can swap a whole class to them.
// TO CHANGE: edit a move line in `moves`, or which version a prop move swaps to in `swaps` (lower-case prop move name → no-prop move name).
enum NoProps {
    static let moves: [LibraryMove] = [
        LibraryMove(id: UUID(uuidString: "3f30295d-86cc-5388-be0d-9c6fe9f24154")!, name: "Arm Pull-Apart (no band)", area: .arms, props: [], reps: "", seconds: 60, cue: "Arms long at shoulder height, palms down. Open wide as if stretching a band, squeeze the shoulder blades, return slowly.", buildingBlock: "Smaller range, hands at chest height.", modification: "Shoulder pain: keep elbows soft and the range small.", style: .contemporary, layers: "Thumbs up → pulse when open → hold open 20 seconds."),
        LibraryMove(id: UUID(uuidString: "654f8bea-e03e-5897-b624-45a6ba71ea54")!, name: "Seated Row (no band)", area: .arms, props: [], reps: "", seconds: 60, cue: "Sit tall, arms reach forward. Pull the elbows back past the ribs and squeeze the shoulder blades; reach forward slowly.", buildingBlock: "Sit on a folded mat; one arm at a time.", modification: "Low back pain: sit on a folded mat with knees bent.", style: .contemporary, layers: "Hold the squeeze 3 counts → lean back slightly → pulse at the back."),
        LibraryMove(id: UUID(uuidString: "ab6159f1-1376-58be-941b-08006517181c")!, name: "Supine Leg Press", area: .glutes, props: [], reps: "", seconds: 60, cue: "On your back, knee to chest, foot flexed. Press the heel up and out to 45° like pushing into a wall, then draw it back in. Pelvis stays still.", buildingBlock: "Press toward the ceiling instead of 45°.", modification: "Low back pain: keep the other foot down and knee bent.", style: .contemporary, layers: "Lower angle → slow 4-count press → leg circles at full press."),
        LibraryMove(id: UUID(uuidString: "a8e1eb4f-4658-5eb5-bb17-03bcd106117b")!, name: "Supine Hamstring Stretch", area: .stretch, props: [], reps: "", seconds: 60, cue: "On your back, hold behind the thigh or calf and draw the straight leg toward you. Other leg long or knee bent. Breathe and soften.", buildingBlock: "Hold behind the thigh with the knee bent.", modification: "Tight hamstrings or back pain: bend the bottom knee, foot on the mat.", style: .mobility, layers: "Straighten the bottom leg → open the leg to the side → cross it over the body."),
        LibraryMove(id: UUID(uuidString: "8efa0acd-a533-56ac-b559-7551510c9357")!, name: "Kneeling Overhead Press (no weights)", area: .arms, props: [], reps: "", seconds: 60, cue: "Kneel tall, fists at shoulders. Press up as if pushing something heavy, ribs down; lower slowly with the same effort.", buildingBlock: "Sit on the heels.", modification: "Knee pain: stand or sit on a folded mat.", style: .contemporary, layers: "Slower 4-count lowering → half-kneeling lunge → pulse at the top."),
        LibraryMove(id: UUID(uuidString: "d7247eb1-f902-554c-a281-5e4f624574d4")!, name: "Tension Bicep Curl", area: .arms, props: [], reps: "", seconds: 60, cue: "Make fists and curl as if lifting something heavy: squeeze hard on the way up, resist on the way down.", buildingBlock: "One arm at a time; press the other palm against the fist for resistance.", modification: "Wrist or elbow pain: smaller range, open hands.", style: .sculpt, layers: "Hold at 90° and pulse → slow 4-count lowering → curl in a squat hold."),
        LibraryMove(id: UUID(uuidString: "95e1fd3c-882f-56b6-b4c4-48fadba7d3f3")!, name: "Bodyweight Triceps Kickback", area: .arms, props: [], reps: "", seconds: 60, cue: "Hinge forward, elbows high by the ribs. Straighten the arms back, palms up, squeeze the back of the arms; bend slowly.", buildingBlock: "Stand taller; smaller hinge.", modification: "Low back: kneel on all fours and do one arm at a time.", style: .sculpt, layers: "Hold straight 2 counts → pulses at the top → in a lunge."),
        LibraryMove(id: UUID(uuidString: "a000da18-3bdf-54c8-a0bd-f9c36aa270bc")!, name: "Hug a Tree (no weights)", area: .arms, props: [], reps: "", seconds: 60, cue: "Arms in a wide circle at chest height, elbows soft. Close as if hugging a big tree, open with control. Shoulders down.", buildingBlock: "Smaller circle.", modification: "Shoulder pain: lower the arms below shoulder height.", style: .contemporary, layers: "Pulse in the hug → hold 20 seconds → half-kneeling lunge."),
        LibraryMove(id: UUID(uuidString: "db4b42b8-ea3a-501a-8775-13a17dd0129f")!, name: "Bodyweight Hinge", area: .glutes, props: [], reps: "", seconds: 60, cue: "Feet hip-width, soft knees. Slide the hands down the thighs as the hips reach back, flat back; squeeze the glutes to stand.", buildingBlock: "Hands on the hips, smaller hinge.", modification: "Low back pain: smaller range, hands on the thighs.", style: .sculpt, layers: "Slow 4-count lower → single-leg hinge → hold at the bottom."),
        LibraryMove(id: UUID(uuidString: "c15a61f7-24ee-5f79-a17a-c4b2c819cae7")!, name: "Bridge with Arm Reach", area: .glutes, props: [], reps: "", seconds: 60, cue: "Lift to bridge. Arms reach to the ceiling, then open wide and close, hips steady.", buildingBlock: "Arms stay on the mat.", modification: "Neck or back pain: lower bridge.", style: .contemporary, layers: "Higher bridge → march one foot → single-leg bridge."),
        LibraryMove(id: UUID(uuidString: "8d88e712-996c-549b-a451-a7d10a739778")!, name: "Arm Circles (no weights)", area: .arms, props: [], reps: "", seconds: 60, cue: "Arms out to the sides at shoulder height. Small circles forward, then back. Shoulders down, fingertips long.", buildingBlock: "Smaller circles, arms slightly lower.", modification: "Shoulder pain: arms lower, take breaks.", style: .barre, layers: "Bigger circles → pulse up and down → hold 30 seconds."),
        LibraryMove(id: UUID(uuidString: "42765e93-89bc-5d30-8a2c-788f0e97bfe0")!, name: "Front Raise (no weights)", area: .arms, props: [], reps: "", seconds: 60, cue: "Fists or open hands. Lift the arms to shoulder height in front, lower in 3 counts. Ribs stay down.", buildingBlock: "One arm at a time.", modification: "Shoulder pain: lift only to chest height.", style: .barre, layers: "Slow 4-count lowering → pulse at shoulder height → alternate arms."),
        LibraryMove(id: UUID(uuidString: "167edd1f-7436-584c-93c5-86c02e3884f8")!, name: "Side-Lying Leg Lift", area: .glutes, props: [], reps: "", seconds: 60, cue: "Lie on your side, legs long and stacked. Lift the top leg to hip height and lower with control. Hips stacked, waist long.", buildingBlock: "Bend the bottom knee for balance.", modification: "Hip pain: smaller lift; pillow between the knees between sets.", style: .contemporary, layers: "Pulses at the top → circles → bottom leg lifts too."),
        LibraryMove(id: UUID(uuidString: "d2ebc863-521a-5688-ba49-db5982492b6a")!, name: "Glute Bridge", area: .glutes, props: [], reps: "", seconds: 60, cue: "Feet hip-width, close to the seat. Press through the heels and squeeze the glutes to lift; lower slowly.", buildingBlock: "Smaller lift.", modification: "Neck: keep weight on the shoulders, not the neck. Knee pain: feet farther away.", style: .sculpt, layers: "Pulses at the top → hold 3 breaths → single leg."),
        LibraryMove(id: UUID(uuidString: "33ae049e-5f10-522c-a63e-abc6e57024f4")!, name: "Lateral Squat Walk", area: .glutes, props: [], reps: "", seconds: 60, cue: "Sit into a quarter squat. Step out to the side and follow, staying low. Knees press out.", buildingBlock: "Higher squat, smaller steps.", modification: "Knee pain: stay taller.", style: .sculpt, layers: "Lower squat → wider steps → pulse each step."),
        LibraryMove(id: UUID(uuidString: "c00940e1-c5dd-56c9-ab42-9204a201ed0e")!, name: "Fire Hydrant", area: .glutes, props: [], reps: "", seconds: 60, cue: "On all fours, knees under hips. Lift one bent knee out to the side to hip height, keep the hips level, lower slowly.", buildingBlock: "Smaller lift.", modification: "Wrists: forearms down. Knees: fold the mat.", style: .contemporary, layers: "Pulses at the top → kick the leg straight out → hold 3 counts."),
        LibraryMove(id: UUID(uuidString: "2817aefe-7337-53b7-8b0a-e4e97a3fb655")!, name: "Bridge with Inner Thigh Squeeze", area: .glutes, props: [], reps: "", seconds: 60, cue: "Feet and knees together. Squeeze the inner thighs as if holding a block, lift to bridge, keep the squeeze down.", buildingBlock: "Smaller lift.", modification: "Back or knee pain: smaller lift, feet hip-width.", style: .contemporary, layers: "Pulses at the top → march → single leg."),
        LibraryMove(id: UUID(uuidString: "5f2bb3aa-25e9-50a3-9932-0f734e64a35d")!, name: "Knees-to-Chest Rock", area: .stretch, props: [], reps: "", seconds: 60, cue: "On your back, hug the knees in. Rock gently side to side and breathe into the low back.", buildingBlock: "One knee at a time.", modification: "Knee pain: hold behind the thighs.", style: .mobility, layers: "Slow circles → add a gentle hug and release → Happy Baby."),
        LibraryMove(id: UUID(uuidString: "72bdab2a-831e-5757-8ecf-b88b02abeefc")!, name: "Narrow Squat", area: .glutes, props: [], reps: "", seconds: 60, cue: "Feet and knees close. Sit back into a squat squeezing the knees together, chest tall; press up.", buildingBlock: "Smaller range.", modification: "Knee pain: shallower squat.", style: .sculpt, layers: "Pulse at the bottom → heel lift → hold low 20 seconds."),
        LibraryMove(id: UUID(uuidString: "71cd7e8d-370a-599e-85a9-4fed14917066")!, name: "Roll Back", area: .core, props: [], reps: "", seconds: 60, cue: "Sit tall, knees bent, hands behind the thighs. Curl the tailbone under and roll halfway back, hold, then return.", buildingBlock: "Smaller roll.", modification: "Back pain: tiny range, hold the thighs firmly.", style: .contemporary, layers: "Arms reach forward → add a twist → arms overhead."),
        LibraryMove(id: UUID(uuidString: "8103bef3-51a3-51ab-9846-f73cc3938116")!, name: "Prayer Press", area: .arms, props: [], reps: "", seconds: 60, cue: "Palms pressed together at the chest, elbows wide. Press hard, push the hands forward and back keeping the press.", buildingBlock: "Hold the press in one place.", modification: "Wrist pain: press with fists.", style: .contemporary, layers: "Pulses → press overhead → in a chest lift."),
        LibraryMove(id: UUID(uuidString: "8d1c8217-f2b0-5b04-b61e-29aae752a323")!, name: "Clasped Chest Opener", area: .stretch, props: [], reps: "", seconds: 60, cue: "Clasp the hands behind the back (or hold the elbows). Lift the chest and draw the shoulder blades together. Breathe.", buildingBlock: "Hold the opposite elbows.", modification: "Shoulder pain: hands on the low back.", style: .mobility, layers: "Lift the clasped hands → fold forward with arms up → longer hold."),
        LibraryMove(id: UUID(uuidString: "41f60d14-5e66-5142-b894-05ff95f51628")!, name: "Freestanding Plié", area: .glutes, props: [], reps: "", seconds: 60, cue: "Heels together, toes out, hands on hips or arms in second. Bend the knees over the toes, lengthen up. No chair.", buildingBlock: "Smaller bend.", modification: "Knee pain: less turnout, smaller bend.", style: .barre, layers: "Heels lifted → pulse low → arms overhead."),
        LibraryMove(id: UUID(uuidString: "0f1496ed-6807-56aa-861f-714deddb338d")!, name: "Freestanding Plié Pulses", area: .glutes, props: [], reps: "", seconds: 60, cue: "Wide plié, hands on hips. Lower and pulse an inch up and down, chest tall. No chair.", buildingBlock: "Higher position.", modification: "Knee pain: less turnout, higher pulses.", style: .barre, layers: "Heels lifted → lower pulses → hold 20 seconds at the end."),
        LibraryMove(id: UUID(uuidString: "3e2a5b65-5aae-5f7e-824e-ed926f2b0c1a")!, name: "Freestanding Relevé", area: .glutes, props: [], reps: "", seconds: 60, cue: "Feet parallel, hands on hips. Rise to the balls of the feet, lower in 3 counts. No chair.", buildingBlock: "Hand on the wall or a partner.", modification: "Ankle or balance issues: stand near a wall.", style: .barre, layers: "Arms overhead → single leg → hold at the top."),
        LibraryMove(id: UUID(uuidString: "b587f7bd-0a76-5c19-9a52-37c2ace85b20")!, name: "Freestanding Arabesque Lift", area: .glutes, props: [], reps: "", seconds: 60, cue: "Hinge forward slightly, hands on hips. Lift the straight leg back from the glute, lower. Hips square. No chair.", buildingBlock: "Toe stays on the floor; small lift.", modification: "Low back: smaller lift, hinge less.", style: .barre, layers: "Hold at the top 3 counts → pulses → standing heel lifted."),
        LibraryMove(id: UUID(uuidString: "7d946d91-6ace-5ac9-9596-9776d59a2e4e")!, name: "Freestanding Attitude Lift", area: .glutes, props: [], reps: "", seconds: 60, cue: "Hands on hips. Bent knee lifts behind and out to the side, lower with control. No chair.", buildingBlock: "Smaller lift.", modification: "Balance: stand near a wall.", style: .barre, layers: "Pulse at the top → hold → standing heel lifted."),
        LibraryMove(id: UUID(uuidString: "ece3405d-1cb0-5eb4-84fd-908fd279160d")!, name: "Curtsy Lunge (no chair)", area: .glutes, props: [], reps: "", seconds: 60, cue: "Hands on hips. Step back and across into a curtsy, front knee over the ankle, press up. No chair.", buildingBlock: "Smaller step, tap only.", modification: "Knee pain: shallow range.", style: .barre, layers: "Pulse at the bottom → knee lift between reps → hold low."),
        LibraryMove(id: UUID(uuidString: "d1a2746a-683e-5927-8abf-6a87ca220f09")!, name: "Freestanding Side Leg Lift", area: .glutes, props: [], reps: "", seconds: 60, cue: "Hands on hips, standing tall. Lift the straight leg to the side without leaning, lower slowly. No chair.", buildingBlock: "Smaller lift.", modification: "Balance: stand near a wall.", style: .barre, layers: "Pulse at the top → circles → hold at the top."),
        LibraryMove(id: UUID(uuidString: "0ef09084-6be2-59d9-95b8-95f9bef67435")!, name: "Squat to Calf Raise (no weights)", area: .glutes, props: [], reps: "", seconds: 60, cue: "Squat, press up, and rise onto the toes; lower the heels and sit back again. Arms forward for balance.", buildingBlock: "Skip the calf raise.", modification: "Knee pain: shallower squat.", style: .sculpt, layers: "Pause at the top → pulse in the squat → slow 4-count lowering."),
        LibraryMove(id: UUID(uuidString: "1478aa34-eeca-5df4-a355-8031d89a0d96")!, name: "Bent-Over Row (no weights)", area: .arms, props: [], reps: "", seconds: 60, cue: "Hinge forward, flat back, fists reaching down. Row the elbows back past the ribs, squeeze, lower slowly.", buildingBlock: "Smaller hinge.", modification: "Low back: hands on thighs, one arm at a time.", style: .sculpt, layers: "Pause at the top → pulses → one arm at a time."),
        LibraryMove(id: UUID(uuidString: "7be95aee-f61a-5a9f-be39-ca22acf0c245")!, name: "Cross-Legged Breathing & Pelvic Floor", area: .warmup, props: [], reps: "", seconds: 60, cue: "Sit tall cross-legged on a folded mat. Breathe wide into the ribs; on the exhale gently lift the pelvic floor, release on the inhale.", buildingBlock: "Sit against a wall.", modification: "Hip or knee pain: sit on a folded mat with legs out.", style: .prenatal, layers: "Longer exhale → hold the lift 3 counts → add arms."),
        LibraryMove(id: UUID(uuidString: "83df3a8f-ae74-5d13-9f2f-67c8d365ce02")!, name: "Standing Hip Circles", area: .warmup, props: [], reps: "", seconds: 60, cue: "Feet hip-width, hands on hips. Circle the hips slowly one way, then the other.", buildingBlock: "Smaller circles.", modification: "Balance: hand on a wall.", style: .prenatal, layers: "Bigger circles → figure eights → arms overhead."),
        LibraryMove(id: UUID(uuidString: "9f3e6cc3-07fb-53c5-8ccb-4ba4f96280cd")!, name: "Wide Squat Hold", area: .glutes, props: [], reps: "", seconds: 60, cue: "Wide stance, toes out, hands at the heart. Sit into a comfortable squat and breathe; press up slowly.", buildingBlock: "Higher squat; hand on a wall.", modification: "Pelvic pain: narrower stance, smaller range.", style: .prenatal, layers: "Lower → hold 20 seconds → heel lift."),
    ]

    static let swaps: [String: String] = [
        "band pull-apart": "Arm Pull-Apart (no band)",
        "seated band row": "Seated Row (no band)",
        "band leg press": "Supine Leg Press",
        "band hamstring stretch": "Supine Hamstring Stretch",
        "kneeling overhead press": "Kneeling Overhead Press (no weights)",
        "kneeling shoulder presses": "Kneeling Overhead Press (no weights)",
        "kneeling shoulder press to tricep dip": "Kneeling Overhead Press (no weights)",
        "bicep curl": "Tension Bicep Curl",
        "triceps kickback": "Bodyweight Triceps Kickback",
        "hug a tree": "Hug a Tree (no weights)",
        "dumbbell deadlift": "Bodyweight Hinge",
        "chest press in bridge": "Bridge with Arm Reach",
        "arm circles": "Arm Circles (no weights)",
        "arm series: front raise": "Front Raise (no weights)",
        "side-lying leg lift with wrist weight": "Side-Lying Leg Lift",
        "side-lying leg lifts with ball": "Side-Lying Leg Lift",
        "banded clamshell": "Clamshell",
        "banded glute bridge": "Glute Bridge",
        "lateral band walk": "Lateral Squat Walk",
        "banded fire hydrant": "Fire Hydrant",
        "bridge with block squeeze": "Bridge with Inner Thigh Squeeze",
        "bridge with block": "Bridge with Inner Thigh Squeeze",
        "bridge with ball squeeze": "Bridge with Inner Thigh Squeeze",
        "supported bridge": "Knees-to-Chest Rock",
        "squat with block squeeze": "Narrow Squat",
        "squats with block squeeze": "Narrow Squat",
        "hundred with ball squeeze": "The Hundred",
        "ball roll back": "Roll Back",
        "dead bug with ball": "Dead Bug",
        "v-sit ball pass": "Teaser Prep",
        "ring inner thigh squeeze": "Inner Thigh Lift",
        "ring chest press": "Prayer Press",
        "chest squeeze": "Prayer Press",
        "chest opener": "Clasped Chest Opener",
        "plié": "Freestanding Plié",
        "plié pulses": "Freestanding Plié Pulses",
        "relevé": "Freestanding Relevé",
        "arabesque lift": "Freestanding Arabesque Lift",
        "attitude lift": "Freestanding Attitude Lift",
        "curtsy lunge": "Curtsy Lunge (no chair)",
        "standing side leg lift": "Freestanding Side Leg Lift",
        "squat to calf raise": "Squat to Calf Raise (no weights)",
        "bent-over row": "Bent-Over Row (no weights)",
        "seated breathing & pelvic floor": "Cross-Legged Breathing & Pelvic Floor",
        "seated ball hip circles": "Standing Hip Circles",
        "supported squat": "Wide Squat Hold",
    ]

    /// The no-prop Library move for a prop move, or nil if the move needs no props (or has no version yet).
    static func version(of name: String) -> LibraryMove? {
        guard let target = swaps[MoveNames.key(name)] else { return nil }
        return LibraryMoveSet.all.first { $0.name == target }
    }
}
