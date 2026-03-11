#!/bin/bash
# 构建 PomodoroTimer.app
# 有完整 Xcode 时构建 Universal Binary (arm64 + x86_64)
# 只有 Command Line Tools 时构建当前架构
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_DIR="$SCRIPT_DIR/PomodoroTimer"
APP="$SCRIPT_DIR/PomodoroTimer.app"

# 检测是否有完整 Xcode（多架构编译需要）
if xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
    echo "==> Building Universal Binary (arm64 + x86_64)..."
    swift build -c release --arch arm64 --arch x86_64 --package-path "$PROJ_DIR" 2>&1
    BINARY="$PROJ_DIR/.build/apple/Products/Release/PomodoroTimer"
else
    echo "==> Building for current architecture (full Xcode needed for Universal Binary)..."
    swift build -c release --package-path "$PROJ_DIR" 2>&1
    BINARY="$PROJ_DIR/.build/release/PomodoroTimer"
fi

echo "==> Assembling .app bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/PomodoroTimer"
cp "$PROJ_DIR/PomodoroTimer/Info.plist" "$APP/Contents/Info.plist"
cp "$SCRIPT_DIR/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

echo "==> Architectures:"
file "$APP/Contents/MacOS/PomodoroTimer"

echo "==> Packaging .zip..."
ZIP_NAME="PomodoroTimer.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$SCRIPT_DIR/$ZIP_NAME"
echo "    Created: $SCRIPT_DIR/$ZIP_NAME"

echo ""
echo "==> Done! PomodoroTimer.app is ready."
echo "    open \"$APP\""
