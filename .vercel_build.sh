#!/bin/bash
echo "Installing Flutter for Vercel Build..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Building Web Application..."
flutter pub get
flutter build web --release
