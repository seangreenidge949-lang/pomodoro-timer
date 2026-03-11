import SwiftUI

@main
struct PomodoroTimerApp: App {
    @StateObject private var timerManager = TimerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
        }
        .defaultSize(width: 400, height: 500)
        .windowResizability(.contentSize)
    }
}
