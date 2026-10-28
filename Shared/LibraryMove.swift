import Foundation

// MARK: - Exercise Area (Category)
/// Categories for organizing exercises in the Library.
/// Used to filter and suggest moves based on class focus.
/// ADD new cases here if you want to categorize exercises differently.
enum ExerciseArea: String, Codable, CaseIterable {
    case warmup = "warm-up"
    case arms
    case glutes
    case core
    case stretch

    /// Human-readable label for UI display
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

// MARK: - Library Move
/// An individual exercise in your Library.
/// Each move contains technical details needed for class building:
/// - Cue: what to tell the student
/// - BuildingBlock: the progression or concept to reinforce
/// - Modification: easier alternative if needed
/// - Props: equipment used (band, dumbbells, ball, etc.)
struct LibraryMove: Codable, Identifiable, Hashable {
    // MARK: - Core Fields
    /// Unique identifier
    var id: UUID
    /// Exercise name (e.g., "The Hundred", "Roll Up")
    var name: String
    /// Category for filtering (warm-up, arms, glutes, core, stretch)
    var area: ExerciseArea
    
    // MARK: - Class Details
    /// Equipment used: ["band", "dumbbells", "ball"], etc. Empty = no props needed
    var props: [String]
    /// Repetitions as a string: "10x", "3-5x", "5-10 sets", etc.
    var reps: String
    /// Duration in seconds if timed (0 = use reps instead)
    var seconds: Int
    
    // MARK: - Teaching Guidance
    /// Cue: the exact instruction to give the student during class
    /// Example: "Press your elbows down and lengthen your legs."
    var cue: String
    /// BuildingBlock: the concept or progression being taught
    /// Example: "Chest lift with stable pelvis."
    /// Used in class detail view to show intent and progression
    var buildingBlock: String
    /// Modification: easier version for students who need adjustment
    /// Example: "Feet on mat or hands behind head."
    var modification: String

