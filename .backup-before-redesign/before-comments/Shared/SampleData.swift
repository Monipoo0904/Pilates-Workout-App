// Built-in classes for Pilates Timer. Generated from the class planner.

import Foundation

enum SampleData {
    static let fallIntoPilates = PilatesClass(
        version: 3,
        id: "fall-into-pilates-45",
        name: "Fall Into Pilates · Outdoor (45 min)",
        props: ["Mat"],
        items: [
            PilatesClassItem(section: "Opening", name: "Welcome & check-in", reps: "", seconds: 180, cue: "Mats in rows facing me, arm's length apart. \"Is anyone pregnant, injured, or dealing with back, neck, knee or shoulder pain? If anything hurts, stop and rest.\" Explain the Powerhouse and the scoop.", transition: "Lie down on your back, knees bent, feet flat."),
            PilatesClassItem(section: "Centering", name: "Breathing", reps: "5 breaths", seconds: 120, cue: "Inhale wide into the back and sides of the ribs. Exhale, scoop the belly in and up, ribs soften.", buildingBlock: "Hands on the ribs to feel them widen."),
            PilatesClassItem(section: "Centering", name: "Imprint & Iso-Abs", reps: "5 holds", seconds: 180, cue: "Exhale, gently imprint the low back into the mat. Hold the scoop and keep breathing. Release and repeat.", modification: "Low back pain: keep a small natural curve.", transition: "Hug the knees into the chest."),
            PilatesClassItem(section: "Mat flow", name: "Hundred", reps: "10 breaths", seconds: 120, cue: "Curl up, eyes to belly, arms long, legs up. \"Pump small and strong. Inhale 2, 3, 4, 5. Exhale 2, 3, 4, 5.\"", buildingBlock: "Bend the knees into tabletop.", modification: "Neck strain: keep the head down on the mat.", transition: "Hug knees in, lower the head, legs long, arms overhead."),
            PilatesClassItem(section: "Mat flow", name: "Roll Up", reps: "4–5", seconds: 150, cue: "\"Inhale, chin to chest. Exhale, peel off the mat one bone at a time and reach past your toes. Exhale, roll down slowly.\"", buildingBlock: "Bend the knees, or hold the backs of the thighs.", modification: "Osteoporosis or disc issues: skip; do a head-and-shoulder curl instead.", transition: "Roll down, right leg to the ceiling."),
            PilatesClassItem(section: "Mat flow", name: "Single Leg Circles", reps: "5 each way, each leg", seconds: 150, cue: "Arms press into the mat. Cross over, circle down, around and up. Hips still, like a glass of water balanced on them.", buildingBlock: "Make the circle smaller.", modification: "Tight hamstrings or low back: bend the bottom knee, foot flat.", transition: "Hug both knees in, curl the head up."),
            PilatesClassItem(section: "Mat flow", name: "Single Leg Stretch", reps: "6 each leg", seconds: 150, cue: "Head and shoulders up, hug one knee, the other leg long. Switch with control, elbows wide, scoop deep.", buildingBlock: "Legs higher toward the ceiling.", modification: "Neck strain: head down on the mat."),
            PilatesClassItem(section: "Mat flow", name: "Double Leg Stretch", reps: "6", seconds: 150, cue: "Inhale, reach arms and legs long. Exhale, circle the arms around and hug the knees back in.", buildingBlock: "Smaller reach, legs higher.", modification: "Neck strain: head down on the mat.", transition: "Feet flat on the mat, hip-width apart."),
            PilatesClassItem(section: "Glutes & core", name: "Shoulder Bridge", reps: "6–8", seconds: 240, cue: "Press through the heels, peel the spine up one bone at a time, squeeze the seat. Roll down the same way.", buildingBlock: "Smaller lift and hold.", modification: "Neck issues: keep the lift low.", transition: "Roll onto your right side, hips stacked."),
            PilatesClassItem(section: "Glutes & core", name: "Side-Lying Leg Lifts (right)", reps: "8", seconds: 120, cue: "Hips stacked, waist lifted. Lift the top leg long and lower with control.", buildingBlock: "Bend the bottom knee for balance.", modification: "Hip pain: smaller lift.", transition: "Roll through your stomach to the left side."),
            PilatesClassItem(section: "Glutes & core", name: "Side-Lying Leg Lifts (left)", reps: "8", seconds: 120, cue: "Hips stacked, waist lifted. Lift the top leg long and lower with control.", buildingBlock: "Bend the bottom knee for balance.", modification: "Hip pain: smaller lift.", transition: "Roll onto your stomach, up on the forearms."),
            PilatesClassItem(section: "Glutes & core", name: "Single Leg Kick", reps: "6 each leg", seconds: 240, cue: "Forearms down, belly lifted off the mat. Kick the heel to the seat twice, then lengthen. Switch.", buildingBlock: "Smaller kicks.", modification: "Low back pain: rest the forehead on the hands.", transition: "Sit up tall, legs a little wider than the mat."),
            PilatesClassItem(section: "Stretch", name: "Spine Stretch Forward", reps: "4–5", seconds: 180, cue: "Feet flexed. Exhale, round forward like rolling over a big ball. Inhale, stack up tall.", buildingBlock: "Sit on a folded towel and bend the knees.", modification: "Osteoporosis: hinge forward with a flat back instead of rounding.", transition: "Turn onto your stomach, hands under the shoulders."),
            PilatesClassItem(section: "Stretch", name: "Swan Prep", reps: "4–5", seconds: 150, cue: "Lift the chest with the upper back, belly scooped, shoulders away from the ears. Lower with control.", modification: "Low back pain: keep it small, forearms down.", transition: "Come to sit, knees in, hands through to the ankles."),
            PilatesClassItem(section: "Stretch", name: "Seal", reps: "6", seconds: 150, cue: "Balance just behind the sit bones. Clap the feet 3 times, roll back, roll up and clap.", buildingBlock: "Rock without the claps.", modification: "Neck or back issues, osteoporosis: skip and hold the balance.", transition: "Come up to standing."),
            PilatesClassItem(section: "Ending", name: "Roll Down & 2 breaths", reps: "3", seconds: 180, cue: "Stand tall, chin to chest, roll down one bone at a time and roll back up. Two big breaths together."),
            PilatesClassItem(section: "Ending", name: "Thank you & gift bags", reps: "", seconds: 120, cue: "Thank everyone, hand out gift bags, take the group photo, and share how to join a Vitality Village.")
        ]
    )

