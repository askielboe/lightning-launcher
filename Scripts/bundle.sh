#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Lightning"
BUILD_DIR=".build/release"
BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "Sources/Resources/Info.plist" "$BUNDLE_DIR/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "$BUNDLE_DIR/Contents/PkgInfo"

# Ad-hoc codesign
codesign --force --sign - "$BUNDLE_DIR"

echo "Bundle created at: $BUNDLE_DIR"
echo "To install: cp -r $BUNDLE_DIR /Applications/"
