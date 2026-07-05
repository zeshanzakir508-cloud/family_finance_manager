#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

# Enable web
flutter config --enable-web

# Get dependencies
flutter pub get

# ✅ Generate Hive adapters FIRST
flutter pub run build_runner build --delete-conflicting-outputs

# Then build web
flutter build web --release