    static let beginnerScript = PilatesClass(
        id: "beginner-script",
        name: "Beginner Mat Teaching Script (35 min)",
        props: ["Mat"],
        items: [
            PilatesClassItem(section: "Opening", name: "Welcome & check-in", reps: "", seconds: 180, cue: "\"Hi everyone, I'm Monique, training for my Peak Pilates mat certification. Is anyone pregnant, injured, or dealing with back, neck, knee or shoulder pain?\" Explain the powerhouse and the scoop. \"If anything hurts, stop and rest.\" End lying on your back.", modification: "Osteoporosis or disc issue: skip Roll Up and Rolling Like a Ball. Pregnancy after the first trimester: no long periods flat on the back."),
            PilatesClassItem(section: "The class", name: "Hundred", reps: "10 breaths", seconds: 180, cue: "Hug knees in, scoop, exhale and curl up, eyes to belly. Arms long, legs up. \"Pump small and strong. Inhale 2, 3, 4, 5. Exhale 2, 3, 4, 5.\" Count the breaths to ten, then hug knees in and lower the head.", buildingBlock: "Bend the knees into tabletop.", modification: "Neck strain: keep the head down on the mat."),
            PilatesClassItem(section: "The class", name: "Roll Up", reps: "4–5", seconds: 180, cue: "Legs long, feet flexed, arms up. \"Inhale, chin to chest. Exhale, peel off the mat one bone at a time and reach past your toes. Inhale, scoop deeper. Exhale, roll down slowly.\"", buildingBlock: "Bend the knees, or hold the backs of the thighs and walk the hands up.", modification: "Osteoporosis or disc issues: skip; do a head-and-shoulder curl instead."),
            PilatesClassItem(section: "The class", name: "Single Leg Circles", reps: "5 each way, each leg", seconds: 180, cue: "Arms press into the mat, right leg to the ceiling, left leg long. \"Cross over, circle down, around and up. Hips still, like a glass of water is balanced on them.\" Switch legs.", buildingBlock: "Make the circle smaller.", modification: "Tight hamstrings or low back: bend the bottom knee, foot flat."),
            PilatesClassItem(section: "The class", name: "Rolling Like a Ball", reps: "6", seconds: 120, cue: "Front of the mat, hold the ankles, tight ball, feet up, balance behind the sit bones. \"Inhale, roll back to your shoulder blades. Exhale, roll up and balance. Stay in your ball.\"", buildingBlock: "Practice the balance with toes on the mat.", modification: "Osteoporosis, disc or neck issues: skip."),
            PilatesClassItem(section: "The class", name: "Single Leg Stretch", reps: "8 sets", seconds: 180, cue: "Curl up, right knee in, outside hand to ankle, inside hand to knee, left leg long. \"Switch, switch. Inhale for two, exhale for two.\"", buildingBlock: "Reach the long leg higher.", modification: "Neck strain: head down."),
            PilatesClassItem(section: "The class", name: "Double Leg Stretch", reps: "6–8", seconds: 180, cue: "Hug both knees in and curl up. \"Inhale, reach arms and legs long. Exhale, circle the arms around and hug the knees in.\"", buildingBlock: "Reach the legs up to the ceiling, not low.", modification: "Neck strain: keep the head down."),
            PilatesClassItem(section: "The class", name: "Spine Stretch Forward", reps: "4", seconds: 180, cue: "Sit tall on the sit bones, legs a little wider than hips, feet flexed, arms forward. \"Exhale, round forward, chin to chest, over a big ball. Inhale, stack back up one bone at a time.\"", buildingBlock: "Bend the knees.", modification: "Tight hamstrings or low back: sit on a folded towel or block."),
            PilatesClassItem(section: "The class", name: "Single Leg Kick", reps: "6–8 sets", seconds: 180, cue: "On the stomach, forearms down, elbows under shoulders, chest lifted, belly scooped, legs together. \"Kick, kick, switch, kick, kick.\"", buildingBlock: "Lower the chest a little.", modification: "Low back pain: rest the forehead on the hands."),
            PilatesClassItem(section: "The class", name: "Side Kick: front and back", reps: "6–8 each side", seconds: 240, cue: "Lie on the right side along the back edge, legs slightly forward, head on hand. \"Top leg to hip height. Kick forward twice, kick, kick, then sweep it long behind. Hips stacked.\" Switch sides.", buildingBlock: "Make the kick smaller.", modification: "Neck or shoulder: rest the head on the arm."),
            PilatesClassItem(section: "The class", name: "Seal", reps: "6", seconds: 120, cue: "Front of the mat, knees open, hands dive through to hold the ankles from underneath, feet up. \"Clap three. Inhale, roll back and clap three. Exhale, roll up, balance, clap three.\"", buildingBlock: "Stay seated: clap and balance only.", modification: "Osteoporosis, disc or neck issues: no rolling."),
            PilatesClassItem(section: "Closing", name: "Closing", reps: "", seconds: 120, cue: "Sit tall at the front of the mat, one big breath in and out. \"Thank you for practicing with me. Notice how you're sitting taller.\" Ask helpers to sign your hours log.")
        ]
    )

