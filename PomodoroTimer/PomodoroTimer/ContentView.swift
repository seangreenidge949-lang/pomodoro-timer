import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @StateObject private var overlayManager = AlertOverlayManager.shared
    @StateObject private var sessionCounter = SessionCounter()
    @State private var breathingOpacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Test mode badge
                if TimerManager.isTestMode {
                    Text("[TEST MODE: \(Int(TimerManager.defaultDuration))s]")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)
                }

                // Timer display
                Text(timeString)
                    .font(.system(size: 80, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .monospacedDigit()
                    .opacity(timerManager.state == .running ? breathingOpacity : 1.0)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 0.878, green: 0.878, blue: 0.878)) // #E0E0E0
                            .frame(height: 2)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.black)
                            .frame(width: geo.size.width * progress, height: 2)
                    }
                }
                .frame(width: 240, height: 2)
                .opacity(timerManager.state == .running || timerManager.state == .paused ? 1 : 0)

                // Action button
                if timerManager.state != .alert {
                    Button(action: {
                        timerManager.handleButtonTap()
                    }) {
                        Text(timerManager.buttonTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 50)
                            .background(Color.black)
                            .cornerRadius(25)
                    }
                    .buttonStyle(.plain)
                }

                // Session dots
                if sessionCounter.count > 0 {
                    HStack(spacing: 8) {
                        let total = max(sessionCounter.count, sessionCounter.goal)
                        ForEach(0..<total, id: \.self) { i in
                            if i < sessionCounter.count {
                                Circle()
                                    .fill(Color(red: 0.8, green: 0.8, blue: 0.8))
                                    .frame(width: 8, height: 8)
                            } else {
                                Circle()
                                    .stroke(Color(red: 0.91, green: 0.91, blue: 0.91), lineWidth: 1)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .padding(.top, 0)
                }

                Spacer()
            }
            .padding()
        }
        .frame(width: 400, height: 500)
        .onChange(of: timerManager.state) { newState in
            if newState == .alert {
                startAlert()
            }
            if newState == .running {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    breathingOpacity = 0.88
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    breathingOpacity = 1.0
                }
            }
        }
        .onAppear {
            setupOverlayDismiss()
        }
    }

    // MARK: - Helpers

    private var timeString: String {
        String(format: "%02d:%02d", timerManager.displayMinutes, timerManager.displaySeconds)
    }

    private var progress: CGFloat {
        let total = TimerManager.defaultDuration
        guard total > 0 else { return 0 }
        return CGFloat((total - timerManager.remaining) / total)
    }

    private func startAlert() {
        AudioManager.shared.playChime()
        overlayManager.showOverlay()
    }

    private func setupOverlayDismiss() {
        overlayManager.onDismiss = { [weak timerManager] in
            AudioManager.shared.stop()
            timerManager?.reset()
            self.sessionCounter.increment()
        }
    }
}

