# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Environment Setup
```bash
# Install dependencies
flutter pub get

# Enable desktop support (if needed)
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
```

### Development
```bash
# Run in development mode
flutter run

# Run with environment variables
flutter run --dart-define=ENVIRONMENT=development
```

### Building
```bash
# Build for specific platform and environment
./scripts/build.sh dev macos        # Development macOS build
./scripts/build.sh prod all         # Production build for all platforms

# Clean build
./scripts/build.sh -c dev macos     # Clean then build

# Manual Flutter builds
flutter build macos --release --dart-define=ENVIRONMENT=production
flutter build windows --release
flutter build linux --release
```

### Code Quality
```bash
# Code analysis and formatting
flutter analyze
dart format .
dart fix --apply

# Run tests
flutter test

# Dependency check
flutter pub outdated
```

### Utilities
```bash
# Version management
./scripts/version-manager.sh --version

# Clean build artifacts
flutter clean

# Clean up old applications
./scripts/cleanup_apps.sh
```

## Architecture Overview

ClipFlow Pro follows **Clean Architecture** with a **modular service layer** organized by business domains:

### Core Architecture Layers

1. **Core Layer** (`lib/core/`): Business logic, models, and modular services
2. **Feature Layer** (`lib/features/`): UI and business logic organized by features
3. **Shared Layer** (`lib/shared/`): Cross-feature widgets, providers, and utilities

### Modular Service Architecture

The service layer is organized into domain-specific modules:

- **clipboard/**: Core clipboard functionality and monitoring
- **analysis/**: Content analysis (HTML, code, semantic recognition)
- **storage/**: Data persistence, encryption, and database operations
- **platform/**: Platform-specific integrations (permissions, hotkeys, OCR, tray)
- **performance/**: Performance monitoring and async processing
- **observability/**: Logging, error handling, and crash reporting
- **operations/**: Cross-domain business operations

Each module follows the **Port-Adapter Pattern**:
- `*_ports.dart`: Defines interfaces and contracts
- Implementation classes: Concrete implementations of ports
- `index.dart`: Unified module exports

### Key Dependencies
- clipboard → analysis, storage, platform
- analysis → platform
- storage → platform/files
- operations → clipboard, analysis, storage (via ports)
- observability ← all layers (can be used by any layer)
- platform ← bottom layer (no business service dependencies)

## Technology Stack

- **Framework**: Flutter 3.19.0+ with Dart 3.9.0+
- **State Management**: Riverpod 3.0.0
- **Database**: SQLite with sqflite
- **Encryption**: AES-256-GCM via encrypt package
- **Routing**: go_router 16.2.1
- **Logging**: Custom logger system + Sentry integration
- **Architecture**: Clean Architecture + Modular Services
- **Design System**: Material Design 3 with custom theme tokens

## Project Structure

### Service Module Pattern
```
lib/core/services/[module]/
├── [module]_ports.dart          # Interface definitions
├── [module]_service.dart        # Main service implementation
├── [sub_module]/
│   ├── [sub_module]_service.dart
│   └── ...                     # Additional components
└── index.dart                   # Unified exports
```

### Feature Organization
```
lib/features/[feature]/
├── data/                        # Data layer implementations
├── domain/                      # Business logic and entities
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/                # UI layer
    ├── pages/
    └── widgets/
```

## Development Standards

### Code Quality
- **Linting**: Uses very_good_analysis with custom rules in analysis_options.yaml
- **Formatting**: dart format with single quotes and trailing commas
- **Type Safety**: Strict inference, casts, and raw types enabled
- **Performance**: const constructors preferred, rebuild boundaries optimized

### Key Patterns
- **Dependency Injection**: Use Riverpod providers with interface-based dependencies
- **Error Handling**: Force `try on Exception catch (e)` - no generic catch blocks
- **Logging**: Use `lib/core/services/logger` - never use `print()` or `debugPrint()`
- **Async**: Prefer async/await over then(), handle exceptions properly

### Testing Strategy
- Target coverage: 70% global, 80% for core modules
- Unit tests for service components
- Integration tests for end-to-end flows
- Mock/Fake for external dependencies

## Platform Considerations

### macOS
- Requires accessibility permissions for clipboard monitoring
- Uses AppInfo-Dev.xcconfig/AppInfo-Prod.xcconfig for environment configs
- Supports system tray integration

### Windows
- Uses WinRT APIs for OCR functionality
- Requires appropriate Windows API permissions

### Linux
- Requires Tesseract for OCR functionality
- Uses GTK system tray integration

## Environment Configuration

- **Development**: `--dart-define=ENVIRONMENT=development`
- **Production**: `--dart-define=ENVIRONMENT=production`
- Environment-specific configs in platform directories (macos/Runner/Configs/)

## Performance Guidelines

- Use const constructors wherever possible
- Implement proper widget rebuild boundaries
- Optimize list views with pagination and virtualization
- Monitor memory usage with performance overlay
- Use async processing queues for heavy operations