    static let gluteCoreProps = PilatesClass(
        id: "glute-core-props",
        name: "20-min Glute & Core with ball and block",
        props: ["Mat", "Yoga block", "Pilates ball"],
        items: [
            PilatesClassItem(section: "Warm-up", name: "3 Breaths", reps: "3", seconds: 45, cue: "On your back. Inhale wide into the ribs and back. Exhale, empty the lungs, spine melts into the mat."),
            PilatesClassItem(section: "Warm-up", name: "Hundred with ball squeeze", reps: "100 pumps", seconds: 120, cue: "Ball between the knees; squeeze to find the inner thighs and Powerhouse while you pump. In 2, 3, 4, 5. Out 2, 3, 4, 5.", buildingBlock: "Knees in tabletop or feet on the floor, head down.", modification: "Neck strain: head down on the mat.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Warm-up", name: "Walkouts", reps: "5", seconds: 60, cue: "Roll up to stand. Roll down bone by bone, walk out 1-2-3 to plank, walk back, roll up.", buildingBlock: "Walk out only partway; knees down in the plank.", modification: "Wrist pain: walk out on fists."),
            PilatesClassItem(section: "Warm-up", name: "Cat & Cow", reps: "4–5", seconds: 45, cue: "Hands under shoulders, knees under hips. Inhale lift tail and head; exhale curl the tail under.", modification: "Wrist pain: on the fists or forearms."),
            PilatesClassItem(section: "Arms", name: "Kneeling shoulder presses", reps: "8", seconds: 45, cue: "Tall kneel, ribs knit together, press overhead. Abs in so the back doesn't arch.", buildingBlock: "No weights, or one arm at a time.", modification: "Knee pain: seated or standing.", props: ["Dumbbells"]),
            PilatesClassItem(section: "Arms", name: "Chest squeeze", reps: "10", seconds: 45, cue: "Ball between the palms at chest height, elbows wide. Squeeze and release, shoulders down.", buildingBlock: "Smaller squeeze.", modification: "Wrist pain: press with the forearms instead.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Glutes · standing", name: "Squats with block squeeze", reps: "8", seconds: 45, cue: "Block between the thighs above the knees; squeeze as you sit back and press through the heels to stand.", buildingBlock: "Squat to a chair.", modification: "Knee pain: shallower squat.", props: ["Yoga block"]),
            PilatesClassItem(section: "Glutes · standing", name: "Squats with left toe lifts", reps: "8", seconds: 45, cue: "Same squat, lift the left toes at the top.", buildingBlock: "Squat to a chair.", modification: "Knee pain: shallower squat, weight in the heels."),
            PilatesClassItem(section: "Glutes · standing", name: "Squats with right toe lifts", reps: "8", seconds: 45, cue: "Now the right toes. Scoop, stand tall.", buildingBlock: "Squat to a chair.", modification: "Knee pain: shallower squat, weight in the heels."),
            PilatesClassItem(section: "Glutes · hands & knees", name: "Fire hydrants", reps: "8", seconds: 45, cue: "Knee stays bent, lift out to the side, hips level. Back flat like a tabletop.", buildingBlock: "Smaller lift.", modification: "Wrist pain: drop to the forearms."),
            PilatesClassItem(section: "Glutes · hands & knees", name: "Fire hydrants with frog kicks", reps: "8", seconds: 45, cue: "Lift, kick the leg long, bend back in.", buildingBlock: "Hydrants only.", modification: "Wrist pain: drop to the forearms."),
            PilatesClassItem(section: "Glutes · hands & knees", name: "Bird dogs", reps: "8", seconds: 45, cue: "Reach opposite arm and leg long and away. Belly lifts to the spine.", buildingBlock: "Arms only, or legs only.", modification: "Wrist pain: on the fists or forearms."),
            PilatesClassItem(section: "Core", name: "Ball roll back", reps: "6–8", seconds: 45, cue: "Ball behind your low back, knees bent. Exhale, curl back into the ball in a C-Curve; inhale to sit tall.", buildingBlock: "Smaller roll back; hands behind the thighs.", modification: "Osteoporosis: sit tall and breathe into the ball instead.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Right side", name: "V-ups on right glute", reps: "8", seconds: 45, cue: "Balance on the right sit bone, hold the ball at the chest, lift and lower with control.", buildingBlock: "Hands behind the thighs, knees bent; hold instead of lifting.", modification: "Low back or osteoporosis: hold the balance only.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Right side", name: "Side-lying clamshells (right)", reps: "8", seconds: 45, cue: "Knees bent, heels in line with the seat, hips stacked; open the top knee.", buildingBlock: "Smaller opening.", modification: "Hip pain: smaller opening."),
            PilatesClassItem(section: "Right side", name: "Side-lying leg lifts with ball (right)", reps: "8", seconds: 45, cue: "Ball between the ankles; lift both legs together, hips stacked, waist lifted.", buildingBlock: "Ball between the knees, knees bent.", modification: "Hip pain: smaller lift.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Core", name: "Crossover elbow taps", reps: "8", seconds: 45, cue: "Elbow reaches to the opposite knee, twist from the ribs. Exhale to twist.", buildingBlock: "Feet on the floor, knees bent; smaller twist.", modification: "Neck strain: head supported in the hands. Osteoporosis: skip loaded twisting."),
            PilatesClassItem(section: "Left side", name: "V-ups on left glute", reps: "8", seconds: 45, cue: "Balance on the left sit bone, hold the ball at the chest, lift and lower with control.", buildingBlock: "Hands behind the thighs; hold instead of lifting.", modification: "Low back or osteoporosis: hold the balance only.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Left side", name: "Side-lying clamshells (left)", reps: "8", seconds: 45, cue: "Hips stacked; open the top knee.", buildingBlock: "Smaller opening.", modification: "Hip pain: smaller opening."),
            PilatesClassItem(section: "Left side", name: "Side-lying leg lifts with ball (left)", reps: "8", seconds: 45, cue: "Ball between the ankles; lift both legs together, hips stacked.", buildingBlock: "Ball between the knees, knees bent.", modification: "Hip pain: smaller lift.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Finish", name: "Bridge with ball squeeze", reps: "8", seconds: 45, cue: "Ball between the knees, squeeze as you roll up one bone at a time and down the same way.", buildingBlock: "Small lift and hold.", modification: "Neck issues: keep the lift low.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Finish", name: "Supported bridge", reps: "5 breaths", seconds: 60, cue: "Lift the hips, slide the block under the sacrum, rest and breathe.", buildingBlock: "Block on its lowest height.", modification: "Low back pain: lowest height, knees bent.", props: ["Yoga block"]),
            PilatesClassItem(section: "Finish", name: "Figure-4 glute stretch", reps: "each side", seconds: 60, cue: "Ankle over knee, breathe into the hip. Roll up, 2 breaths, finish standing tall.", buildingBlock: "Keep the bottom foot on the floor.", modification: "Knee pain: ankle lower on the thigh, gentle stretch.")
        ]
    )

