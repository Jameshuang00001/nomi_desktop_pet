#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
python3 naigai-desktop/package.py
app='dist/糯米桌面宠物.app'
xcrun swiftc naigai-desktop/main.swift naigai-desktop/HorizontalMotion.swift naigai-desktop/SleepPolicy.swift naigai-desktop/Droppings.swift naigai-desktop/FolderDrag.swift naigai-desktop/PositionHistory.swift -target arm64-apple-macosx13.0 -framework AppKit -framework WebKit -module-cache-path /tmp/naigai-module-cache -o "$app/Contents/MacOS/Naigai"
icon_dir=$(mktemp -d /tmp/nuomi-icon.XXXXXX)
mkdir "$icon_dir/Nuomi.iconset"
for n in 16 32 128 256 512; do
 sips -z "$n" "$n" naigai-desktop/assets/Nuomi.png --out "$icon_dir/Nuomi.iconset/icon_${n}x${n}.png" >/dev/null
 twice=$((n*2))
 sips -z "$twice" "$twice" naigai-desktop/assets/Nuomi.png --out "$icon_dir/Nuomi.iconset/icon_${n}x${n}@2x.png" >/dev/null
done
iconutil -c icns "$icon_dir/Nuomi.iconset" -o "$app/Contents/Resources/Nuomi.icns"
rm -rf "$icon_dir"
codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"
