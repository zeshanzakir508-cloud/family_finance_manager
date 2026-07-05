#!/bin/bash
set -e

# Install Flutter
if [ ! -d "/tmp/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
fi

export PATH="$PATH:/tmp/flutter/bin"
export FLUTTER_ROOT="/tmp/flutter"

# Enable web
flutter config --enable-web

# Clean everything
flutter clean
rm -f pubspec.lock

# Force correct google_fonts version
flutter pub add google_fonts:8.1.0

# Get all dependencies
flutter pub get

# Build
flutter build web --release --no-source-maps

# Copy to Vercel
mkdir -p .vercel/output/static
cp -r build/web/* .vercel/output/static/
