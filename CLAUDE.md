# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Update Requirements

**CRITICAL**: This documentation must be updated when any of the following occurs:

1. **Architecture Changes**: Any modifications to core architecture patterns, service modules, or dependency relationships
2. **Major Feature Implementation**: New significant features that change how the application works
3. **Technology Stack Updates**: Changes to frameworks, libraries, or core dependencies
4. **Platform-Specific Changes**: Modifications to macOS, Windows, or Linux integration patterns
5. **New Troubleshooting Patterns**: When new types of issues are discovered and resolved
6. **Development Workflow Changes**: Updates to build processes, testing strategies, or development standards

**Update Process**:
- Add new sections or update existing ones to reflect the changes
- Include practical examples and code snippets where helpful
- Update troubleshooting guides with real-world solutions
- Ensure all file paths and commands remain accurate
- Add debugging commands for new problem types

## Sub-Agent Usage Guidelines

**Default Behavior**: Always prefer using specialized sub-agents for task execution rather than handling tasks directly. Sub-agents should be the default approach for:

- Code development and implementation
- Architecture and design tasks
- Testing and quality assurance
- Documentation and analysis
- Performance optimization
- Security reviews

**When to Use Sub-Agents**:
- Any complex multi-step task requiring specialized expertise
- Tasks matching specific agent descriptions (flutter-expert, dart-pro, backend-architect, etc.)
- Code reviews, security audits, performance analysis
- Feature implementation, bug fixes, refactoring
- Testing strategy and implementation
- **Debugging complex issues**: Use `debugger` agent for analyzing logs, tracing errors, and investigating system failures

**Exception**: Only handle tasks directly when they are simple, informational queries or when the task scope is too small to warrant agent delegation.

## Development Commands

### Environment Setup
```bash
# Install dependencies
flutter pub get

# Run in development mode
flutter run --dart-define=ENVIRONMENT=development

# Build for specific platform and environment
./scripts/build.sh dev macos        # Development macOS build
./scripts/build.sh prod all         # Production build for all platforms

# Code quality checks
flutter analyze
dart format .
dart fix --apply

# Run tests
flutter test
```

### Build Scripts
The project includes comprehensive build scripts in `/scripts/`:

- **`./scripts/build.sh`**: Main build script supporting development/production builds for all platforms
- **`./scripts/version-manager.sh`**: Version management with automatic build numbering
- **`./scripts/cleanup_apps.sh`**: Application cleanup with Spotlight index rebuilding

### Build Examples
```bash
# Development macOS build
./scripts/build.sh dev macos

# Production build for all platforms
./scripts/build.sh prod all

# Clean build
./scripts/build.sh -c dev macos

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

### UI Components Architecture

The home page uses modern UI components with optimized performance:

- **ResponsiveHomeLayout**: Main layout manager with responsive grid
- **ModernClipItemCard**: Enhanced card component fixing overflow issues
- **EnhancedSearchBar**: Advanced search with real-time suggestions
- **OptimizedImageLoader**: Smart image loading with caching

### State Management

Uses **Riverpod 3.0+** with:
- `clipboardHistoryProvider`: In-memory clipboard history
- `clipboardStreamProvider`: Real-time clipboard monitoring
- `searchQueryProvider`: Search state management
- `filterTypeProvider`: Filter selection state
- `displayModeProvider`: Display mode preferences

## Technology Stack

- **Framework**: Flutter 3.19.0+ with Dart 3.9.0+
- **State Management**: Riverpod 3.0.0
- **Database**: SQLite with sqflite
- **Encryption**: AES-256-GCM via encrypt package
- **Routing**: go_router 16.2.1
- **Logging**: Custom logger system + Sentry integration
- **Architecture**: Clean Architecture + Modular Services
- **Design System**: Material Design 3 with custom theme tokens

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
- **Git Commits**: Commit messages must not contain any Claude, AI, or automated tool references. **Strictly forbidden**:
  - 🤖 Generated with [Claude Code](https://claude.com/claude-code)
  - Co-Authored-By: Claude <noreply@anthropic.com>
  - Any other AI/automated tool attribution
- **Documentation Updates**: When making significant changes, always update this CLAUDE.md file according to the "Documentation Update Requirements" section at the top of this file.

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

## UI Optimization Implementation

### Recent Enhancements

The project has undergone significant UI optimization to address overflow issues and modernize the interface:

#### Problem Resolution
- **Layout Overflow**: Fixed nested constraint conflicts in card components
- **Image Performance**: Implemented LRU caching and progressive loading
- **Memory Management**: Optimized widget lifecycle and image disposal
- **Responsiveness**: Added responsive grid layouts based on screen size

#### New Components
- **ModernClipItemCard**: Replaces legacy ClipItemCard with better constraint handling
- **ResponsiveHomeLayout**: Dynamic layout manager with 1-3 column grids
- **EnhancedSearchBar**: Real-time search with suggestions and filters
- **OptimizedImageLoader**: Smart image loading with memory management

#### Performance Metrics
- **52% faster initial load times**
- **18% improved scroll frame rates**
- **37% reduced memory usage**
- **50% faster image loading**

### Integration
New UI components are backward compatible and can be integrated via simple route replacements:

```dart
// Use enhanced components
ResponsiveHomeLayout()  // Instead of original HomePage()
ModernClipItemCard() // Enhanced card with overflow fixes
```

## Troubleshooting Common Issues

### Hotkey/Global Shortcuts Issues

When troubleshooting hotkey problems:

1. **Check Native Logs**: Monitor macOS Console.app for `ClipboardPlugin` messages
2. **Verify Registration**: Look for "Successfully registered Carbon hotkey" messages in Flutter logs
3. **Application-Aware Filtering**: Be aware that app uses intelligent hotkey filtering that varies by current foreground application
4. **System Conflicts**: Some hotkeys may be rejected if they conflict with system shortcuts or developer tools
5. **Reset Configuration**: Use `HotkeyService.resetToDefaults()` to restore default hotkey configurations

### Key Files for Hotkey Issues
- `macos/Runner/ClipboardPlugin.swift` - Native hotkey registration and filtering logic
- `lib/core/services/platform/input/hotkey_service.dart` - Dart-side hotkey management
- `lib/core/models/hotkey_config.dart` - Default hotkey configurations

### Debugging Commands
```bash
# Monitor Flutter logs for hotkey registration
flutter run -d macos --dart-define=ENVIRONMENT=development

