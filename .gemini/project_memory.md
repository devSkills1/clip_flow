# Project Memory: Clip Flow Pro

## 1. Project Overview
**Name:** `clip_flow_pro`
**Description:** Cross-platform clipboard history management tool.
**Target Platforms:** macOS, Windows, Linux.
**Version:** 1.0.0+1

## 2. Tech Stack
*   **Framework:** Flutter (SDK ^3.9.0), Dart.
*   **State Management:** Flutter Riverpod.
*   **Database:** Sqflite (Local SQL database).
*   **Routing:** GoRouter.
*   **Desktop Integration:**
    *   `window_manager`: Window control.
    *   `tray_manager`: System tray integration.
    *   `screen_retriever`: Screen information.
    *   `hotkey_manager` (Inferred from conversation history).
*   **Clipboard & Content:**
    *   `clipboard`: Basic clipboard access.
    *   `image`, `image_picker`: Image processing.
    *   `ocr` (Custom implementation or library inferred from context).
*   **Networking:** Dio, Http.
*   **Utils:** Encrypt, Crypto, UUID, Shared Preferences.

## 3. Key Features
*   **Clipboard History:** Tracks text and images copied to the clipboard.
*   **Cross-Platform:** Consistent experience across desktop OSs.
*   **Deduplication:** Intelligent handling of duplicate clipboard entries (Text & Image).
*   **OCR Support:** Extracts text from copied images.
*   **Search & Organize:** Efficient retrieval of past clipboard items.

## 4. Project Structure
*   `lib/`: Main source code.
    *   `core/`: Shared services, models, utils, constants.
    *   `features/`: Feature-specific code (UI, Logic).
    *   `shared/`: Shared UI components or widgets.
    *   `l10n/`: Localization files.
    *   `main.dart`: Entry point.
*   `macos/`, `windows/`, `linux/`: Platform-specific native code.
*   `.gemini/`: Project documentation and agent memory.

## 5. Recent Development Status (as of Nov 2025)
### Completed/In-Progress Tasks
*   **Deduplication Vulnerabilities:**
    *   Addressed P0, P1, and P2 level issues.
    *   Fixed UI double-update issues.
    *   Standardized OCR text handling.
    *   Unified ID generation logic.
    *   See `.gemini/deduplication_vulnerabilities.md` for details.
*   **Clipboard Copy Debugging:**
    *   Investigated regression in `setClipboardImage` and `setClipboardFile` (macOS).
    *   Focus on `ClipboardPlugin.swift`.
*   **Startup Issues:**
    *   Fixed "Black Screen" on startup.
    *   Fixed `HotkeyService` initialization error (`Bad state: No element`).

## 6. Important Commands
*   **Run Dev:** `flutter run`
*   **Get Dependencies:** `flutter pub get`
*   **Run Tests:** `flutter test`
*   **Build:** `flutter build macos` / `windows` / `linux`

## 7. Documentation Index
*   [Deduplication Vulnerabilities](.gemini/deduplication_vulnerabilities.md)
*   [P0 Fixes Summary](.gemini/p0_fixes_summary.md)
*   [P1 Fixes Summary](.gemini/p1_fixes_summary.md)
*   [P2 Fixes Summary](.gemini/p2_fixes_summary.md)
