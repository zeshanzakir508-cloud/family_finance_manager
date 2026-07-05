#!/bin/bash

# Install Flutter
if [ ! -d "/tmp/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
fi
export PATH="$PATH:/tmp/flutter/bin"

# Enable web
flutter config --enable-web

# Clean and get dependencies
flutter clean
flutter pub get

# Force update of problematic packages
flutter pub upgrade google_fonts
flutter pub upgrade

# Run build runner if needed
flutter pub run build_runner build --delete-conflicting-outputs

# Build web with release mode
flutter build web --release --no-source-maps

# Copy build output to Vercel's expected location
cp -r build/web/* .vercel/output/static/
