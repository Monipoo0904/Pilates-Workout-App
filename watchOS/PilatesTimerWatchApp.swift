import SwiftUI
import WatchKit
import HealthKit

/// Lets the iPhone launch this app with a Pilates workout.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        // The class itself arrives over WatchConnectivity; WatchContentView opens it and starts the workout.
    }
}

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
