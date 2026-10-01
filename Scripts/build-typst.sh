#!/bin/zsh
# Builds the Typst engine (Typst/, Rust) for whatever Xcode is building, and leaves
# libinkept_typst.a in $BUILT_PRODUCTS_DIR/InkeptTypst. Run by the app target before it compiles.
#
# Needs rustup with the Apple targets:
#   rustup target add aarch64-apple-ios aarch64-apple-ios-sim aarch64-apple-darwin x86_64-apple-darwin
set -euo pipefail

export PATH="$HOME/.cargo/bin:/opt/homebrew/opt/rustup/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
if ! command -v cargo >/dev/null; then
    echo "error: Rust isn't installed. Install rustup (https://rustup.rs) to build the Typst engine."
    exit 1
fi

crate="${PROJECT_DIR}/Typst"
output="${BUILT_PRODUCTS_DIR}/InkeptTypst"
mkdir -p "$output"

targets=()
for arch in ${=ARCHS}; do
    case "${PLATFORM_NAME}:${arch}" in
        iphoneos:arm64) targets+=(aarch64-apple-ios) ;;
        iphonesimulator:arm64) targets+=(aarch64-apple-ios-sim) ;;
        iphonesimulator:x86_64) targets+=(x86_64-apple-ios) ;;
        macosx:arm64) targets+=(aarch64-apple-darwin) ;;
        macosx:x86_64) targets+=(x86_64-apple-darwin) ;;
        *) echo "error: no Rust target for ${PLATFORM_NAME} ${arch}"; exit 1 ;;
    esac
done

libraries=()
for target in $targets; do
    if ! rustup target list --installed | grep -qx "$target"; then
        echo "error: the Rust target $target is missing. Run: rustup target add $target"
        exit 1
    fi
    echo "Building Typst for $target"
    # A clean environment: Xcode's SDK settings would otherwise leak into the host build scripts.
    env -i HOME="$HOME" PATH="$PATH" \
        IPHONEOS_DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-18.0}" \
        MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-15.0}" \
        cargo build --release --quiet --manifest-path "$crate/Cargo.toml" --target "$target" --lib
    libraries+=("$crate/target/$target/release/libinkept_typst.a")
done

if (( ${#libraries} == 1 )); then
    cp -f "${libraries[1]}" "$output/libinkept_typst.a.tmp"
else
    lipo -create $libraries -output "$output/libinkept_typst.a.tmp"
fi
# Only touch the library when it changed, so the app isn't relinked for nothing.
if ! cmp -s "$output/libinkept_typst.a.tmp" "$output/libinkept_typst.a"; then
    mv -f "$output/libinkept_typst.a.tmp" "$output/libinkept_typst.a"
else
    rm -f "$output/libinkept_typst.a.tmp"
fi
