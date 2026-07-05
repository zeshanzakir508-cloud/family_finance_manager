#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

# ✅ FORCE CLEAN CACHE - THIS IS THE KEY FIX
rm -rf .dart_tool
rm -rf build
rm -f pubspec.lock

# Enable web
flutter config --enable-web

# Get dependencies with fresh resolution
flutter pub get

# ✅ FORCE google_fonts 6.1.0 (overrides pubspec.lock)
flutter pub add google_fonts:6.1.0

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Build web
flutter build web --release --no-tree-shake-icons
