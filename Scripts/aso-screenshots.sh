#!/bin/zsh
# Makes the App Store screenshots in AppStore/Screenshots: runs the demo library in English on an
# iPhone 6.9″ and an iPad 13″ simulator and on this Mac, captures each scene, and lays each capture
# out with its caption (Design/AppStore/ComposeScreenshots.swift).
#
# Usage: Scripts/aso-screenshots.sh [iphone] [ipad] [mac]   (all three when none are named)
#
# The Mac scenes open the app's window on this Mac for a few seconds each. They use a copy of the
# app built without the sandbox, so it can write its window snapshots where this script reads them.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/AppStore/Screenshots"
work="${ASO_WORK:-$(mktemp -d)}"
raw="$work/raw"
devices=("$@")
(( ${#devices} )) || devices=(iphone ipad mac)
bundle=com.chemical-pink.inkept

# Each scene: a name, its launch arguments, and how long it takes to settle, in seconds.
# The plan in compose() gives each its caption.
scenes=(
    "1-study|-appearanceMode|light|-study|Linear Algebra|-studyReveal|6"
    "2-note|-appearanceMode|light|-openNote|Linear Algebra/Eigenvalues.md|5"
    "3-graph|-appearanceMode|light|-openNotes|-notesViewMode|graph|5"
    "4-board|-appearanceMode|light|-openNotes|-notesViewMode|board|5"
    "5-typst|-appearanceMode|light|-openNote|Physics/Waves.md|9"
    "6-dark|-appearanceMode|dark|-openNote|Linear Algebra/Eigenvalues.md|-showLinks|6"
)
common=(-demoLibrary -didShowRatingHelp YES -AppleLanguages "(en)" -AppleLocale en_US)

# MARK: - Simulators

# The simulator called `name`, made from `type` on the newest iOS runtime if it isn't there yet.
simulator() {
    local name=$1 type=$2
    local udid
    udid=$(xcrun simctl list devices -j | python3 -c "
import json, sys
name = sys.argv[1]
for runtime, devices in json.load(sys.stdin)['devices'].items():
    for device in devices:
        if device['name'] == name and device.get('isAvailable'):
            print(device['udid']); sys.exit()
" "$name")
    if [[ -z $udid ]]; then
        local runtime
        runtime=$(xcrun simctl list runtimes -j | python3 -c "
import json, sys
runtimes = [r for r in json.load(sys.stdin)['runtimes'] if r['platform'] == 'iOS' and r['isAvailable']]
print(sorted(runtimes, key=lambda r: [int(p) for p in r['version'].split('.')])[-1]['identifier'])
")
        udid=$(xcrun simctl create "$name" "$type" "$runtime")
    fi
    print $udid
}

# Boots `udid` in English, with the status bar every screenshot shares.
prepare_simulator() {
    local udid=$1
    xcrun simctl boot $udid 2>/dev/null || true
    xcrun simctl bootstatus $udid -b >/dev/null
    xcrun simctl spawn $udid defaults write -g AppleLanguages -array en
    xcrun simctl spawn $udid defaults write -g AppleLocale -string en_US
    # The language is read when the system starts, so it starts once more.
    xcrun simctl shutdown $udid
    xcrun simctl boot $udid
    xcrun simctl bootstatus $udid -b >/dev/null
    xcrun simctl ui $udid appearance light
    xcrun simctl status_bar $udid override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
}

capture_simulator() {
    local device=$1 name=$2 type=$3
    local udid
    udid=$(simulator "$name" "$type")
    print "▸ $device: $name ($udid)"
    local derived="$work/derived-ios"
    xcodebuild -project "$root/inkept.xcodeproj" -scheme inkept -configuration Debug \
        -destination "id=$udid" -derivedDataPath "$derived" build -quiet
    local app="$derived/Build/Products/Debug-iphonesimulator/inkept.app"
    prepare_simulator $udid
    xcrun simctl install $udid "$app"
    mkdir -p "$raw/$device"
    for scene in $scenes; do
        local parts=("${(@s:|:)scene}")
        local shot=${parts[1]} settle=${parts[-1]}
        xcrun simctl launch --terminate-running-process $udid $bundle $common "${(@)parts[2,-2]}" >/dev/null
        sleep $settle
        xcrun simctl io $udid screenshot "$raw/$device/$shot.png" >/dev/null
        print "  $shot"
    done
    xcrun simctl terminate $udid $bundle 2>/dev/null || true
    xcrun simctl status_bar $udid clear
}

# MARK: - The Mac

capture_mac() {
    print "▸ mac"
    local derived="$work/derived-mac"
    print '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict/></plist>' > "$work/none.entitlements"
    xcodebuild -project "$root/inkept.xcodeproj" -scheme inkept -configuration Debug \
        -destination 'platform=macOS,arch=arm64' -derivedDataPath "$derived" build -quiet \
        CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
        CODE_SIGN_ENTITLEMENTS="$work/none.entitlements" ENABLE_HARDENED_RUNTIME=NO
    local binary="$derived/Build/Products/Debug/inkept.app/Contents/MacOS/inkept"
    # Without the sandbox the app's temporary folder is the user's own.
    local snapshots paired index
    snapshots=$(getconf DARWIN_USER_TEMP_DIR)
    mkdir -p "$raw/mac"
    for scene in $scenes; do
        local parts=("${(@s:|:)scene}")
        local shot=${parts[1]} settle=${parts[-1]}
        local name="inkept-aso-$shot"
        local arguments=("${(@)parts[2,-2]}")
        # Beside a note on the Mac, links are a setting that's remembered; it's given here, so it isn't.
        if (( ${arguments[(Ie)-showLinks]} )); then
            arguments=("${(@)arguments:#-showLinks}" -notes.showsLinks YES)
        else
            arguments+=(-notes.showsLinks NO)
        fi
        arguments=($common $arguments)
        # AppKit reads arguments as `-key value` pairs, so a flag with nothing after it would take the next flag as
        # its value and leave a word over that the Mac opens as a document, and then no window comes up. Each gets YES.
        paired=()
        for (( index = 1; index <= ${#arguments}; index++ )); do
            paired+=("${arguments[index]}")
            if [[ ${arguments[index]} == -* && ( $index -eq ${#arguments} || ${arguments[index + 1]} == -* ) ]]; then
                paired+=(YES)
            fi
        done
        rm -f "$snapshots/$name.png"
        # Each run is closed by a signal, so macOS would otherwise try to bring back a window it never saved.
        "$binary" $paired -ApplePersistenceIgnoreState YES \
            -windowSize 1440x900 -windowSnapshot "$name" -windowSnapshotDelay $(( settle + 2 )) >/dev/null 2>&1 &
        local app=$!
        for _ in {1..40}; do
            [[ -f "$snapshots/$name.png" ]] && break
            sleep 1
        done
        sleep 1
        kill $app 2>/dev/null || true
        wait $app 2>/dev/null || true
        mv "$snapshots/$name.png" "$raw/mac/$shot.png"
        print "  $shot"
    done
}

# MARK: - Captions

compose() {
    local composer="$work/compose-screenshots"
    swiftc -O -parse-as-library -o "$composer" \
        "$root/Design/AppStore/ComposeScreenshots.swift" \
        "$root/inkept/DesignSystem/Ink/InkRandom.swift" \
        "$root/inkept/DesignSystem/Ink/InkBrush.swift" \
        "$root/inkept/DesignSystem/Ink/InkGeometry.swift" \
        "$root/inkept/DesignSystem/Ink/InkShapes.swift" \
        "$root/inkept/DesignSystem/Ink/InkText.swift" \
        "$root/inkept/DesignSystem/Ink/InkFlower.swift"
    python3 - "$raw" "$out" "$work/plan.json" "${devices[@]}" <<'PLAN'
import json, os, sys

raw, out, plan_path, *devices = sys.argv[1:]
captions = {
    "1-study": ("Remember it, right before you'd forget", "Flashcards with FSRS spaced repetition"),
    "2-note": ("Notes in Markdown, neat as you type", "Formulas, code, pictures and checklists"),
    "3-graph": ("See how your notes connect", "A living graph, in the spirit of Obsidian"),
    "4-board": ("Every subject at a glance", "Each page opens with its first picture or formula"),
    "5-typst": ("Draw with Typst, right in a note", "Plots and diagrams, made on your device"),
    "6-dark": ("Your files, by day and by night", "No account · no tracking · free and open source"),
}
# The size App Store Connect asks for, and how round the screen's corners are.
sizes = {"iphone": (1320, 2868, 0.13), "ipad": (2064, 2752, 0.02), "mac": (2880, 1800, 0.018)}
plan = []
for device in devices:
    width, height, corner = sizes[device]
    for index, (shot, (headline, subline)) in enumerate(captions.items()):
        source = os.path.join(raw, device, shot + ".png")
        if not os.path.exists(source):
            continue
        plan.append({
            "input": source,
            "output": os.path.join(out, device, shot + ".png"),
            "width": width, "height": height,
            "headline": headline, "subline": subline,
            "dark": shot == "6-dark", "flower": index == 0,
            "corner": corner, "seed": 11 + index * 7,
        })
json.dump(plan, open(plan_path, "w"), indent=1)
print(f"{len(plan)} screenshots planned")
PLAN
    "$composer" "$work/plan.json" "$root/inkept/Resources/Fonts/Neucha.ttf"
}

for device in $devices; do
    case $device in
        iphone) capture_simulator iphone "inkept-ASO-iPhone-17-Pro-Max" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max ;;
        ipad) capture_simulator ipad "inkept-ASO-iPad-Pro-13" com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB ;;
        mac) capture_mac ;;
        *) print "unknown device: $device"; exit 1 ;;
    esac
done
compose
print "▸ done: $out"
