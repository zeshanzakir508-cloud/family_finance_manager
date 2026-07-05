#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

# ✅ Clear cache to force fresh dependency resolution
rm -rf .dart_tool
rm -rf build
rm -rf pubspec.lock

# Enable web
flutter config --enable-web

# Get dependencies with fresh resolution
flutter pub get

# ✅ Force specific google_fonts version
flutter pub upgrade google_fonts

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Build web
flutter build web --release --no-tree-shake-icons