    static let gluteCore = PilatesClass(
        id: "glute-core-20",
        name: "20-min Glute & Core",
        props: ["Mat"],
        items: [
            PilatesClassItem(section: "Warm-up", name: "3 Breaths", reps: "3", seconds: 45, cue: "On your back. Inhale wide into the ribs and back. Exhale, empty the lungs, spine melts into the mat."),
            PilatesClassItem(section: "Warm-up", name: "Hundred", reps: "100 pumps, 10 breaths", seconds: 120, cue: "Chin to chest, legs to point of control. In 2, 3, 4, 5. Out 2, 3, 4, 5. Low back imprinted, abs scoop in and up."),
            PilatesClassItem(section: "Warm-up", name: "Walkouts", reps: "5", seconds: 90, cue: "Roll up to stand. Roll down bone by bone, walk out 1-2-3 to plank, walk back, roll up. Belly lifts, no sagging hips."),
            PilatesClassItem(section: "Warm-up", name: "Cat & Cow", reps: "4–5", seconds: 45, cue: "Hands under shoulders, knees under hips. Inhale lift tail and head; exhale curl the tail under."),
            PilatesClassItem(section: "Arms", name: "Kneeling shoulder presses", reps: "8", seconds: 60, cue: "Tall kneel, ribs knit together, press overhead. Abs in so the back doesn't arch."),
            PilatesClassItem(section: "Arms", name: "Kneeling shoulder press to tricep dip", reps: "8", seconds: 60, cue: "Same press, add the dip. Elbows point straight back."),
            PilatesClassItem(section: "Glutes · standing", name: "Squats", reps: "8", seconds: 60, cue: "Tuck toes, stand through the heels, feet hip-width. Sit back, knees over toes, press through heels. Squeeze at the top."),
            PilatesClassItem(section: "Glutes · standing", name: "Squats with left toe lifts", reps: "8", seconds: 60, cue: "Same squat, lift the left toes at the top."),
            PilatesClassItem(section: "Glutes · standing", name: "Squats with right toe lifts", reps: "8", seconds: 60, cue: "Now the right toes. Scoop, stand tall."),
            PilatesClassItem(section: "Glutes · hands & knees", name: "Fire hydrants", reps: "8", seconds: 60, cue: "Knee stays bent, lift out to the side, hips level. Back flat like a tabletop."),
            PilatesClassItem(section: "Glutes · hands & knees", name: "Fire hydrants with frog kicks", reps: "8", seconds: 60, cue: "Lift, kick the leg long, bend back in."),
            PilatesClassItem(section: "Glutes · hands & knees", name: "Bird dogs", reps: "8", seconds: 60, cue: "Reach opposite arm and leg long and away. Belly lifts to the spine."),
            PilatesClassItem(section: "Right side", name: "V-ups on right glute", reps: "8", seconds: 60, cue: "Balance on the right sit bone, lift and lower with control."),
            PilatesClassItem(section: "Right side", name: "Side-lying clamshells (right)", reps: "8", seconds: 60, cue: "Knees bent, heels in line with the seat, hips stacked; open the top knee."),
            PilatesClassItem(section: "Right side", name: "Side-lying leg lift circles + pulse (right)", reps: "8", seconds: 60, cue: "Top leg long, lift, circle, pulse at the top. Waist lifts, top hip still."),
            PilatesClassItem(section: "Core", name: "Crossover elbow taps", reps: "8", seconds: 60, cue: "Elbow reaches to the opposite knee, twist from the ribs. Exhale to twist."),
            PilatesClassItem(section: "Left side", name: "V-ups on left glute", reps: "8", seconds: 60, cue: "Balance on the left sit bone, lift and lower with control."),
            PilatesClassItem(section: "Left side", name: "Side-lying clamshells (left)", reps: "8", seconds: 60, cue: "Hips stacked; open the top knee."),
            PilatesClassItem(section: "Left side", name: "Side-lying leg lift circles + pulse (left)", reps: "8", seconds: 60, cue: "Top leg long, lift, circle, pulse. Top hip still."),
            PilatesClassItem(section: "Cool-down", name: "Figure-4 glute stretch", reps: "each side", seconds: 60, cue: "Ankle over knee, breathe into the hip. Roll up, 2 breaths, finish standing tall.")
        ]
    )

