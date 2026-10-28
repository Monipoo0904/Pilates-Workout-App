"""Generates Shared Swift: NoProps (a mat-only version of every prop move, plus the new Library moves those need)."""
import json, sys, uuid
NS = uuid.UUID('6b1f0c1e-7a52-4c1e-9a7e-5d1c0f00d00d')

# New mat-only moves: name, area, style, cue, buildingBlock (easier step), modification, layers
NEW = [
 ("Arm Pull-Apart (no band)", "arms", "contemporary", "Arms long at shoulder height, palms down. Open wide as if stretching a band, squeeze the shoulder blades, return slowly.", "Smaller range, hands at chest height.", "Shoulder pain: keep elbows soft and the range small.", "Thumbs up → pulse when open → hold open 20 seconds."),
 ("Seated Row (no band)", "arms", "contemporary", "Sit tall, arms reach forward. Pull the elbows back past the ribs and squeeze the shoulder blades; reach forward slowly.", "Sit on a folded mat; one arm at a time.", "Low back pain: sit on a folded mat with knees bent.", "Hold the squeeze 3 counts → lean back slightly → pulse at the back."),
 ("Supine Leg Press", "glutes", "contemporary", "On your back, knee to chest, foot flexed. Press the heel up and out to 45° like pushing into a wall, then draw it back in. Pelvis stays still.", "Press toward the ceiling instead of 45°.", "Low back pain: keep the other foot down and knee bent.", "Lower angle → slow 4-count press → leg circles at full press."),
 ("Supine Hamstring Stretch", "stretch", "mobility", "On your back, hold behind the thigh or calf and draw the straight leg toward you. Other leg long or knee bent. Breathe and soften.", "Hold behind the thigh with the knee bent.", "Tight hamstrings or back pain: bend the bottom knee, foot on the mat.", "Straighten the bottom leg → open the leg to the side → cross it over the body."),
 ("Kneeling Overhead Press (no weights)", "arms", "contemporary", "Kneel tall, fists at shoulders. Press up as if pushing something heavy, ribs down; lower slowly with the same effort.", "Sit on the heels.", "Knee pain: stand or sit on a folded mat.", "Slower 4-count lowering → half-kneeling lunge → pulse at the top."),
 ("Tension Bicep Curl", "arms", "sculpt", "Make fists and curl as if lifting something heavy: squeeze hard on the way up, resist on the way down.", "One arm at a time; press the other palm against the fist for resistance.", "Wrist or elbow pain: smaller range, open hands.", "Hold at 90° and pulse → slow 4-count lowering → curl in a squat hold."),
 ("Bodyweight Triceps Kickback", "arms", "sculpt", "Hinge forward, elbows high by the ribs. Straighten the arms back, palms up, squeeze the back of the arms; bend slowly.", "Stand taller; smaller hinge.", "Low back: kneel on all fours and do one arm at a time.", "Hold straight 2 counts → pulses at the top → in a lunge."),
 ("Hug a Tree (no weights)", "arms", "contemporary", "Arms in a wide circle at chest height, elbows soft. Close as if hugging a big tree, open with control. Shoulders down.", "Smaller circle.", "Shoulder pain: lower the arms below shoulder height.", "Pulse in the hug → hold 20 seconds → half-kneeling lunge."),
 ("Bodyweight Hinge", "glutes", "sculpt", "Feet hip-width, soft knees. Slide the hands down the thighs as the hips reach back, flat back; squeeze the glutes to stand.", "Hands on the hips, smaller hinge.", "Low back pain: smaller range, hands on the thighs.", "Slow 4-count lower → single-leg hinge → hold at the bottom."),
 ("Bridge with Arm Reach", "glutes", "contemporary", "Lift to bridge. Arms reach to the ceiling, then open wide and close, hips steady.", "Arms stay on the mat.", "Neck or back pain: lower bridge.", "Higher bridge → march one foot → single-leg bridge."),
 ("Arm Circles (no weights)", "arms", "barre", "Arms out to the sides at shoulder height. Small circles forward, then back. Shoulders down, fingertips long.", "Smaller circles, arms slightly lower.", "Shoulder pain: arms lower, take breaks.", "Bigger circles → pulse up and down → hold 30 seconds."),
 ("Front Raise (no weights)", "arms", "barre", "Fists or open hands. Lift the arms to shoulder height in front, lower in 3 counts. Ribs stay down.", "One arm at a time.", "Shoulder pain: lift only to chest height.", "Slow 4-count lowering → pulse at shoulder height → alternate arms."),
 ("Side-Lying Leg Lift", "glutes", "contemporary", "Lie on your side, legs long and stacked. Lift the top leg to hip height and lower with control. Hips stacked, waist long.", "Bend the bottom knee for balance.", "Hip pain: smaller lift; pillow between the knees between sets.", "Pulses at the top → circles → bottom leg lifts too."),
 ("Glute Bridge", "glutes", "sculpt", "Feet hip-width, close to the seat. Press through the heels and squeeze the glutes to lift; lower slowly.", "Smaller lift.", "Neck: keep weight on the shoulders, not the neck. Knee pain: feet farther away.", "Pulses at the top → hold 3 breaths → single leg."),
 ("Lateral Squat Walk", "glutes", "sculpt", "Sit into a quarter squat. Step out to the side and follow, staying low. Knees press out.", "Higher squat, smaller steps.", "Knee pain: stay taller.", "Lower squat → wider steps → pulse each step."),
 ("Fire Hydrant", "glutes", "contemporary", "On all fours, knees under hips. Lift one bent knee out to the side to hip height, keep the hips level, lower slowly.", "Smaller lift.", "Wrists: forearms down. Knees: fold the mat.", "Pulses at the top → kick the leg straight out → hold 3 counts."),
 ("Bridge with Inner Thigh Squeeze", "glutes", "contemporary", "Feet and knees together. Squeeze the inner thighs as if holding a block, lift to bridge, keep the squeeze down.", "Smaller lift.", "Back or knee pain: smaller lift, feet hip-width.", "Pulses at the top → march → single leg."),
 ("Knees-to-Chest Rock", "stretch", "mobility", "On your back, hug the knees in. Rock gently side to side and breathe into the low back.", "One knee at a time.", "Knee pain: hold behind the thighs.", "Slow circles → add a gentle hug and release → Happy Baby."),
 ("Narrow Squat", "glutes", "sculpt", "Feet and knees close. Sit back into a squat squeezing the knees together, chest tall; press up.", "Smaller range.", "Knee pain: shallower squat.", "Pulse at the bottom → heel lift → hold low 20 seconds."),
 ("Roll Back", "core", "contemporary", "Sit tall, knees bent, hands behind the thighs. Curl the tailbone under and roll halfway back, hold, then return.", "Smaller roll.", "Back pain: tiny range, hold the thighs firmly.", "Arms reach forward → add a twist → arms overhead."),
 ("Prayer Press", "arms", "contemporary", "Palms pressed together at the chest, elbows wide. Press hard, push the hands forward and back keeping the press.", "Hold the press in one place.", "Wrist pain: press with fists.", "Pulses → press overhead → in a chest lift."),
 ("Clasped Chest Opener", "stretch", "mobility", "Clasp the hands behind the back (or hold the elbows). Lift the chest and draw the shoulder blades together. Breathe.", "Hold the opposite elbows.", "Shoulder pain: hands on the low back.", "Lift the clasped hands → fold forward with arms up → longer hold."),
 ("Freestanding Plié", "glutes", "barre", "Heels together, toes out, hands on hips or arms in second. Bend the knees over the toes, lengthen up. No chair.", "Smaller bend.", "Knee pain: less turnout, smaller bend.", "Heels lifted → pulse low → arms overhead."),
 ("Freestanding Plié Pulses", "glutes", "barre", "Wide plié, hands on hips. Lower and pulse an inch up and down, chest tall. No chair.", "Higher position.", "Knee pain: less turnout, higher pulses.", "Heels lifted → lower pulses → hold 20 seconds at the end."),
 ("Freestanding Relevé", "glutes", "barre", "Feet parallel, hands on hips. Rise to the balls of the feet, lower in 3 counts. No chair.", "Hand on the wall or a partner.", "Ankle or balance issues: stand near a wall.", "Arms overhead → single leg → hold at the top."),
 ("Freestanding Arabesque Lift", "glutes", "barre", "Hinge forward slightly, hands on hips. Lift the straight leg back from the glute, lower. Hips square. No chair.", "Toe stays on the floor; small lift.", "Low back: smaller lift, hinge less.", "Hold at the top 3 counts → pulses → standing heel lifted."),
 ("Freestanding Attitude Lift", "glutes", "barre", "Hands on hips. Bent knee lifts behind and out to the side, lower with control. No chair.", "Smaller lift.", "Balance: stand near a wall.", "Pulse at the top → hold → standing heel lifted."),
 ("Curtsy Lunge (no chair)", "glutes", "barre", "Hands on hips. Step back and across into a curtsy, front knee over the ankle, press up. No chair.", "Smaller step, tap only.", "Knee pain: shallow range.", "Pulse at the bottom → knee lift between reps → hold low."),
 ("Freestanding Side Leg Lift", "glutes", "barre", "Hands on hips, standing tall. Lift the straight leg to the side without leaning, lower slowly. No chair.", "Smaller lift.", "Balance: stand near a wall.", "Pulse at the top → circles → hold at the top."),
 ("Squat to Calf Raise (no weights)", "glutes", "sculpt", "Squat, press up, and rise onto the toes; lower the heels and sit back again. Arms forward for balance.", "Skip the calf raise.", "Knee pain: shallower squat.", "Pause at the top → pulse in the squat → slow 4-count lowering."),
 ("Bent-Over Row (no weights)", "arms", "sculpt", "Hinge forward, flat back, fists reaching down. Row the elbows back past the ribs, squeeze, lower slowly.", "Smaller hinge.", "Low back: hands on thighs, one arm at a time.", "Pause at the top → pulses → one arm at a time."),
 ("Cross-Legged Breathing & Pelvic Floor", "warmup", "prenatal", "Sit tall cross-legged on a folded mat. Breathe wide into the ribs; on the exhale gently lift the pelvic floor, release on the inhale.", "Sit against a wall.", "Hip or knee pain: sit on a folded mat with legs out.", "Longer exhale → hold the lift 3 counts → add arms."),
 ("Standing Hip Circles", "warmup", "prenatal", "Feet hip-width, hands on hips. Circle the hips slowly one way, then the other.", "Smaller circles.", "Balance: hand on a wall.", "Bigger circles → figure eights → arms overhead."),
 ("Wide Squat Hold", "glutes", "prenatal", "Wide stance, toes out, hands at the heart. Sit into a comfortable squat and breathe; press up slowly.", "Higher squat; hand on a wall.", "Pelvic pain: narrower stance, smaller range.", "Lower → hold 20 seconds → heel lift."),
]

