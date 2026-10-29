#!/bin/zsh
set -eu
cd "$(dirname "$0")"
work_dir=$(mktemp -d /tmp/nomi-tests.XXXXXX)
trap 'rm -rf "$work_dir"' EXIT
for name in gaze roam sleep potty folder; do node "naigai-desktop/test-$name.cjs"; done
for pair in 'HorizontalMotion motion' 'SleepPolicy sleep' 'Droppings droppings' 'PositionHistory position-history'; do
 parts=(${=pair})
 xcrun swiftc "naigai-desktop/${parts[1]}.swift" "naigai-desktop/test-${parts[2]}.swift" -framework AppKit -module-cache-path "$work_dir/cache" -o "$work_dir/${parts[2]}"
 "$work_dir/${parts[2]}"
done
