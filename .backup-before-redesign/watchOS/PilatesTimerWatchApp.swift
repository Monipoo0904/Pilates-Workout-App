import SwiftUI

@main
struct PilatesTimerWatchApp: App {
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