# Prop move → its no-prop version (a new move above or one already in the Library)
SWAPS = {
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
}

def sw(s): return json.dumps(s, ensure_ascii=False)
o = ['''
// MARK: - No-props versions

// WHAT: A mat-only version of every move that uses a band, weights, ball, block, ring or chair.
//       New mat-only moves are added to the Library; the builder can swap a whole class to them.
// TO CHANGE: edit a move line in `moves`, or which version a prop move swaps to in `swaps` (lower-case prop move name → no-prop move name).
enum NoProps {
    static let moves: [LibraryMove] = [
''']
for (name, area, style, cue, bb, mod, layers) in NEW:
    uid = uuid.uuid5(NS, name.lower())
    o.append(f'        LibraryMove(id: UUID(uuidString: "{uid}")!, name: {sw(name)}, area: .{area}, props: [], reps: "", seconds: 60, cue: {sw(cue)}, buildingBlock: {sw(bb)}, modification: {sw(mod)}, style: .{style}, layers: {sw(layers)}),\n')
o.append('''    ]

    static let swaps: [String: String] = [
''')
for k, v in SWAPS.items():
    o.append(f'        {sw(k)}: {sw(v)},\n')
o.append('''    ]

    /// The no-prop Library move for a prop move, or nil if the move needs no props (or has no version yet).
    static func version(of name: String) -> LibraryMove? {
        guard let target = swaps[MoveNames.key(name)] else { return nil }
        return LibraryMoveSet.all.first { $0.name == target }
    }
}
''')
open(sys.argv[1], 'w').write(''.join(o))
names = [n[0] for n in NEW]
assert len(set(n.lower() for n in names)) == len(names)
print(len(NEW), 'new moves,', len(SWAPS), 'swaps')
