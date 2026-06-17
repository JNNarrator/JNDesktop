# JNTool

JNTool is a Flutter-based desktop toolkit for everyday developer workflows such as API debugging, data formatting, and code generation. It currently targets Windows and macOS desktop apps, bringing small but frequently used utilities into one lightweight workspace.

## Features

- **JSON / Java Bean conversion**: Generate Java Bean code from JSON, or produce sample JSON from Java Bean fields. Supports class name, package name, Lombok annotations, Jackson annotations, camelCase conversion, and field comments.
- **Curl tool**: Parse curl commands and extract URL, method, headers, and request body for API debugging.
- **JSON tool**: Format, minify, and inspect JSON structures.
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
│   │   │   ├── bean_tool/
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
