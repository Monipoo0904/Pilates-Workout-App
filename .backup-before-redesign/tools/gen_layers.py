"""Generates Shared Swift: MoveLayers (harder 'layer up' options per move) and Sidedness (moves done one side at a time)."""
import json, sys

L = {
 # ---- classical
 "the hundred": "Legs in tabletop → legs long at 45° → lower the legs as long as the back stays down.",
 "hundred": "@the hundred",
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
 "side kick: front and back": "@side kick front/back",
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
 # ---- contemporary
 "pelvic curl": "Hold the top 3 breaths → lift one heel → march in bridge.",
 "chest lift": "Hold the top and pulse → legs in tabletop → hands behind the head, longer hold.",
 "chest lift with rotation": "Legs in tabletop → hold each twist 3 counts → extend one leg with the twist.",
 "toe taps": "Tap farther from the hips → legs straighter → double toe taps.",
 "dead bug": "Straight-leg reach → ball between hand and knee → slower 4-count reach.",
 "dead bug with ball": "@dead bug",
 "bird dog": "Hold the reach 3 breaths → elbow to knee under the body → knees hover.",
 "bird dogs": "@bird dog",
 "forearm plank": "Hold longer → lift one leg → rock forward and back.",
 "forearm plank hold": "@forearm plank",
 "side plank (knee)": "Straight legs → lift the top leg → thread the top arm through.",
 "clamshell": "Hips lift off the mat → pulse at the top → add a thigh band.",
 "side-lying clamshells": "@clamshell",
 "inner thigh lift": "Pulses at the top → small circles → ankle or wrist weight.",
 "windshield wipers": "Straight legs → bigger range → hold low 2 counts each side.",
 "cat & cow": "Hip circles → flow to Child's Pose and back → reach opposite arm and leg.",
 "thread the needle": "Reach to the ceiling first → hold 3 breaths → bind behind the back.",
 "mermaid": "Twist to face the mat → hover the bottom hand → side plank lift (advanced).",
 # ---- props
 "band pull-apart": "Shorter grip → hold open 3 counts → overhead pull-apart.",
 "seated band row": "Shorter band → hold the squeeze 3 counts → one arm at a time.",
 "band leg press": "Shorter band → slow 4-count press → leg circles in the band.",
 "band hamstring stretch": "Straighten the bottom leg → open the leg out to the side → cross over the body.",
 "kneeling overhead press": "Heavier weights → half-kneeling lunge → add a twist at the top.",
 "kneeling shoulder presses": "@kneeling overhead press",
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
 "bridge with block": "@bridge with block squeeze",
 "supported bridge": "Lift one leg → circle the leg → both legs up (shoulder stand prep).",
 "squat with block squeeze": "Pulse at the bottom → add a heel lift → hold low 20 seconds.",
 "squats with block squeeze": "@squat with block squeeze",
 "hundred with ball squeeze": "Legs long at 45° → lower the legs → hold the squeeze the whole time.",
 "ball roll back": "Roll farther back → add a twist → arms overhead.",
 "bridge with ball squeeze": "Squeeze pulses at the top → march → single leg.",
 "v-sit ball pass": "Straighter legs → lower down between passes → hold the V 3 breaths.",
 "ring inner thigh squeeze": "Hold 5 counts → in a bridge → in a V-sit.",
 "ring chest press": "Pulses → press overhead → in a chest lift.",
 # ---- barre
 "plié": "Heels lifted → pulse low → arms overhead.",
 "plié pulses": "Heels lifted → smaller, lower pulses → hold 20 seconds at the end.",
 "relevé": "One hand off the chair → single leg → lower in 4 counts.",
 "arabesque lift": "Hold at the top 3 counts → pulses → standing heel lifted.",
 "attitude lift": "Pulse at the top → hold → standing heel lifted.",
 "curtsy lunge": "Pulse at the bottom → no hands → knee lift between reps.",
 "standing side leg lift": "Pulse at the top → no hands → circles.",
 "chair pose pulses": "Heels lifted → hold 20 seconds → add a twist.",
 # ---- sculpt
 "bodyweight squat": "Pulse at the bottom → lower in 4 counts → heel lift at the top.",
 "squats": "@bodyweight squat",
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
 # ---- side-lying (class names)
 "side-lying leg lifts": "Pulses at the top → circles → add a ball or ankle weight.",
 "side-lying leg lift circles + pulse": "Bigger circles → slower pulses → ankle weight.",
 "side-lying leg lifts with ball": "Lift the ball higher → pulse → hold 3 counts at the top.",
 # ---- stretch & mobility (deeper options)
 "figure-4 glute stretch": "Pull the bottom knee closer → straighten the bottom leg → seated figure-4.",
 "child's pose": "Walk hands to one side → wide knees → thread an arm through.",
 "low lunge hip flexor stretch": "Arms overhead → side bend → hold the back foot (quad stretch).",
 "chest opener": "Higher block → arms wide → longer hold, slow breaths.",
 "standing roll down": "Bend the knees at the bottom → walk out to plank → roll up onto the toes.",
 "roll down & 2 breaths": "@standing roll down",
 "seated side bend": "Reach farther → add a twist → hold 3 breaths.",
 "neck & shoulder release": "Hand on the head for gentle weight → shoulder rolls → chin to chest.",
 "supine spinal twist": "Straighten the top leg → arms in cactus → hold 5 breaths.",
 # ---- prenatal & gentle
 "seated breathing & pelvic floor": "Longer exhale → add a pelvic floor lift → add arms.",
 "breathing": "Longer exhale → 3D rib breath (back and sides) → add a pelvic floor lift.",
 "3 breaths": "@breathing",
 "imprint & iso-abs": "Hold 5 breaths → lift one foot → tabletop legs.",
 "seated ball hip circles": "Bigger circles → figure eights → arms overhead.",
 "quadruped arm reach": "Add the opposite leg → hold 3 breaths → add a band.",
 "wall push-up": "Feet farther from the wall → slower lowering → one arm (advanced).",
 "supported squat": "Lower → hold 20 seconds → heel lift.",
 "side-lying leg lift (pillow)": "Pulses → circles → ankle weight.",
 # ---- standing
 "standing footwork": "Heels lifted → slower → single leg.",
 "single-leg balance": "Eyes closed → arms overhead → extend the lifted leg.",
 "standing knee lift with twist": "Hold the knee lift → quicker tempo → add weights.",
}
for k, v in list(L.items()):
    if v.startswith("@"):
        L[k] = L[v[1:]]

