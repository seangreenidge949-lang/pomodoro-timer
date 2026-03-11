import AppKit
import QuartzCore
import SwiftUI

/// Manages fullscreen overlay windows across all connected displays.
/// When activated:
/// - Creates borderless red windows covering every screen
/// - Disables Cmd+Tab, hides Dock/MenuBar via presentationOptions
/// - Listens for any keypress to dismiss
class AlertOverlayManager: ObservableObject {
    static let shared = AlertOverlayManager()

    @Published var isShowingOverlay = false

    private var overlayWindows: [NSWindow] = []
    private var keyMonitor: Any?
    private var globalKeyMonitor: Any?
    private var screenObserver: NSObjectProtocol?
    private var safetyTimer: Timer?
    private var savedPresentationOptions: NSApplication.PresentationOptions = []

    var onDismiss: (() -> Void)?

    func showOverlay() {
        guard !isShowingOverlay else { return }
        isShowingOverlay = true

        // Save current presentation options
        savedPresentationOptions = NSApplication.shared.presentationOptions

        // Lock system: disable process switching, hide dock/menubar
        NSApplication.shared.presentationOptions = [
            .disableProcessSwitching,
            .hideDock,
            .hideMenuBar
        ]

        // Create overlay on all screens
        createOverlayWindows()

        // Monitor screen changes (plug/unplug)
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recreateOverlayWindows()
        }

        // Monitor any key press or mouse click to dismiss (local — app is frontmost)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { [weak self] event in
            self?.dismissOverlay()
            return nil  // consume the event
        }

        // Global monitor as fallback (captures events even when app is not frontmost)
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { [weak self] _ in
            self?.dismissOverlay()
        }

        // Safety timeout: auto-dismiss after 5 minutes to prevent lockout
        safetyTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { [weak self] _ in
            self?.dismissOverlay()
        }
    }

    func dismissOverlay() {
        guard isShowingOverlay else { return }
        isShowingOverlay = false

        // Restore presentation options
        NSApplication.shared.presentationOptions = savedPresentationOptions

        // Remove monitors
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }
        safetyTimer?.invalidate()
        safetyTimer = nil
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }

        // Animate dismiss: fade out + scale down over 300ms
        for window in overlayWindows {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                window.orderOut(nil)
                window.alphaValue = 1
                self?.overlayWindows.removeAll { $0 === window }
            })
        }

        // Notify caller
        onDismiss?()
    }

    // MARK: - Window Creation

    private func createOverlayWindows() {
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen)
            overlayWindows.append(window)
        }
    }

    private func recreateOverlayWindows() {
        // Close existing
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()

        // Recreate for current screens
        if isShowingOverlay {
            createOverlayWindows()
        }
    }

    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = false

        // SwiftUI overlay content
        let overlayView = NSHostingView(rootView: AlertOverlayView())
        window.contentView = overlayView

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        return window
    }
}

// MARK: - Overlay View

struct AlertOverlayView: View {
    @State private var opacity: Double = 0
    @State private var bgColor = Color(red: 0.906, green: 0.298, blue: 0.235) // #E74C3C
    @State private var textScale: CGFloat = 1.0

    private let colorA = Color(red: 0.906, green: 0.298, blue: 0.235) // #E74C3C
    private let colorB = Color(red: 0.753, green: 0.224, blue: 0.169) // #C0392B

    var body: some View {
        ZStack {
            bgColor
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("时间到！")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(textScale)

                Text("休息一下")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Text("按任意键返回")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 40)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bgColor = colorB
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                textScale = 1.02
            }
        }
    }
}
