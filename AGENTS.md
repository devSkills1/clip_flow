# Repository Guidelines

## Project Structure & Stack
ClipFlow targets Flutter 3.19+/Dart 3.9+. `lib/core/services/` hosts clipboard, OCR, storage, and logging layers; `lib/features/` implements UX flows with Riverpod; `lib/shared/` contains widgets/utilities; `lib/l10n/` stores generated strings. Tests live in `test/`, shared assets in `assets/`, and automation scripts in `scripts/`.

## Build, Test & Dev Commands
- `flutter pub get` — install dependencies.
- `flutter analyze` — enforce `very_good_analysis`.
- `flutter run -d macos|windows|linux` — start a desktop target.
- `flutter test --coverage` — run suites and refresh coverage.
- `./scripts/build.sh [--dmg|--clean]` — build or clean binaries.
- `./scripts/version-manager.sh --bump patch` — bump versions.

## Coding Style & Naming
Format with two-space `dart format`, single quotes, trailing commas, `const` constructors, and `final` locals. Never call `print`/`debugPrint`; use `lib/core/services/logger`. Catch concrete exceptions (`on Exception catch`) and avoid deprecated APIs. Use `snake_case.dart` filenames with descriptive suffixes (`_page.dart`, `_widget.dart`, `_service.dart`). UI strings must come from `AppLocalizations`.

## Architecture & Patterns
Apply Clean Architecture: Riverpod `Notifier`/`AsyncNotifier` providers (prefer `autoDispose`) expose services. IDs are produced only via `IdGenerator.generateId()` and deduping uses `DeduplicationService`. Long-running DB work must run inside transactions plus migrations for schema bumps. Wrap every `MethodChannel` call in `try on PlatformException catch`, and reference assets through generated accessors instead of hardcoding paths.

## UI/UX & Performance
Ship Material 3 surfaces, keep build methods small by extracting stateless widgets, and reuse `OptimizedImageLoader` for media. Maintain 60 fps by limiting rebuilds, apply blur/backdrop sparingly, and ensure WCAG 2.1 AA contrast with localized text plus platform-standard shortcuts (Enter/Esc).

## Testing Expectations
Add unit tests for new services and widget tests for complex UI under the matching `test/` subtree; integration flow tests live under `test/integration`. Mock clipboard, OCR, and storage adapters instead of platform APIs. Run `flutter test --coverage` before pushing and document curated runs inside `test/test_runner.dart`.

## Commit & PR Workflow
Commits use Conventional Commit syntax with Chinese messages (e.g., `feat(security): 加固快捷键校验`) and never mention AI tools. Pull requests must summarize intent, link issues, attach screenshots/GIFs for UI changes, and list verification commands. Tag platform owners for OS-specific edits and record security-impactful work inside `docs/` or `.gemini/project_memory.md`.

## Security & Collaboration Notes
Never log sensitive clipboard payloads or commit sample dumps. Manage secrets through `config/` templates and `switch-env.sh`, keeping signing assets outside source control. Communicate in Chinese while keeping code comments in English, prefer straightforward reusable solutions, and scope edits narrowly to avoid cross-feature churn.
