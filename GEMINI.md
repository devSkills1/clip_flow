# ClipFlow Pro - Developer Guide

## Project Overview

**ClipFlow Pro** is a modern, cross-platform clipboard history manager built with Flutter. It supports macOS, Windows, and Linux, offering a minimalist, fast, and comprehensive clipboard management experience.

**Key Features:**
*   **Cross-Platform:** macOS, Windows, Linux.
*   **All-Type Support:** Text, Rich Text, Images, Files, Audio, Video, Code, HTML, RTF.
*   **Smart Features:** OCR (Optical Character Recognition), full-text search, type filtering.
*   **Security:** AES-256 encryption for sensitive data.
*   **Modern UI:** Material Design 3, responsive grid layout, multiple display modes.
*   **Performance:** Optimized for low memory usage and high frame rates.

## Technology Stack

*   **Framework:** Flutter (3.19.0+)
*   **Language:** Dart (3.9.0+)
*   **State Management:** Riverpod (3.0.0)
*   **Database:** SQLite (sqflite)
*   **Architecture:** Clean Architecture + Modular Service Layers
*   **Linting:** `very_good_analysis`

## Architecture

The project follows **Clean Architecture** principles with a modular service layer organization.

### Layer Structure
*   **Core Layer (`lib/core/`)**: Business logic and data models.
    *   **Services**: Modularized by domain (`clipboard`, `analysis`, `storage`, `platform`, `performance`, `observability`, `operations`).
    *   **Ports & Adapters**: Services define interfaces (`*_ports.dart`) which are implemented by concrete classes.
*   **Feature Layer (`lib/features/`)**: UI and business logic organized by feature (e.g., `home`, `settings`).
*   **Shared Layer (`lib/shared/`)**: Reusable widgets, providers, and constants.

### Key Patterns
*   **Dependency Injection**: Managed via Riverpod providers.
*   **Dependency Direction**: Strict layering (e.g., `clipboard` depends on `storage`, not vice-versa).
*   **ID Generation**: Centralized SHA256 hash generation via `IdGenerator.generateId()`.
*   **Deduplication**: Centralized logic in `DeduplicationService`.

## Development Guidelines

### Coding Standards
*   **Style**: Follow `very_good_analysis` rules. Use `dart format` (2 spaces, single quotes, trailing commas).
*   **Logging**: **NEVER** use `print()` or `debugPrint()`. Use the provided `lib/core/services/logger`.
*   **Error Handling**: Catch specific exceptions (`on Exception catch (e)`). Avoid generic `catch (e)`.
*   **Async**: Prefer `async/await` over `.then()`.
*   **Typing**: Enable strict inference and explicit type casts.
*   **Naming**: `snake_case` for files (`_service.dart`, `_widget.dart`).

### UI/UX Guidelines
*   **Design System**: Material Design 3.
*   **Localization**: All UI strings must be localized using `gen-l10n`.
*   **Accessibility**: WCAG 2.1 AA compliance. Support text scaling (1.0-1.5x).
*   **Performance**:
    *   Use `OptimizedImageLoader` for images.
    *   Use `const` constructors where possible.
    *   Avoid heavy computations in build methods.

## Build & Run

### Prerequisites
*   Flutter 3.19.0+
*   Dart 3.9.0+
*   Platform requirements (Xcode for macOS, VS for Windows, etc.)

### Common Commands

```bash
# Install dependencies
flutter pub get

# Run in development mode
flutter run --dart-define=ENVIRONMENT=development

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

### Scripts (`scripts/`)
*   `./scripts/build.sh`: Main build script for production binaries.
    *   Usage: `./scripts/build.sh [dev|prod] [macos|windows|linux|all]`
*   `./scripts/version-manager.sh`: Manage app versions.
*   `./scripts/cleanup_apps.sh`: Clean up build artifacts.

## Directory Structure

```
/
├── .agent/             # Agent-specific memory and summaries
├── assets/             # Static assets (icons, etc.)
├── config/             # App configuration
├── docs/               # Documentation (Architecture, APIs, Guides)
├── lib/
│   ├── core/           # Core logic (services, models, utils)
│   ├── features/       # UI features (home, settings)
│   ├── l10n/           # Localization files
│   ├── shared/         # Shared widgets and providers
│   ├── app.dart        # App entry point widget
│   └── main.dart       # Application entry point
├── scripts/            # Build and utility scripts
└── test/               # Unit, widget, and integration tests
```

## Testing Strategy

*   **Unit Tests**: Required for all service components (`test/core/`, `test/unit/`).
*   **Integration Tests**: End-to-end flows (`test/integration/`).
*   **Mocking**: Use mocks for platform channels, clipboard, and storage.

## Important Notes

*   **Hotkeys**: Managed via `HotkeyService`. Conflicts can be resolved by resetting to defaults.
*   **Database**: SQLite migrations must be handled carefully when schema changes.
*   **Security**: Do not log sensitive clipboard content.

## Agent Workflow Expectations
- Respond in Chinese while keeping any code comments in English.
- Prefer straightforward, reusable solutions and avoid over‑engineering.
- Watch cyclomatic complexity and reuse modules or helpers whenever possible.
- Apply design patterns only when they simplify modules and reinforce clear boundaries.
- Scope edits to the relevant module to avoid unnecessary cross‑feature impact.