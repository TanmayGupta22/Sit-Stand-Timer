#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

app=".build/SitStandTimer.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/SitStandTimer "$app/Contents/MacOS/SitStandTimer"
cp Resources/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app" >/dev/null

open "$app"
