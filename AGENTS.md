# Repository Guidelines

## Project Structure & Module Organization
ClipFlow Pro uses clean architecture. Feature code stays in `lib/`, with `lib/core` holding shared models, `lib/services/*` exposing clipboard/analysis/storage adapters via barrel `index.dart` files, and UI flows scoped to `lib/features`. Tests mirror this layout in `test/`. Keep media inside `assets/`, docs in `docs/` or `MIGRATION_GUIDE.md`, configuration templates under `config/`, platform shells in `macos/`, `windows/`, `linux/`, and `web/`, helper automation in `scripts/`, and generated coverage output under `coverage/`.

## Build, Test & Development Commands
- `flutter pub get` — refresh dependencies whenever `pubspec.yaml` changes.
- `flutter run -d macos|windows|linux` — debug the chosen desktop shell.
- `flutter build macos|windows|linux` — produce release binaries per platform.
- `./scripts/build.sh [--dmg|--clean]` — reproducible packaging and cleanup.
- `./scripts/release.sh` — orchestrate tagged releases.
- `./scripts/version-manager.sh --version` — confirm semantic version alignment.
- `flutter analyze` or `dart analyze` — keep static analysis clean.

## Coding Style & Naming Conventions
Run `dart format lib test` (two-space indents, trailing commas on multiline literals). Order imports with external packages before relative paths. Use PascalCase for classes/enums, camelCase for members, snake_case for files, and prefix Riverpod providers with their feature (e.g., `historyListProvider`). Favor const constructors, annotate immutable models, expose modules through `index.dart`, and source user strings via the localization workflow defined in `l10n.yaml`.

## Testing Guidelines
Mirror production files with `test/<feature>_test.dart` suites. Execute `flutter test` before each PR, regenerate coverage via `flutter test --coverage`, and review reports with `genhtml coverage/lcov.info -o coverage/html` when auditing. Use Riverpod `ProviderContainer` plus fake services for service-layer tests, golden snapshots for clipboard cards, and `await tester.pumpAndSettle()` after async UI events. Each bug fix must introduce a regression test named for the restored behavior.

## Commit & Pull Request Guidelines
Adopt Conventional Commits (`type(scope): summary`) like `docs:` or `fix(dedup):`, limiting subjects to 72 characters and keeping emoji severity markers when present. Pull requests should outline impact, verification steps, and attach relevant screenshots or clips. Reference GitHub issues in footers (`Refs #123`) and request review only after `flutter analyze`, `flutter test`, and the required build or packaging scripts succeed.

## Security & Configuration Tips
Never commit credentials, signing keys, or provisioning artifacts—store them in OS keychains and load via environment variables or helpers such as `switch-env.sh`. Files inside `config/` are templates only. To enable a new desktop target, run `flutter config --enable-<platform>-desktop` and install the OS dependencies documented in the README before building.

## Agent Workflow Expectations
- Respond in Chinese while keeping any code comments in English.
- Prefer straightforward, reusable solutions and avoid over-engineering.
- Watch cyclomatic complexity and reuse modules or helpers whenever possible.
- Apply design patterns only when they simplify modules and reinforce clear boundaries.
- Scope edits to the relevant module to avoid unnecessary cross-feature impact.
