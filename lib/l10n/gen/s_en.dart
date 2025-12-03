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
  String get appSwitcherTitle => 'App Switcher';

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
  String generalAutoStartErrorMessage(String error) {
    return 'Failed to update startup setting: $error';
  }

  @override
  String get generalMinimizeToTrayTitle => 'Minimize to tray';

  @override
  String get generalMinimizeToTraySubtitle =>
      'Minimize to tray when closing the window';

  @override
  String get generalAutoHideTitle => 'Auto-hide window';

  @override
  String get generalAutoHideSubtitle =>
      'Hide after inactivity; works on cold start and Cmd + Option + ` toggle';

  @override
  String get generalGlobalHotkeyTitle => 'Global hotkey';

  @override
  String generalGlobalHotkeySubtitle(String hotkey) {
    return 'Current hotkey: $hotkey';
  }

  @override
  String get generalAutoHideHotkeyTitle => 'Auto-hide hotkey';

  @override
  String generalAutoHideHotkeySubtitle(String hotkey) {
    return 'Current hotkey: $hotkey';
  }

  @override
  String get generalAutoHideTimeoutTitle => 'Auto-hide delay';

  @override
  String generalAutoHideTimeoutSubtitle(int seconds) {
    return 'Hide after $seconds seconds of inactivity';
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
  String get dialogMaxHistoryHelperText => 'Recommended range: 100-2000';

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
  String get headerActionOpenAppSwitcher => 'Switch to compact mode';

  @override
  String get headerActionBackTraditional => 'Back to classic';

  @override
  String get windowMinimizeTooltip => 'Minimize window';

  @override
  String get windowCloseTooltip => 'Close window';

  @override
  String get aboutVersionTitle => 'Version';

  @override
  String get aboutVersionValue => '1.0.0';

  @override
  String get homeEmptyTitle => 'No clipboard history yet';

  @override
  String get homeEmptySubtitle => 'Copy something to get started';

  @override
  String get searchEmptyTitle => 'No matching results';

  @override
  String get searchEmptySubtitle => 'Try another keyword or adjust filters';

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

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterTypeSection => 'Type';

  @override
  String get filterDisplayModeSection => 'Display Mode';

  @override
  String get filterTypeAll => 'All';

  @override
  String get filterTypeText => 'Text';

  @override
  String get filterTypeRichText => 'Rich Text';

  @override
  String get filterTypeImage => 'Image';

  @override
  String get filterTypeColor => 'Color';

  @override
  String get filterTypeFile => 'File';

  @override
  String get filterTypeAudio => 'Audio';

  @override
  String get filterTypeVideo => 'Video';

  @override
  String get filterSettingsButton => 'Settings';

  @override
  String get filterClearHistoryButton => 'Clear History';

  @override
  String get filterClearSearchButton => 'Clear Search';

  @override
  String get filterClearAllUnfavoritedButton => 'Clear Unfavorited';

  @override
  String get filterClearAllButton => 'Clear All';

  @override
  String get filterConfirmClearTitle => 'Confirm Clear';

  @override
  String get filterConfirmClearContent =>
      'Are you sure you want to clear the history?\n\nThis will delete all [unfavorited] items and keep favorites.\nThis action cannot be undone.';

  @override
  String get searchHint => 'Search clipboard history...';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours hr ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get clipTypeText => 'Text';

  @override
  String get clipTypeRichText => 'Rich Text';

  @override
  String get clipTypeHtml => 'HTML';

  @override
  String get clipTypeImage => 'Image';

  @override
  String get formatCountThousand => 'k';

  @override
  String get formatCountTenThousand => 'k';

  @override
  String get formatCountHundredMillion => 'M';

  @override
  String get formatCountMillion => 'M';

  @override
  String get formatCountBillion => 'B';

  @override
  String get clipTypeColor => 'Color';

  @override
  String get clipTypeFile => 'File';

  @override
  String get clipTypeAudio => 'Audio';

  @override
  String get clipTypeVideo => 'Video';

  @override
  String get clipTypeUrl => 'URL';

  @override
  String get clipTypeEmail => 'Email';

  @override
  String get clipTypeJson => 'JSON';

  @override
  String get clipTypeXml => 'XML';

  @override
  String get clipTypeCode => 'Code';

  @override
  String get performanceMonitor => 'Performance Monitor';

  @override
  String get performanceMetricsReset => 'Performance metrics reset';

  @override
  String get performanceResetFailed => 'Failed to reset performance metrics';

  @override
  String get performanceFps => 'Frame Rate (FPS)';

  @override
  String get performanceMemory => 'Memory Usage';

  @override
  String get performanceCpu => 'CPU Usage';

  @override
  String get performanceJank => 'Jank Count';

  @override
  String get performanceDbQuery => 'Database Query';

  @override
  String get performanceClipboard => 'Clipboard Capture';

  @override
  String get performanceScore => 'Performance Score';

  @override
  String get performanceGood => 'Performance Good';

  @override
  String get performanceWarning => 'Performance Warning';

  @override
  String get performanceMemoryLeak => 'Memory leak detected';

  @override
  String get performanceOptimizationTitle =>
      'Performance Optimization Suggestions';

  @override
  String get performanceOptimizationClose => 'Close';

  @override
  String performanceOptimizationCount(int count) {
    return 'Optimization Suggestions ($count)';
  }

  @override
  String get performanceRecommendationReduceAnimations =>
      'Suggestion: Reduce complex animations and redraws';

  @override
  String get performanceRecommendationRepaintBoundary =>
      'Suggestion: Use RepaintBoundary to optimize rendering';

  @override
  String get performanceRecommendationMemoryLeak =>
      'Suggestion: Check for memory leaks';

  @override
  String get performanceRecommendationReleaseResources =>
      'Suggestion: Release unused resources promptly';

  @override
  String get performanceRecommendationOptimizeCpu =>
      'Suggestion: Optimize CPU-intensive operations';

  @override
  String get performanceRecommendationUseIsolate =>
      'Suggestion: Use Isolate for time-consuming tasks';

  @override
  String get performanceRecommendationCheckMainThread =>
      'Suggestion: Check for main thread blocking operations';

  @override
  String get performanceRecommendationAsyncIO =>
      'Suggestion: Use async operations for IO tasks';

  @override
  String performanceAlertCriticalFps(String fps) {
    return 'Critical: FPS too low ($fps)';
  }

  @override
  String performanceAlertWarningFps(String fps) {
    return 'Warning: FPS low ($fps)';
  }

  @override
  String performanceAlertCriticalMemory(String memory) {
    return 'Critical: Memory usage too high (${memory}MB)';
  }

  @override
  String performanceAlertWarningMemory(String memory) {
    return 'Warning: Memory usage high (${memory}MB)';
  }

  @override
  String performanceAlertCriticalCpu(String cpu) {
    return 'Critical: CPU usage too high ($cpu%)';
  }

  @override
  String performanceAlertWarningCpu(String cpu) {
    return 'Warning: CPU usage high ($cpu%)';
  }

  @override
  String get performanceStreamError => 'Performance monitoring stream error';

  @override
  String get performanceStartFailed => 'Failed to start performance monitoring';

  @override
  String get performanceAlert => 'Performance Alert';

  @override
  String get performanceAvgFrameTime => 'Average Frame Time';

  @override
  String get performanceJankPercentage => 'Jank Percentage';

  @override
  String get performanceFrameTimeVariance => 'Frame Time Variance';

  @override
  String get performanceHealthExcellent => 'Excellent';

  @override
  String get performanceHealthGood => 'Good';

  @override
  String get performanceHealthFair => 'Fair';

  @override
  String get performanceHealthPoor => 'Poor';

  @override
  String get performanceHealthWarmingUp => 'Warming Up';

  @override
  String get performanceHealthUnknown => 'Unknown';

  @override
  String get ocrLanguageTitle => 'OCR Language';

  @override
  String get ocrLanguageSubtitle =>
      'Choose the language used for text recognition';

  @override
  String get ocrMinConfidenceTitle => 'Minimum confidence threshold';

  @override
  String get ocrMinConfidenceSubtitle =>
      'Ignore results below this confidence score';

  @override
  String get updateAvailableTitle => 'New version available';

  @override
  String get updateLatestVersionPrefix => 'Latest version: ';

  @override
  String get updateReleaseNotesTitle => 'Release notes:';

  @override
  String get updateLaterAction => 'Update later';

  @override
  String get downloadNowAction => 'Download now';

  @override
  String get sectionStorage => 'Storage Management';

  @override
  String get storageAppDataTitle => 'Application Data';

  @override
  String get storageAppDataSubtitle =>
      'Show application data directory in Finder';

  @override
  String get developerOptionsTitle => 'Developer Options';

  @override
  String get storageCleanEmptyTitle => 'Clean Empty Data';

  @override
  String get storageCleanEmptySubtitle =>
      'Delete clipboard records with empty content';

  @override
  String get storageValidateTitle => 'Validate Data Integrity';

  @override
  String get storageValidateSubtitle =>
      'Check and repair issues in the database';

  @override
  String get performanceOverlayTitle => 'Performance Overlay';

  @override
  String get performanceOverlaySubtitle => 'Show real-time performance metrics';

  @override
  String get developerModeActive => 'Developer mode activated';

  @override
  String get developerModeInactive => 'Developer mode deactivated';

  @override
  String maxHistoryUnit(int count) {
    return '$count items';
  }

  @override
  String get cleanEmptyDialogTitle => 'Confirm Clean Empty Data';

  @override
  String get cleanEmptyDialogContent =>
      'This will permanently delete all records with empty content and cannot be undone. Continue?';

  @override
  String cleanSuccessMessage(int count) {
    return 'Successfully cleaned $count empty data records';
  }

  @override
  String cleanErrorMessage(String error) {
    return 'Clean failed: $error';
  }

  @override
  String get validateProgressText => 'Validating data...';

  @override
  String get validateCompleteDialogTitle => 'Validation Complete';

  @override
  String validateEmptyTextDeleted(int count) {
    return 'Deleted empty text records: $count';
  }

  @override
  String validateOrphanFilesDeleted(int count) {
    return 'Deleted orphan files: $count';
  }

  @override
  String validateTotalRemaining(int count) {
    return 'Total valid records remaining: $count';
  }

  @override
  String validateErrorMessage(String error) {
    return 'Validation failed: $error';
  }

  @override
  String checkUpdateErrorMessage(String error) {
    return 'Check for update failed: $error';
  }

  @override
  String get feedbackDialogTitle => 'Feedback & Help';

  @override
  String get feedbackEmailTitle => 'Send Email';

  @override
  String get feedbackEmailAddress => 'jr.lu.jobs@gmail.com';

  @override
  String get feedbackIssueTitle => 'Submit Issue';

  @override
  String get feedbackIssueSubtitle =>
      'Report a bug or suggest a feature on GitHub';

  @override
  String feedbackErrorMessage(String error) {
    return 'Could not open feedback channel: $error';
  }

  @override
  String get feedbackEmailInDevelopment =>
      'Email feature is under development. Please try again later.';

  @override
  String feedbackEmailErrorMessage(String error) {
    return 'Could not open mail client: $error';
  }

  @override
  String get feedbackIssueInDevelopment =>
      'Issue reporting feature is under development. Please try again later.';

  @override
  String feedbackIssueErrorMessage(String error) {
    return 'Could not open link: $error';
  }

  @override
  String get checkUpdateProgressText => 'Checking for updates...';

  @override
  String get checkUpdateDialogTitle => 'Check for updates';

  @override
  String get checkUpdateDialogContent => 'You are up to date';
}
