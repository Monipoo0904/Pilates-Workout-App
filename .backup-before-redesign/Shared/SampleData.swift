import Foundation

enum SampleData {
    static let starterClass = PilatesClass(
        version: 1,
        id: "starter-glute-core",
        name: "Starter Glute & Core (15 min)",
        props: ["Mat", "Yoga block", "Pilates ball"],
        items: [
            PilatesClassItem(
                section: "Warm-up",
                name: "Hundred with Ball Squeeze",
                reps: "100 pumps",
                seconds: 120,
                cue: "Ball between knees, curl up and keep shoulders soft.",
                buildingBlock: "Tabletop knees and neutral pelvis.",
                modification: "Neck strain: head down on the mat.",
                props: ["Pilates ball"]
            ),
            PilatesClassItem(
                section: "Glutes",
                name: "Bridge with Block",
                reps: "10 slow reps",
                seconds: 180,
                cue: "Press through heels and lightly squeeze the block.",
                buildingBlock: "Rib-to-hip connection before lifting.",
                modification: "Lower bridge range if hamstrings cramp.",
                props: ["Yoga block"]
            ),
            PilatesClassItem(
                section: "Core",
                name: "Dead Bug with Ball",
                reps: "8/side",
                seconds: 210,
                cue: "Opposite arm/leg reach while keeping low back long.",
                buildingBlock: "Exhale on reach.",
                modification: "Keep knees bent if back arches.",
                props: ["Pilates ball"]
            ),
            PilatesClassItem(
                section: "Finish",
                name: "Forearm Plank Hold",
                reps: "2 holds",
                seconds: 120,
                cue: "Long line from head to heels.",
                buildingBlock: "Lift through upper back.",
                modification: "Drop knees for support.",
                props: []
            )
        ]
    )
}
