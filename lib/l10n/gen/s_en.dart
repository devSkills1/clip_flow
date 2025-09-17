// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Clip Flow Pro';

  @override
  String get homeTitle => 'Home';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionGeneral => 'General';

  @override
  String get sectionSecurity => 'Security';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionAbout => 'About';

  @override
  String get generalAutoStartTitle => 'Launch at startup';

  @override
  String get generalAutoStartSubtitle =>
      'Automatically run when the system starts';

  @override
  String get generalMinimizeToTrayTitle => 'Minimize to tray';

  @override
  String get generalMinimizeToTraySubtitle =>
      'Minimize to tray when closing the window';

  @override
  String get generalGlobalHotkeyTitle => 'Global hotkey';

  @override
  String generalGlobalHotkeySubtitle(String hotkey) {
    return 'Current hotkey: $hotkey';
  }

  @override
  String get generalMaxHistoryTitle => 'Max history items';

  @override
  String generalMaxHistorySubtitle(int count) {
    return '$count items';
  }

  @override
  String get securityEnableEncryptionTitle => 'Enable encryption';

  @override
  String get securityEnableEncryptionSubtitle =>
      'Store sensitive data with AES-256 encryption';

  @override
  String get securityEnableOcrTitle => 'Enable OCR';

  @override
  String get securityEnableOcrSubtitle =>
      'Automatically recognize text in images';

  @override
  String get appearanceThemeModeTitle => 'Theme mode';

  @override
  String get appearanceDefaultDisplayModeTitle => 'Default display mode';

  @override
  String get appearanceLanguageTitle => 'Language';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get displayCompact => 'Compact';

  @override
  String get displayNormal => 'Default';

  @override
  String get displayPreview => 'Preview';

  @override
  String get displayCompactDesc =>
      'Compact: denser list with single-line preview';

  @override
  String get displayNormalDesc =>
      'Normal: balanced density with regular preview';

  @override
  String get displayPreviewDesc =>
      'Preview: larger thumbnails with detailed preview';

  @override
  String get languageZhCN => 'Simplified Chinese';

  @override
  String get languageEnUS => 'English';

  @override
  String get dialogHotkeyTitle => 'Set global hotkey';

  @override
  String get dialogHotkeyContent => 'Press the key combination you want';

  @override
  String get dialogMaxHistoryTitle => 'Set max history items';

  @override
  String get dialogMaxHistoryContent =>
      'Choose the maximum clipboard history items';

  @override
  String get dialogMaxHistoryFieldLabel => 'History items';

  @override
  String get dialogThemeTitle => 'Choose theme mode';

  @override
  String get dialogDisplayModeTitle => 'Choose default display mode';

  @override
  String get dialogLanguageTitle => 'Choose language';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionOk => 'OK';

  @override
  String get actionCheckUpdateTitle => 'Check for updates';

  @override
  String get actionCheckUpdateSubtitle => 'Check the latest version';

  @override
  String get actionFeedbackTitle => 'Send feedback';

  @override
  String get actionFeedbackSubtitle => 'Report bugs or suggestions';

  @override
  String get aboutVersionTitle => 'Version';

  @override
  String get aboutVersionValue => '1.0.0';

  @override
  String get homeEmptyTitle => 'No clipboard history yet';

  @override
  String get homeEmptySubtitle => 'Copy something to get started';

  @override
  String snackCopiedPrefix(String text) {
    return 'Copied: $text';
  }

  @override
  String get dialogDeleteTitle => 'Confirm delete';

  @override
  String dialogDeleteContent(String text) {
    return 'Are you sure to delete this clipboard item?\\n$text';
  }

  @override
  String get actionDelete => 'Delete';

  @override
  String previewImage(int width, int height, String format) {
    return 'Image ($width x $height, $format)';
  }

  @override
  String previewFile(String fileName) {
    return 'File: $fileName';
  }

  @override
  String previewColor(String hex) {
    return 'Color: $hex';
  }

  @override
  String get unknownFormat => 'Unknown';

  @override
  String get unknownFile => 'Unknown file';
}
