# spell_strike

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Hi

114/04/11 2:50PM 更新
在pubspec.yaml中新增了錄音和請求權限的插件
新增了lib\services\recording.dart
在main.dart中導入、創建、初始化錄音器(_audioRecorder)
android\app\build.gradle.kts中的 minSdk從flutter.minSdkVersion改為24，因為flutter_sound插件不支援原本的21版本
錄音檔位置：/data/user/0/com.example.spell_strike/cache/，recording.dart中有對應獲取位址的功能
