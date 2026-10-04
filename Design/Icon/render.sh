#!/bin/sh
# Renders the app icon with the app's own ink engine into the Icon Composer document: the flower
# in each appearance — light, dark and tinted — and the grained paper it lies on in the light one.
# Usage: Design/Icon/render.sh [Icon Composer document]
set -eu

root="$(cd "$(dirname "$0")/../.." && pwd)"
document="${1:-$root/inkept/Resources/AppIcon.icon}"
layers="$document/Assets"
build="$(mktemp -d)"
mkdir -p "$layers"

swiftc -O -parse-as-library -o "$build/render-icon" \
    "$root/Design/Icon/RenderIcon.swift" \
    "$root/inkept/DesignSystem/Ink/InkRandom.swift" \
    "$root/inkept/DesignSystem/Ink/InkBrush.swift" \
    "$root/inkept/DesignSystem/Ink/InkGeometry.swift" \
    "$root/inkept/DesignSystem/Ink/InkShapes.swift" \
    "$root/inkept/DesignSystem/Ink/InkText.swift" \
    "$root/inkept/DesignSystem/Ink/InkFlower.swift"

"$build/render-icon" "$layers"
python3 "$root/Design/Icon/grain.py" "$layers"
rm -rf "$build"
