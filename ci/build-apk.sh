#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "$0")/.." && pwd)
upstream_root="$project_root/upstream"
expected_commit=a9f6542fa507a841f40ab4f3fcb531427cd02550
test "$(git -C "$upstream_root" rev-parse HEAD)" = "$expected_commit"
git -C "$upstream_root" diff --exit-code
git -C "$upstream_root" apply --check "$project_root/patches/galaxy-xr-client.patch"
git -C "$upstream_root" apply "$project_root/patches/galaxy-xr-client.patch"

sdk_dir="${ANDROID_HOME:?The runner must provide an Android SDK}"
unset ANDROID_SDK_ROOT
sudo apt-get update
sudo apt-get install -y ripgrep unzip
"$sdk_dir/cmdline-tools/latest/bin/sdkmanager" 'platforms;android-35' 'build-tools;35.0.0' 'ndk;27.2.12479018'
export ANDROID_NDK_HOME="$sdk_dir/ndk/27.2.12479018"
rustup toolchain install 1.97.1 --profile minimal --target aarch64-linux-android
cargo +1.97.1 install --locked --git https://github.com/zarik5/cargo-apk \
  --rev 0fd3126dad5aa1c5f0f26cdae3410f2e5af62c60 cargo-apk

# Galaxy XR uses the generic Khronos loader. Do not package unrelated vendor loaders.
loader_dir="$upstream_root/deps/android_openxr/arm64-v8a"
mkdir -p "$loader_dir" "$project_root/dist"
loader_archive="$RUNNER_TEMP/openxr-1.1.36.aar"
curl --fail --location --retry 3 \
  https://github.com/KhronosGroup/OpenXR-SDK-Source/releases/download/release-1.1.36/openxr_loader_for_android-1.1.36.aar \
  --output "$loader_archive"
unzip -p "$loader_archive" prefab/modules/openxr_loader/libs/android.arm64-v8a/libopenxr_loader.so \
  > "$loader_dir/libopenxr_loader.so"
test -s "$loader_dir/libopenxr_loader.so"

cd "$upstream_root"
export RUSTFLAGS="--remap-path-prefix=$HOME=/builder --remap-path-prefix=$project_root=/src"
# Cargo clears RUSTFLAGS when launching a program through `cargo run`.
# Run the compiled xtask directly so cargo-apk inherits the privacy flags.
export RUSTUP_TOOLCHAIN=1.97.1
# Native dependencies can retain compiler directories in DWARF even when Rust
# paths are remapped. Strip debug metadata, not runtime code or license notices.
export CARGO_PROFILE_RELEASE_STRIP=debuginfo
cargo +1.97.1 build -p alvr_xtask
"$upstream_root/target/debug/alvr_xtask" build-client --release
apk="$upstream_root/build/alvr_client_android/alvr_client_android.apk"
"$sdk_dir/build-tools/35.0.0/apksigner" verify "$apk"

# Inspect all unpacked entries, not only the client library. Fail without printing matches.
audit_dir=$(mktemp -d "$RUNNER_TEMP/galaxy-xr-audit.XXXXXX")
unzip -q "$apk" -d "$audit_dir"
if rg --text --quiet --fixed-strings -e "$HOME/" -e "$project_root/" "$audit_dir"; then
  echo 'APK audit failed: unremapped builder paths remain.' >&2
  exit 1
fi
if rg --text --quiet '(/Users/|[A-Za-z]:\\Users\\|192\.168\.)' "$audit_dir"; then
  echo 'APK audit failed: a known local identifier pattern remains.' >&2
  exit 1
fi

cp "$apk" "$project_root/dist/Galaxy-XR-ALVR.apk"
cp "$project_root/"{LICENSE,README.md,START-HERE.txt,SETUP.txt,Connect-USB.ps1,ALVR-Unblock.ps1,BUILD-PRIVACY.txt,ACTIONS.txt} "$project_root/dist/"
curl --fail --location --retry 3 \
  https://raw.githubusercontent.com/KhronosGroup/OpenXR-SDK-Source/release-1.1.36/LICENSE \
  --output "$project_root/dist/OpenXR-LICENSE.txt"
cd "$project_root/dist"
sha256sum Galaxy-XR-ALVR.apk > SHA256SUMS.txt
printf 'Project version: Beta 0.2 stable baseline\nALVR version: 20.14.1\nPackage: alvr.client.stabletest\nProject commit: %s\nALVR commit: %s\nOpenXR loader: 1.1.36\nSigning: ephemeral Android debug key; test only\n' \
  "$GITHUB_SHA" "$expected_commit" > BUILD-INFO.txt
