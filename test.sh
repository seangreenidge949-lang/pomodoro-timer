#!/bin/bash
# 番茄时钟快速测试：3 秒后触发全屏覆盖
set -e
PROJ_DIR="$(cd "$(dirname "$0")/PomodoroTimer" && pwd)"
cd "$PROJ_DIR"

echo "Building..."
swift build 2>&1

# Create .app bundle so macOS treats it as a proper GUI app
APP="$PROJ_DIR/.build/debug/PomodoroTimer.app"
mkdir -p "$APP/Contents/MacOS"
cp "$PROJ_DIR/.build/debug/PomodoroTimer" "$APP/Contents/MacOS/PomodoroTimer"
cp "$PROJ_DIR/PomodoroTimer/Info.plist" "$APP/Contents/Info.plist"

echo "Launching with --duration 3 (test mode)..."
open "$APP" --args --duration 3