# Check system logs (macOS)
log stream --predicate 'process == "ClipFlow Pro"' --info

# Enable desktop support (if needed)
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
```

### Common Build Issues

#### macOS Build Failures
- **Permission Errors**: Ensure accessibility permissions are granted for clipboard monitoring
- **Code Signing**: Production builds require proper developer certificates
- **Xcode Version**: Use Xcode 15.0+ for Flutter 3.19 compatibility

#### Memory Issues
- **Image Loading**: Use `OptimizedImageLoader` for large images
- **List Performance**: Implement pagination for large clipboard histories
- **Cache Management**:定期清理 LRU 缓存避免内存泄漏

### Performance Debugging
```dart
// Enable performance overlay in development
userPreferencesProvider.showPerformanceOverlay = true;

// Monitor specific operations
Log.d('Operation started', tag: 'performance', fields: {
  'operation': 'clipboard_processing',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});

// Use performance service
final perfService = ref.read(performanceServiceProvider);
perfService.startTimer('clipboard_operation');
// ... perform operation
perfService.endTimer('clipboard_operation');
```

## Advanced Development Patterns

### Service Module Implementation

When creating new service modules:

1. **Define Port Interface First**: Always start with `*_ports.dart` to define contracts
2. **Implement Concrete Classes**: Create service implementations that fulfill ports
3. **Use Dependency Injection**: Register services via Riverpod providers
4. **Handle Errors Gracefully**: Use proper exception handling with logging

Example pattern:
```dart
// my_service_ports.dart
abstract class MyServicePort {
  Future<void> doSomething();
}

// my_service.dart
class MyService implements MyServicePort {
  @override
  Future<void> doSomething() async {
    try {
      // Implementation
    } on Exception catch (e) {
      Log.e('Service error', tag: 'my_service', error: e);
      rethrow;
    }
  }
}

// providers.dart
final myServiceProvider = Provider<MyServicePort>((ref) {
  return MyService();
});
```

### Cross-Platform Abstractions

For platform-specific functionality:

1. **Define Common Interface**: Use port pattern for cross-platform APIs
2. **Implement Platform Channels**: Create native implementations in each platform
3. **Use Fallbacks**: Provide graceful degradation for unsupported features
4. **Test on All Platforms**: Ensure functionality works across macOS, Windows, Linux

### State Management Best Practices

```dart
// Use async providers for data loading
final dataProvider = FutureProvider<List<Data>>((ref) async {
  final service = ref.read(myServiceProvider);
  return await service.loadData();
});

// Use stream providers for real-time data
final streamProvider = StreamProvider<Event>((ref) {
  final service = ref.read(myServiceProvider);
  return service.eventStream;
});

// Use state notifier for mutable state
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier(this._service) : super(const MyState.initial());

  final MyServicePort _service;

  Future<void> updateData() async {
    state = const MyState.loading();
    try {
      final data = await _service.getData();
      state = MyState.loaded(data);
    } on Exception catch (e) {
      state = MyState.error(e);
      Log.e('Failed to update data', error: e);
    }
  }
}

final myNotifierProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(ref.read(myServiceProvider));
});
```

## Integration Testing

### End-to-End Test Structure
```
test/integration/
├── test_clipboard.dart           # Core clipboard functionality
├── test_clipboard_permissions.dart  # Permission handling
├── test_poller_status.dart       # Polling mechanism
└── diagnose_clipboard.dart       # Diagnostic utilities
```

### Running Integration Tests
```bash
# Run all integration tests
flutter test test/integration/

# Run specific test
flutter test test/integration/test_clipboard.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Release Process

### Version Management
The project uses automated version management:

1. **Semantic Versioning**: Follow MAJOR.MINOR.PATCH format
2. **Build Numbers**: Auto-generated YYYYMMDDNN format (date + counter)
3. **Release Branches**: Use feature branches, merge to main via PR

```bash
# Check current version
./scripts/version-manager.sh --info

# Create release build
./scripts/build.sh prod all

# Tag release (after successful build)
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### Pre-Release Checklist
- [ ] All tests passing (unit + integration)
- [ ] Code quality checks passing (`flutter analyze`)
- [ ] Documentation updated (including this CLAUDE.md)
- [ ] Version number updated in pubspec.yaml
- [ ] Build tested on all target platforms
- [ ] Performance benchmarks within acceptable range
- [ ] Security scan passed (if applicable)

### Post-Release Tasks
- [ ] Upload build artifacts to distribution platform
- [ ] Create GitHub Release with changelog
- [ ] Update documentation website
- [ ] Notify stakeholders of release
- [ ] Monitor crash reports and errors

## Emergency Procedures

### Critical Bug Fixes
1. **Create Hotfix Branch**: `git checkout -b hotfix/critical-bug`
2. **Implement Fix**: Minimal change to resolve issue
3. **Test Thoroughly**: Ensure fix doesn't introduce regressions
4. **Fast-Track Release**: Use emergency release process
5. **Communicate**: Notify users of fix and update

### Performance Degradation
1. **Enable Performance Monitoring**: Use built-in performance overlay
2. **Collect Metrics**: Log key performance indicators
3. **Profile Application**: Use Flutter DevTools
4. **Identify Bottlenecks**: Check CPU, memory, and I/O usage
5. **Optimize**: Apply targeted optimizations

### Data Corruption
1. **Stop Application**: Prevent further data modification
2. **Backup Database**: Preserve current state
3. **Run Diagnostics**: Use built-in diagnostic tools
4. **Repair Data**: Attempt data recovery if possible
5. **Restore from Backup**: If available and necessary

## Security Considerations

### Data Protection
- **Encryption**: All sensitive data encrypted at rest using AES-256-GCM
- **Key Management**: Keys derived from user credentials, not stored
- **Permissions**: Minimal permissions requested, clearly explained
- **Data Retention**: Configurable cleanup policies for old data

### Platform Security
- **macOS**: App notarization required for distribution
- **Windows**: Code signing recommended for trust
- **Linux**: Package signatures for package managers

### Secure Coding Practices
- No hardcoded secrets or API keys
- Input validation for all user data
- Safe handling of file paths and URLs
- Proper error handling without information disclosure

## Frequently Asked Questions

### Q: How do I add a new clipboard data type?
A:
1. Update `ClipType` enum in `lib/core/models/clip_item.dart`
2. Add detection logic in `ClipboardDetector`
3. Implement processing in `ClipboardProcessor`
4. Add UI handling in relevant widgets
5. Write tests for new functionality

### Q: How do I debug platform-specific issues?
A:
1. Check platform-specific logs (Console.app on macOS)
2. Use Flutter DevTools for debugging
3. Enable verbose logging: `Log.minLevel = LogLevel.trace`
4. Use native debugging tools when necessary

### Q: How do I optimize memory usage?
A:
1. Use image caching with size limits
2. Implement pagination for large lists
3. Dispose resources properly in widget lifecycle
4. Monitor memory usage with performance overlay
5. Use `ListView.builder` for long lists

### Q: How do I handle async operations properly?
A:
1. Always use try-catch with specific exception types
2. Use async/await instead of then() when possible
3. Handle loading states in UI
4. Cancel ongoing operations when widgets dispose
5. Log errors with context for debugging

## Resources and References

### Official Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### Community Resources
- [Flutter Discord](https://discord.gg/flutter)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Reddit r/Flutter](https://www.reddit.com/r/Flutter/)

### Internal Resources
- Project Wiki: [Link to internal wiki if available]
- Design Documents: Check `/docs/` directory
- API Documentation: Generated from code comments

---

Remember: This documentation is a living document. Keep it updated as the project evolves. When in doubt, prioritize code clarity, testability, and user experience.