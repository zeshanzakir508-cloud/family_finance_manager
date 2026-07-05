#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

# Enable web
flutter config --enable-web

# Clean cache
rm -rf .dart_tool
rm -rf build
rm -f pubspec.lock

# Get dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Build web
flutter build web --release --no-tree-shake-icons
