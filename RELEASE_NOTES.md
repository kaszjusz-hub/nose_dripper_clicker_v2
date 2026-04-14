# Nose Dripper Clicker v2 - Release Notes

## Version: 0.1.0 (Build 14042026)
- Combo progress bar restored on main screen
- Upgrade panel made scrollable to prevent overflow
- Syntax fixes in nose_screen.dart
- Built with Flutter 3.41.6, Dart 3.11.4

## Assets
- Universal Release APK: build/app/outputs/flutter-apk/app-release.apk (~45.5 MB)
- Android App Bundle: build/app/outputs/bundle/release/app-release.aab (~38.6 MB)
- Split ABI APKs (recommended for installation):
  - armeabi-v7a: ~13.0 MB (32-bit ARM)
  - arm64-v8a: ~15.5 MB (64-bit ARM)
  - x86_64: ~16.8 MB (64-bit x86)

## Installation
For Poco X6 Pro (arm64-v8a):
1. Download: releases/nose_dripper_clicker_v2_arm64-v8a.apk
2. Enable "Install from unknown sources" in Android settings
3. Transfer APK to device and install

For other devices, choose the matching ABI:
- armeabi-v7a: older 32-bit ARM devices
- arm64-v8a: newer 64-bit ARM devices (recommended for most modern phones)
- x86_64: Intel/AMD chips (less common in phones)

## Notes
- The debug APK (app-debug.apk) is ~148 MB and includes development symbols
- Release versions are significantly smaller due to tree-shaking and minification
- Font resources reduced by 99.9% via tree-shaking
- Split APKs reduce download size by ~65-70% vs universal APK

## Next Steps
- Implement proper asset bundling to further reduce size
- Add ProGuard/R8 rules for release builds
- Consider using flutter build apk --split-per-abi for smaller individual APKs
- Automate release process with GitHub Actions