    init(
        id: UUID = UUID(),
        name: String,
        area: ExerciseArea,
        props: [String] = [],
        reps: String = "",
        seconds: Int = 0,
        cue: String,
        buildingBlock: String,
        modification: String
    ) {
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

// MARK: - Seeded Library Data
/// Pre-built Library moves for Peak Pilates Level I Classical Mat.
/// Used to seed LibraryStore on first launch.
/// MODIFY: Add your own moves here, or add to the app via "Add your own move" form.
enum LibraryMoveSet {
    /// Level I Classical Mat exercises seeded on first launch.
    /// To add more moves: append a new LibraryMove() entry below, or use the app form.
    static let levelIMat: [LibraryMove] = [
        LibraryMove(
            name: "The Hundred",
            area: .warmup,
            reps: "100 pumps",
            cue: "Pump your arms while breathing in for 5 counts, out for 5.",
            buildingBlock: "Chest lift with pumping arms.",
            modification: "Feet on mat or knees bent."
        ),
        LibraryMove(
            name: "Roll Up",
            area: .stretch,
            reps: "3-5x",
            cue: "Articulate one vertebra at a time, stacking up with control.",
            buildingBlock: "Peel the spine off the mat.",
            modification: "Bend knees or use a hold on the back of the thighs."
        ),
        LibraryMove(
            name: "Single Leg Circles",
            area: .core,
            reps: "5-10x",
            cue: "Keep your hips stable and circle only from the hip.",
            buildingBlock: "Stable pelvis while one leg circles.",
            modification: "Smaller circles or hand under glutes for support."
        ),
        LibraryMove(
            name: "Rolling Like a Ball",
            area: .core,
            reps: "5-10 sets",
            cue: "Move as one unit, holding behind the thighs with control.",
            buildingBlock: "Imprint and roll massage the spine.",
            modification: "Small rolls or stay in the ball position."
        ),
        LibraryMove(
            name: "Single Leg Stretch",
            area: .core,
            reps: "5-10x",
            cue: "Lengthen the bottom leg while drawing the knee toward the chest.",
            buildingBlock: "Crunch position with alternating pulls.",
            modification: "Hands behind the head or smaller range."
        ),
        LibraryMove(
            name: "Double Leg Stretch",
            area: .core,
            reps: "3-5x",
            cue: "Circle the arms as you extend the legs, then gather back in.",
            buildingBlock: "Both legs extend while arms circle.",
            modification: "Feet remain on mat or smaller range."
        ),
        LibraryMove(
            name: "Spine Stretch Forward",
            area: .stretch,
            reps: "3-5x",
            cue: "Flex the spine and fold forward with a long spine.",
            buildingBlock: "Seated flexion, stacking vertebrae.",
            modification: "Bent knees or hands on thighs."
        ),
        LibraryMove(
            name: "Criss Cross",
            area: .core,
            reps: "3-5x",
            cue: "Rotate from the upper body while the legs hold steady.",
            buildingBlock: "Oblique rotation with one knee drawing in.",
            modification: "Smaller range or hands behind the head."
        ),
        LibraryMove(
            name: "Open Leg Rocker",
            area: .core,
            reps: "6x",
            cue: "Keep the legs open and rock back with a tight core.",
            buildingBlock: "V-sit rocker position.",
            modification: "Smaller rocks or place one foot down."
        ),
        LibraryMove(
            name: "Corkscrew",
            area: .core,
            reps: "3-5 sets",
            cue: "Circle the hips while the legs stay long and lifted.",
            buildingBlock: "Hip circles with stable shoulders.",
            modification: "Smaller circles or knees bent."
        ),
        LibraryMove(
            name: "Saw",
            area: .stretch,
            reps: "3 sets",
            cue: "Rotate to reach the opposite foot, stacking your ribs.",
            buildingBlock: "Seated rotation with flexion.",
            modification: "Smaller range or hand to own foot."
        ),
        LibraryMove(
            name: "Neck Pull",
            area: .core,
            reps: "5 sets",
            cue: "Hands behind the head; roll down one vertebra at a time.",
            buildingBlock: "Supported roll-down from seated.",
            modification: "Hands across chest or smaller range."
        ),
        LibraryMove(
            name: "Single Leg Kicks",
            area: .glutes,
            reps: "3 sets",
            cue: "Pulse the bottom leg toward the glute while the other leg kicks.",
            buildingBlock: "Prone position, alternating leg kicks.",
            modification: "Smaller pulses or rest on elbows."
        ),
        LibraryMove(
            name: "Double Leg Kicks",
            area: .glutes,
            reps: "5x",
            cue: "Bend both knees toward the glutes, then extend with a chest lift.",
            buildingBlock: "Prone position, both legs kick together.",
            modification: "Smaller kicks or keep forehead down."
        ),
        LibraryMove(
            name: "Side Kick Series - Front/Back",
            area: .glutes,
            reps: "5-10x ea",
            cue: "Pulse the leg forward and back from the hip, stable torso.",
            buildingBlock: "Lying on side, front and back leg pulses.",
            modification: "Smaller range or rest head on arm."
        ),
        LibraryMove(
            name: "Side Kick Series - Up/Down",
            area: .glutes,
            reps: "5-10x ea",
            cue: "Lift and lower the leg, keeping alignment throughout.",
            buildingBlock: "Lying on side, leg lifts up and down.",
            modification: "Smaller range or top leg bent."
        ),
        LibraryMove(
            name: "Teaser",
            area: .core,
            reps: "3x",
            cue: "Balance on the sitting bones and reach the arms and legs.",
            buildingBlock: "V-sit balance position.",
            modification: "Hands stay down or one leg bent."
        ),
        LibraryMove(
            name: "Seal",
            area: .core,
            reps: "6x",
            cue: "Clap your inner thighs as you pulse the chest lift.",
            buildingBlock: "Rounded spine with inner thigh pulses.",
            modification: "Skip the clap or smaller pulses."
        ),
    ]
}
