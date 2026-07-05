#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

# Force clean cache
rm -rf .dart_tool
rm -rf build
rm -f pubspec.lock

# Enable web
flutter config --enable-web

# ✅ FORCE google_fonts 4.0.4 BEFORE pub get
flutter pub add google_fonts:4.0.4

# Get dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Build web
flutter build web --release --no-tree-shake-icons
