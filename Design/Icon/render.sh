#!/bin/sh
# Renders the app icon variants with the app's own ink engine, then lays paper grain over them.
# Usage: Design/Icon/render.sh [output directory]
set -eu

root="$(cd "$(dirname "$0")/../.." && pwd)"
out="${1:-$root/inkept/Resources/Assets.xcassets/AppIcon.appiconset}"
build="$(mktemp -d)"
mkdir -p "$out"

swiftc -O -parse-as-library -o "$build/render-icon" \
    "$root/Design/Icon/RenderIcon.swift" \
    "$root/inkept/DesignSystem/Ink/InkRandom.swift" \
    "$root/inkept/DesignSystem/Ink/InkBrush.swift" \
    "$root/inkept/DesignSystem/Ink/InkGeometry.swift" \
    "$root/inkept/DesignSystem/Ink/InkShapes.swift" \
    "$root/inkept/DesignSystem/Ink/InkText.swift"

"$build/render-icon" "$out" "$root/inkept/Resources/Fonts/Neucha.ttf"
python3 "$root/Design/Icon/grain.py" "$out"
rm -rf "$build"
