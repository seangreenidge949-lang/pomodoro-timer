// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PomodoroTimer",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PomodoroTimer",
            path: "PomodoroTimer",
            exclude: ["Info.plist", "PomodoroTimer.entitlements"],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
