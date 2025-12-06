# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- User guide internationalization support

## [1.0.0] - 2024-XX-XX

### Added
- **Clipboard Management**
  - Real-time clipboard monitoring and history storage
  - Support for multiple content types: text, rich text, images, files, colors, URLs, emails, code
  - Smart content type detection and classification
  - Favorite items to prevent automatic cleanup
  - Search and filter clipboard history

- **User Interface**
  - Classic mode with full-featured interface
  - Compact mode for quick access
  - Multiple display modes: compact, normal, preview
  - Dark/Light/System theme support
  - Internationalization (English & Chinese)

- **Security**
  - Optional AES-256 encryption for sensitive data
  - Local-only data storage
  - No cloud sync or remote servers

- **OCR**
  - Automatic text recognition from images
  - Configurable recognition language
  - Adjustable confidence threshold

- **Platform Support**
  - macOS support with native integrations
  - Global hotkey for quick access
  - System tray integration
  - Launch at startup option
  - Auto-hide window feature

- **Developer Features**
  - Performance monitoring overlay
  - Data validation and cleanup tools
  - Comprehensive logging system

### Security
- All clipboard data stored locally
- Optional encryption for sensitive content
- No analytics or tracking

---

## Version History Format

### Types of Changes

- `Added` for new features
- `Changed` for changes in existing functionality
- `Deprecated` for soon-to-be removed features
- `Removed` for now removed features
- `Fixed` for any bug fixes
- `Security` for vulnerability fixes

[Unreleased]: https://github.com/Jemiking/Clip-Flow-Pro/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Jemiking/Clip-Flow-Pro/releases/tag/v1.0.0
