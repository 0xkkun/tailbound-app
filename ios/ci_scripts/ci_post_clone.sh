#!/bin/sh
set -e

# Flutter SDK 설치
echo "Installing Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Flutter 설정
flutter precache --ios
flutter pub get

# CocoaPods
cd $CI_PRIMARY_REPOSITORY_PATH/ios
pod install

# Flutter 빌드 (release)
cd $CI_PRIMARY_REPOSITORY_PATH
flutter build ios --release --no-codesign

echo "Flutter build completed!"
