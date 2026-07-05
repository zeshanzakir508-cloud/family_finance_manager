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

# NUCLEAR CLEAN - Remove EVERYTHING
flutter clean
rm -f pubspec.lock
rm -rf .dart_tool
rm -rf build
rm -rf ~/.pub-cache

# Get dependencies with fresh cache
flutter pub get

# Build
flutter build web --release --no-source-maps

# Copy to Vercel
mkdir -p .vercel/output/static
cp -r build/web/* .vercel/output/static/