    static let starterClass = PilatesClass(
        id: "starter-glute-core",
        name: "Starter Glute & Core (15 min)",
        props: ["Mat", "Yoga block", "Pilates ball"],
        items: [
            PilatesClassItem(section: "Warm-up", name: "Hundred with Ball Squeeze", reps: "100 pumps", seconds: 120, cue: "Ball between knees, curl up and keep shoulders soft.", buildingBlock: "Tabletop knees and neutral pelvis.", modification: "Neck strain: head down on the mat.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Glutes", name: "Bridge with Block", reps: "10 slow reps", seconds: 180, cue: "Press through heels and lightly squeeze the block.", buildingBlock: "Rib-to-hip connection before lifting.", modification: "Lower bridge range if hamstrings cramp.", props: ["Yoga block"]),
            PilatesClassItem(section: "Core", name: "Dead Bug with Ball", reps: "8/side", seconds: 210, cue: "Opposite arm/leg reach while keeping low back long.", buildingBlock: "Exhale on reach.", modification: "Keep knees bent if back arches.", props: ["Pilates ball"]),
            PilatesClassItem(section: "Finish", name: "Forearm Plank Hold", reps: "2 holds", seconds: 120, cue: "Long line from head to heels.", buildingBlock: "Lift through upper back.", modification: "Drop knees for support.")
        ]
    )

    /// Classes that ship with the app. Missing ones are added back on launch; your own edits are kept.
    static let builtIns: [PilatesClass] = [fallIntoPilates, beginnerScript, gluteCoreProps, gluteCore, starterClass]

    /// Adds any built-in class whose id isn't already saved.
    /// Adds missing built-in classes, and replaces a saved built-in with the newer
    /// version when its version number goes up (so fixes reach the phone and the watch).
    static func mergingBuiltIns(into saved: [PilatesClass]) -> [PilatesClass] {
        let latest = Dictionary(builtIns.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let updated = saved.map { savedClass -> PilatesClass in
            if let builtIn = latest[savedClass.id], builtIn.version > savedClass.version { return builtIn }
            return savedClass
        }
        let ids = Set(saved.map(\.id))
        return updated + builtIns.filter { !ids.contains($0.id) }
    }
}
