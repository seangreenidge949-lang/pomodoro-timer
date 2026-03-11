# PomodoroTimer

A native macOS Pomodoro timer app built with SwiftUI. Minimal, beautiful, and distraction-free.

<img src="docs/screenshot.png" width="400" alt="PomodoroTimer Screenshot">

## Install

### Download (Recommended)

1. Go to [Releases](../../releases/latest) and download `PomodoroTimer-vX.X.zip`
2. Unzip and drag `PomodoroTimer.app` to your **Applications** folder
3. **First launch**: Right-click the app → **Open** → click **Open** in the dialog

> The app is not signed with an Apple Developer certificate, so macOS Gatekeeper will block double-click on first launch. The right-click → Open workaround only needs to be done once.

### Build from Source

Requires macOS 13+ and Swift 5.9+.

```bash
git clone https://github.com/seangreenidge949-lang/pomodoro-timer.git
cd pomodoro-timer
./build.sh
open PomodoroTimer.app
```

## Features

- 25/5/15 min Pomodoro cycles with auto-progression
- Ambient background sounds (rain, fire, cafe, etc.)
- Menu bar presence with timer display
- Minimal, native macOS design
- Universal Binary (Apple Silicon + Intel)

## License

MIT
