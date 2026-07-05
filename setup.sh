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

# Nuclear clean
flutter clean
rm -f pubspec.lock
rm -rf .dart_tool
rm -rf build
rm -rf ~/.pub-cache

# Create fresh pubspec with ALL dependencies and forced google_fonts
cat > pubspec.yaml << 'EOF'
name: family_finance_manager
description: A Family Finance Manager app
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  google_fonts: 8.1.0
  firebase_core: 2.27.0
  firebase_auth: 4.17.8
  cloud_firestore: 4.15.8
  firebase_storage: 11.6.9
  firebase_remote_config: 4.3.17
  fl_chart: 0.66.2
  flutter_cache_manager: 3.4.0
  provider: 6.1.2
  shared_preferences: 2.2.3
  sqflite: 2.4.1
  intl: 0.18.1
  path_provider: 2.1.5
  image_picker: 1.1.2
  permission_handler: 11.4.0
  connectivity_plus: 5.0.2
  share_plus: 7.2.2
  url_launcher: 6.3.1
  device_info_plus: 9.1.2
  package_info_plus: 5.0.1
  flutter_local_notifications: 17.2.4
  http: 1.2.0
  equatable: 2.0.8
  csv: 5.1.1
  mockito: 5.4.4
  timezone: 0.9.4
  flutter_launcher_icons: 0.13.1
  google_mobile_ads: 4.0.0
  in_app_purchase: 3.2.3
  local_auth: 2.3.0
  webview_flutter: 4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: 3.0.2
  build_runner: 2.4.13
  analyzer: 14.0.0
  hive_generator: 2.0.1

flutter:
  uses-material-design: true
  assets:
    - assets/

dependency_overrides:
  google_fonts: 8.1.0
  analyzer: 14.0.0
EOF

# Get dependencies
flutter pub get

# Build
flutter build web --release --no-source-maps

# Copy to Vercel
mkdir -p .vercel/output/static
cp -r build/web/* .vercel/output/static/