SIDED = sorted([
 "single leg circles", "side kick front/back", "side kick up/down", "side kick: front and back", "side bend", "mermaid",
 "clamshell", "banded clamshell", "side-lying clamshells", "inner thigh lift", "side plank (knee)",
 "side-lying leg lift with wrist weight", "side-lying leg lift (pillow)", "side-lying leg lifts",
 "side-lying leg lift circles + pulse", "side-lying leg lifts with ball", "banded fire hydrant", "fire hydrants",
 "fire hydrants with frog kicks", "arabesque lift", "attitude lift", "standing side leg lift", "curtsy lunge",
 "figure-4 glute stretch", "low lunge hip flexor stretch", "band hamstring stretch", "band leg press",
 "thread the needle", "seated side bend", "single-leg balance", "v-ups on glute", "squats with toe lifts",
])

def sw(s): return json.dumps(s, ensure_ascii=False)
out = []
out.append('''
// MARK: - Layers and sides

// WHAT: "Layer up" options: harder versions of each move, easiest first, shown under Modification on the phone and watch.
//       A move's own Layers text (written in the builder or Library) wins; otherwise this list is used.
// TO CHANGE: edit the text after a move's name. Use → between layers. Names are lower case; left/right are ignored.
enum MoveLayers {
    static func lookup(_ name: String) -> String {
        byName[MoveNames.key(name)] ?? ""
    }

    static let byName: [String: String] = [
''')
for k, v in L.items():
    out.append(f'        {sw(k)}: {sw(v)},\n')
out.append('''    ]
}

// WHAT: Moves taught one side at a time (right side first, then left). The builder turns these on automatically.
// TO CHANGE: add a move's lower-case name to the list.
enum Sidedness {
    static func isOneSided(_ name: String) -> Bool {
        let key = MoveNames.key(name)
        return names.contains(key) || key.contains("side-lying") || key.contains("clamshell") || key.contains("fire hydrant")
    }

    static let names: Set<String> = [
''')
out.append(''.join(f'        {sw(n)},\n' for n in SIDED))
out.append('''    ]
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
''')
open(sys.argv[1], 'w').write(''.join(out))
print(len(L), 'layer entries')
