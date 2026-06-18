# JNTool

JNTool is a Flutter-based desktop toolkit for everyday developer workflows such as API debugging, data formatting, and code generation. It currently targets Windows and macOS desktop apps, bringing small but frequently used utilities into one lightweight workspace.

## Features

- **JSON tool**: Format, minify, validate, and inspect JSON structures in a tree view.
- **Curl request tool**: Parse curl commands, extract URL, method, headers, and body, then send HTTP requests for API debugging.
- **Bean conversion**: Generate Java Bean code from JSON, or produce sample JSON from Java Bean fields. Supports class name, package name, Lombok annotations, Jackson annotations, camelCase conversion, and field comments.
- **Cron generator**: Create Spring Boot cron expressions and preview upcoming execution times.
- **Config conversion**: Convert Spring Boot YAML and properties files in both directions while preserving edge cases such as empty string values.
- **Base64 conversion**: Convert text / images to and from Base64 for quick encoding checks.
- **Desktop experience**: Built with Flutter and includes Windows and macOS platform projects.

## Tech Stack

- Flutter 3.x
- Dart
- Provider
- Windows Desktop / macOS Desktop

## Quick Start

### Requirements

- Flutter SDK 3.0 or later
- Windows: Visual Studio 2022 Build Tools with the **Desktop development with C++** workload
- macOS: Xcode and the macOS desktop development toolchain

### Install Dependencies

```bash
cd jntool
flutter pub get
```

### Run the App

Windows:

```bash
flutter run -d windows
```

macOS:

```bash
flutter run -d macos
```

### Build the App

Windows:

```bash
flutter build windows
```

To generate the Windows installer, run the script on a Windows host with Inno Setup 6 installed:

```powershell
cd jntool
.\installer\windows\build_windows_installer.ps1
```

The installer is written to `jntool\dist\windows\JNToolSetup-1.0.0.exe`.

You can also build it in GitHub Actions: open the `Build Windows Installer` workflow, click `Run workflow`, and download the `JNToolSetup-1.0.0` artifact after the workflow finishes.

macOS:

```bash
flutter build macos
```

## Project Structure

```text
jndesktop/
├── jntool/
│   ├── lib/
│   │   ├── app.dart
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── tools/
│   │   │   ├── base64_tool/
│   │   │   ├── bean_tool/
│   │   │   ├── config_tool/
│   │   │   ├── cron_tool/
│   │   │   ├── curl_tool/
│   │   │   └── json_tool/
│   │   ├── utils/
│   │   └── widgets/
│   ├── macos/
│   ├── windows/
│   ├── test/
│   └── pubspec.yaml
├── README.md
└── README.en.md
```

## Development Checks

Before submitting changes, run:

```bash
cd jntool
flutter analyze
flutter test
```

To verify the Windows desktop build:

```bash
flutter build windows
```

## License

This project is open-sourced under the MIT License.
