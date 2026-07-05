#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

# ✅ DELETE pubspec.lock
rm -f pubspec.lock

# Enable web
flutter config --enable-web

# Get dependencies (this creates new pubspec.lock without google_fonts)
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Build web
flutter build web --release --no-tree-shake-icons
