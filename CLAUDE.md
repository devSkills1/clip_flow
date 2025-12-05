# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release
flutter build macos    # or windows / linux

# Code analysis (required before merge)
flutter analyze

# Format check
dart format --output=none --set-exit-if-changed .

# Run all tests with coverage
flutter test --coverage

# Run a single test file
flutter test test/clipboard_service_test.dart

# Generate l10n files after modifying arb files
flutter gen-l10n

# Build scripts
./scripts/build.sh          # Build with signing
./scripts/build.sh --dmg    # Build macOS DMG
./scripts/build.sh --clean  # Clean build cache
```

## Architecture Overview

**Clean Architecture + Riverpod** with modular service layer:

```
lib/
├── core/services/           # Domain services (modular)
│   ├── clipboard/           # Detection → Polling → Processing → Storage
│   ├── analysis/            # Content/HTML/Code analyzers
│   ├── storage/             # Database, Encryption, Preferences, Path
│   ├── platform/            # System, Input, OCR, Tray (per-platform)
│   ├── performance/         # Monitoring, Async queue
│   ├── observability/       # Logger, CrashService, ErrorHandler
│   └── operations/          # Cross-domain business ops (UpdateService)
├── features/                # UI modules (Clean Architecture layers)
│   ├── classic/             # Classic mode (data/domain/presentation)
│   ├── compact/             # Compact mode
│   └── settings/            # Settings page
├── shared/                  # Shared widgets, providers, constants
└── l10n/                    # Internationalization
```

**Dependency Direction:**
- `clipboard → analysis, storage, platform`
- `analysis → platform`
- `storage → platform/files`
- `operations → clipboard, analysis, storage` (via ports)
- `observability ← all layers` (can be used by all)
- `platform ← bottom layer` (no business dependencies)

## Key Patterns

**Port Interface Pattern**: Each service module has `*_ports.dart` defining interfaces, implementations, and `index.dart` for unified exports.

**State Management**: Riverpod 3.x with `Notifier` pattern for type-safe dependency injection and reactive state.

**Dual UI Modes**: `DynamicHomePage` switches between classic (timeline, context menus) and compact (blur background, horizontal cards, auto-hide) modes.

## Internationalization

- ARB source: `lib/l10n/arb/app_en.arb`, `app_zh.arb`
- Generated: `lib/l10n/gen/s.dart`
- Access: `S.of(context)?.keyName` with fallback from `I18nFallbacks`
- Always run `flutter gen-l10n` after modifying ARB files

## Code Style

Uses `very_good_analysis` with strict settings:
- `strict-casts`, `strict-raw-types`, `strict-inference` enabled
- `avoid_print: error` - use `Log.*` instead
- `sort_pub_dependencies: error`
- `prefer_const_constructors`, `require_trailing_commas` enforced

## Platform-Specific Notes

- **macOS**: Requires Accessibility permission for clipboard monitoring
- **OCR**: macOS (Vision), Windows (WinRT), Linux (Tesseract) - factory pattern in `OcrServiceFactory`
- **Autostart**: macOS implemented, Windows/Linux TODO (returns false gracefully)
- Native code in `macos/`, `windows/`, `linux/` directories with `clipboard_plugin.*`

## Testing

Test files in `test/` cover clipboard, OCR, hotkeys, performance, deduplication, and integration scenarios. Mocks provided for clipboard/OCR/storage dependencies.
