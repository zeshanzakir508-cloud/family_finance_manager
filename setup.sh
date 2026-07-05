#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"
flutter config --enable-web
flutter pub get
flutter build web --release
