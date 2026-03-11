import Foundation
import AppKit
import Combine

enum TimerState: Equatable {
    case idle
    case running
    case paused
    case alert
}

class TimerManager: ObservableObject {
    static let defaultDuration: TimeInterval = {
        // 支持 --duration N 启动参数（秒），方便测试
        let args = CommandLine.arguments
        if let idx = args.firstIndex(of: "--duration"),
           idx + 1 < args.count,
           let seconds = TimeInterval(args[idx + 1]),
           seconds > 0 {
            return seconds
        }
        return 25 * 60
    }()

    static var isTestMode: Bool {
        defaultDuration != 25 * 60
    }

    @Published var remaining: TimeInterval = TimerManager.defaultDuration
    @Published var state: TimerState = .idle {
        didSet { updateDockBadge() }
    }

    private var timerSource: DispatchSourceTimer?
    private var targetDate: Date?
    private var pausedRemaining: TimeInterval = 0
    /// Prevents macOS App Nap from suspending our timer when the window is hidden.
    private var activityToken: NSObjectProtocol?

    var displayMinutes: Int { Int(remaining) / 60 }
    var displaySeconds: Int { Int(remaining) % 60 }

    var buttonTitle: String {
        switch state {
        case .idle: return "START"
        case .running: return "PAUSE"
        case .paused: return "RESUME"
        case .alert: return ""
        }
    }

    // MARK: - Actions

    func handleButtonTap() {
        switch state {
        case .idle:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        case .alert:
            break
        }
    }

    func start() {
        remaining = TimerManager.defaultDuration
        targetDate = Date().addingTimeInterval(remaining)
        state = .running
        startTimer()
    }

    func pause() {
        pausedRemaining = remaining
        stopTimer()
        state = .paused
    }

    func resume() {
        targetDate = Date().addingTimeInterval(pausedRemaining)
        state = .running
        startTimer()
    }

    func reset() {
        stopTimer()
        remaining = TimerManager.defaultDuration
        state = .idle
    }

    func triggerAlert() {
        stopTimer()
        remaining = 0
        state = .alert
    }

    // MARK: - Timer

    /// Uses DispatchSourceTimer (immune to App Nap) + Date-based drift correction.
    private func startTimer() {
        // Disable App Nap so the timer fires even when the window is occluded
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Pomodoro countdown in progress"
        )

        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(deadline: .now(), repeating: .milliseconds(250), leeway: .milliseconds(50))
        source.setEventHandler { [weak self] in
            guard let self, let target = self.targetDate else { return }
            let diff = target.timeIntervalSince(Date())
            if diff <= 0 {
                self.triggerAlert()
            } else {
                self.remaining = diff
                self.updateDockBadge()
            }
        }
        source.resume()
        timerSource = source
    }

    private func stopTimer() {
        timerSource?.cancel()
        timerSource = nil
        targetDate = nil

        // Release activity token to re-enable App Nap
        activityToken = nil
    }

    // MARK: - Dock Badge

    func updateDockBadge() {
        let badge: String
        switch state {
        case .running, .paused:
            let minutes = Int(ceil(remaining / 60))
            badge = "\(minutes)"
        case .alert:
            badge = "!"
        case .idle:
            badge = ""
        }
        NSApplication.shared.dockTile.badgeLabel = badge
    }
}
