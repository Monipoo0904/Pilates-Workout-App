// ======================================================================
// PilatesTimerWatchApp.swift  (Apple Watch app)
// WHAT THIS FILE DOES: Starts the watch app, shares the class/log/connection data with every watch screen, and lets the iPhone launch it for a workout.
// TO CHANGE: Rarely needed.
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import SwiftUI
import WatchKit
import HealthKit

/// Lets the iPhone launch this app with a Pilates workout.
// WHAT: Lets the iPhone open this watch app with a Pilates workout.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        // The class itself arrives over WatchConnectivity; WatchContentView opens it and starts the workout.
    }
}

// WHAT: Starts the watch app and shares data with all watch screens.
@main
struct PilatesTimerWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate
    @StateObject private var classStore = WatchClassStore()
    @StateObject private var logStore = WatchLogStore()
    @StateObject private var connectivity = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(classStore)
                .environmentObject(logStore)
                .environmentObject(connectivity)
                .onAppear {
                    connectivity.classStore = classStore
                    connectivity.logStore = logStore
                }
        }
    }
}
