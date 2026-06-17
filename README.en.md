# JNTool

JNTool is a macOS desktop development tool application built with Flutter, designed to provide developers with convenient code generation and data processing functionalities.

## Features

- **Bean Generator**: Quickly generate Java/Flutter Bean classes and configuration panels
- **Curl Tool**: Parse curl commands and support HTTP request simulation and debugging
- **JSON Tool**: Parse, format, and visually display JSON data in a tree structure

## Technology Stack

- **Framework**: Flutter 3.x
- **Platform**: macOS
- **State Management**: Provider
- **Programming Language**: Dart

## Project Structure

```
jntool/
├── lib/
│   ├── app.dart              # Application entry
│   ├── main.dart             # Main function
│   ├── models/               # Data models
│   ├── providers/            # State management
│   ├── screens/              # Screen pages
│   ├── tools/                # Tool modules
│   │   ├── bean_tool/        # Bean generator tool
│   │   ├── curl_tool/        # Curl parser tool
│   │   └── json_tool/        # JSON processing tool
│   ├── utils/                # Utility classes
│   └── widgets/              # Common widgets
├── macos/                    # macOS native configuration
├── test/                     # Unit tests
└── pubspec.yaml              # Dependency configuration
```

## Quick Start

### Prerequisites

- Flutter SDK (>=3.0.0)
- macOS 10.14+

### Install Dependencies

```bash
cd jntool
flutter pub get
```

### Run the Project

```bash
flutter run -d macos
```

### Build the Application

```bash
flutter build macos
```

## Feature Details

### Bean Generator

Provides a visual configuration panel for Bean classes, supporting custom field types, annotations, and more, to generate standardized code templates.

### Curl Tool

- Parse curl command strings
- Convert to HTTP request configurations
- Support for multiple HTTP methods and request headers

### JSON Tool

- Format and compress JSON
- Tree-structured visualization
- Bidirectional conversion between JSON and Dart models

## Contribution Guidelines

Issues and pull requests are welcome. Please ensure tests are passed before submitting:

```bash
flutter test
```

## License

This project is open-sourced under the MIT License.