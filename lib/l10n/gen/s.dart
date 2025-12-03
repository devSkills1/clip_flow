import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 's_en.dart';
import 's_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/s.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application display name
  ///
  /// In en, this message translates to:
  /// **'Clip Flow Pro'**
  String get appName;

  /// Title for home page
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Title for App Switcher mode
  ///
  /// In en, this message translates to:
  /// **'App Switcher'**
  String get appSwitcherTitle;

  /// Title for settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings - General section title
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sectionGeneral;

  /// Settings - Security section title
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get sectionSecurity;

  /// Settings - Appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// Settings - About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// General - Auto start - title
  ///
  /// In en, this message translates to:
  /// **'Launch at startup'**
  String get generalAutoStartTitle;

  /// General - Auto start - subtitle
  ///
  /// In en, this message translates to:
  /// **'Automatically run when the system starts'**
  String get generalAutoStartSubtitle;

  /// General - Auto start toggle error message
  ///
  /// In en, this message translates to:
  /// **'Failed to update startup setting: {error}'**
  String generalAutoStartErrorMessage(String error);

  /// General - Minimize to tray - title
  ///
  /// In en, this message translates to:
  /// **'Minimize to tray'**
  String get generalMinimizeToTrayTitle;

  /// General - Minimize to tray - subtitle
  ///
  /// In en, this message translates to:
  /// **'Minimize to tray when closing the window'**
  String get generalMinimizeToTraySubtitle;

  /// General - Auto hide - title
  ///
  /// In en, this message translates to:
  /// **'Auto-hide window'**
  String get generalAutoHideTitle;

  /// General - Auto hide - subtitle
  ///
  /// In en, this message translates to:
  /// **'Hide after inactivity; works on cold start and Cmd + Option + ` toggle'**
  String get generalAutoHideSubtitle;

  /// General - Global hotkey - title
  ///
  /// In en, this message translates to:
  /// **'Global hotkey'**
  String get generalGlobalHotkeyTitle;

  /// General - Global hotkey - current value
  ///
  /// In en, this message translates to:
  /// **'Current hotkey: {hotkey}'**
  String generalGlobalHotkeySubtitle(String hotkey);

  /// General - Auto-hide hotkey - title
  ///
  /// In en, this message translates to:
  /// **'Auto-hide hotkey'**
  String get generalAutoHideHotkeyTitle;

  /// General - Auto-hide hotkey - subtitle
  ///
  /// In en, this message translates to:
  /// **'Current hotkey: {hotkey}'**
  String generalAutoHideHotkeySubtitle(String hotkey);

  /// General - Auto-hide delay - title
  ///
  /// In en, this message translates to:
  /// **'Auto-hide delay'**
  String get generalAutoHideTimeoutTitle;

  /// General - Auto-hide delay - subtitle
  ///
  /// In en, this message translates to:
  /// **'Hide after {seconds} seconds of inactivity'**
  String generalAutoHideTimeoutSubtitle(int seconds);

  /// General - Max history - title
  ///
  /// In en, this message translates to:
  /// **'Max history items'**
  String get generalMaxHistoryTitle;

  /// General - Max history - subtitle
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String generalMaxHistorySubtitle(int count);

  /// Security - Enable encryption - title
  ///
  /// In en, this message translates to:
  /// **'Enable encryption'**
  String get securityEnableEncryptionTitle;

  /// Security - Enable encryption - subtitle
  ///
  /// In en, this message translates to:
  /// **'Store sensitive data with AES-256 encryption'**
  String get securityEnableEncryptionSubtitle;

  /// Security - Enable OCR - title
  ///
  /// In en, this message translates to:
  /// **'Enable OCR'**
  String get securityEnableOcrTitle;

  /// Security - Enable OCR - subtitle
  ///
  /// In en, this message translates to:
  /// **'Automatically recognize text in images'**
  String get securityEnableOcrSubtitle;

  /// Appearance - Theme mode - title
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get appearanceThemeModeTitle;

  /// Appearance - Default display mode - title
  ///
  /// In en, this message translates to:
  /// **'Default display mode'**
  String get appearanceDefaultDisplayModeTitle;

  /// Appearance - Language - title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get appearanceLanguageTitle;

  /// Theme - Light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme - Dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Theme - System
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Display mode - Compact
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get displayCompact;

  /// Display mode - Default
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get displayNormal;

  /// Display mode - Preview
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get displayPreview;

  /// Display mode - Compact - description
  ///
  /// In en, this message translates to:
  /// **'Compact: denser list with single-line preview'**
  String get displayCompactDesc;

  /// Display mode - Normal - description
  ///
  /// In en, this message translates to:
  /// **'Normal: balanced density with regular preview'**
  String get displayNormalDesc;

  /// Display mode - Preview - description
  ///
  /// In en, this message translates to:
  /// **'Preview: larger thumbnails with detailed preview'**
  String get displayPreviewDesc;

  /// Language - Simplified Chinese
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageZhCN;

  /// Language - English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnUS;

  /// Dialog - Set global hotkey - title
  ///
  /// In en, this message translates to:
  /// **'Set global hotkey'**
  String get dialogHotkeyTitle;

  /// Dialog - Hotkey - content
  ///
  /// In en, this message translates to:
  /// **'Press the key combination you want'**
  String get dialogHotkeyContent;

  /// Dialog - Max history - title
  ///
  /// In en, this message translates to:
  /// **'Set max history items'**
  String get dialogMaxHistoryTitle;

  /// Dialog - Max history - content
  ///
  /// In en, this message translates to:
  /// **'Choose the maximum clipboard history items'**
  String get dialogMaxHistoryContent;

  /// Dialog - Max history - field label
  ///
  /// In en, this message translates to:
  /// **'History items'**
  String get dialogMaxHistoryFieldLabel;

  /// Dialog - Max history - helper text
  ///
  /// In en, this message translates to:
  /// **'Recommended range: 100-2000'**
  String get dialogMaxHistoryHelperText;

  /// Dialog - Choose theme - title
  ///
  /// In en, this message translates to:
  /// **'Choose theme mode'**
  String get dialogThemeTitle;

  /// Dialog - Choose display mode - title
  ///
  /// In en, this message translates to:
  /// **'Choose default display mode'**
  String get dialogDisplayModeTitle;

  /// Dialog - Choose language - title
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get dialogLanguageTitle;

  /// Action - Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Action - OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// About - Check updates - title
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get actionCheckUpdateTitle;

  /// About - Check updates - subtitle
  ///
  /// In en, this message translates to:
  /// **'Check the latest version'**
  String get actionCheckUpdateSubtitle;

  /// About - Feedback - title
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get actionFeedbackTitle;

  /// About - Feedback - subtitle
  ///
  /// In en, this message translates to:
  /// **'Report bugs or suggestions'**
  String get actionFeedbackSubtitle;

  /// Button label for switching to App Switcher mode
  ///
  /// In en, this message translates to:
  /// **'Switch to compact mode'**
  String get headerActionOpenAppSwitcher;

  /// Button label for returning to the traditional UI
  ///
  /// In en, this message translates to:
  /// **'Back to classic'**
  String get headerActionBackTraditional;

  /// Tooltip for the window minimize action
  ///
  /// In en, this message translates to:
  /// **'Minimize window'**
  String get windowMinimizeTooltip;

  /// Tooltip for the window close action
  ///
  /// In en, this message translates to:
  /// **'Close window'**
  String get windowCloseTooltip;

  /// About - Version - title
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersionTitle;

  /// About - Version - value
  ///
  /// In en, this message translates to:
  /// **'1.0.0'**
  String get aboutVersionValue;

  /// Home - empty state title
  ///
  /// In en, this message translates to:
  /// **'No clipboard history yet'**
  String get homeEmptyTitle;

  /// Home - empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Copy something to get started'**
  String get homeEmptySubtitle;

  /// Search empty state title
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get searchEmptyTitle;

  /// Search empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Try another keyword or adjust filters'**
  String get searchEmptySubtitle;

  /// Home - copied snackbar
  ///
  /// In en, this message translates to:
  /// **'Copied: {text}'**
  String snackCopiedPrefix(String text);

  /// Home - delete dialog - title
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get dialogDeleteTitle;

  /// Home - delete dialog - content
  ///
  /// In en, this message translates to:
  /// **'Are you sure to delete this clipboard item?\\n{text}'**
  String dialogDeleteContent(String text);

  /// Action - Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Home - preview - image
  ///
  /// In en, this message translates to:
  /// **'Image ({width} x {height}, {format})'**
  String previewImage(int width, int height, String format);

  /// Home - preview - file
  ///
  /// In en, this message translates to:
  /// **'File: {fileName}'**
  String previewFile(String fileName);

  /// Home - preview - color
  ///
  /// In en, this message translates to:
  /// **'Color: {hex}'**
  String previewColor(String hex);

  /// Home - preview - unknown format
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownFormat;

  /// Home - preview - unknown file
  ///
  /// In en, this message translates to:
  /// **'Unknown file'**
  String get unknownFile;

  /// Sidebar - filter title
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// Sidebar - type section title
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterTypeSection;

  /// Sidebar - display mode section title
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get filterDisplayModeSection;

  /// Sidebar - type - all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterTypeAll;

  /// Sidebar - type - text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get filterTypeText;

  /// Sidebar - type - rich text
  ///
  /// In en, this message translates to:
  /// **'Rich Text'**
  String get filterTypeRichText;

  /// Sidebar - type - image
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get filterTypeImage;

  /// Sidebar - type - color
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get filterTypeColor;

  /// Sidebar - type - file
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get filterTypeFile;

  /// Sidebar - type - audio
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get filterTypeAudio;

  /// Sidebar - type - video
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get filterTypeVideo;

  /// Sidebar - settings button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get filterSettingsButton;

  /// Sidebar - clear history button
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get filterClearHistoryButton;

  /// Sidebar - confirm clear dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear'**
  String get filterConfirmClearTitle;

  /// Search box hint text
  ///
  /// In en, this message translates to:
  /// **'Search clipboard history...'**
  String get searchHint;

  /// Time display - just now
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// Time display - minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeMinutesAgo(int minutes);

  /// Time display - hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours} hr ago'**
  String timeHoursAgo(int hours);

  /// Time display - days ago
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeDaysAgo(int days);

  /// Clipboard type - text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get clipTypeText;

  /// Clipboard type - rich text
  ///
  /// In en, this message translates to:
  /// **'Rich Text'**
  String get clipTypeRichText;

  /// Clipboard type - HTML
  ///
  /// In en, this message translates to:
  /// **'HTML'**
  String get clipTypeHtml;

  /// Clipboard type - image
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get clipTypeImage;

  /// Clipboard type - color
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get clipTypeColor;

  /// Clipboard type - file
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get clipTypeFile;

  /// Clipboard type - audio
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get clipTypeAudio;

  /// Clipboard type - video
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get clipTypeVideo;

  /// Clipboard type - URL
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get clipTypeUrl;

  /// Clipboard type - email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get clipTypeEmail;

  /// Clipboard type - JSON
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get clipTypeJson;

  /// Clipboard type - XML
  ///
  /// In en, this message translates to:
  /// **'XML'**
  String get clipTypeXml;

  /// Clipboard type - code
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get clipTypeCode;

  /// Performance monitor title
  ///
  /// In en, this message translates to:
  /// **'Performance Monitor'**
  String get performanceMonitor;

  /// Performance metrics reset message
  ///
  /// In en, this message translates to:
  /// **'Performance metrics reset'**
  String get performanceMetricsReset;

  /// Performance reset failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to reset performance metrics'**
  String get performanceResetFailed;

  /// Performance FPS label
  ///
  /// In en, this message translates to:
  /// **'Frame Rate (FPS)'**
  String get performanceFps;

  /// Performance memory usage label
  ///
  /// In en, this message translates to:
  /// **'Memory Usage'**
  String get performanceMemory;

  /// Performance CPU usage label
  ///
  /// In en, this message translates to:
  /// **'CPU Usage'**
  String get performanceCpu;

  /// Performance jank count label
  ///
  /// In en, this message translates to:
  /// **'Jank Count'**
  String get performanceJank;

  /// Performance database query label
  ///
  /// In en, this message translates to:
  /// **'Database Query'**
  String get performanceDbQuery;

  /// Performance clipboard capture label
  ///
  /// In en, this message translates to:
  /// **'Clipboard Capture'**
  String get performanceClipboard;

  /// Performance score label
  ///
  /// In en, this message translates to:
  /// **'Performance Score'**
  String get performanceScore;

  /// Performance good status
  ///
  /// In en, this message translates to:
  /// **'Performance Good'**
  String get performanceGood;

  /// Performance warning status
  ///
  /// In en, this message translates to:
  /// **'Performance Warning'**
  String get performanceWarning;

  /// Memory leak warning message
  ///
  /// In en, this message translates to:
  /// **'Memory leak detected'**
  String get performanceMemoryLeak;

  /// Performance optimization dialog title
  ///
  /// In en, this message translates to:
  /// **'Performance Optimization Suggestions'**
  String get performanceOptimizationTitle;

  /// Performance optimization dialog close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get performanceOptimizationClose;

  /// Performance optimization suggestions count
  ///
  /// In en, this message translates to:
  /// **'Optimization Suggestions ({count})'**
  String performanceOptimizationCount(int count);

  /// Performance recommendation - reduce animations
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Reduce complex animations and redraws'**
  String get performanceRecommendationReduceAnimations;

  /// Performance recommendation - repaint boundary
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Use RepaintBoundary to optimize rendering'**
  String get performanceRecommendationRepaintBoundary;

  /// Performance recommendation - memory leak
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Check for memory leaks'**
  String get performanceRecommendationMemoryLeak;

  /// Performance recommendation - release resources
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Release unused resources promptly'**
  String get performanceRecommendationReleaseResources;

  /// Performance recommendation - optimize CPU
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Optimize CPU-intensive operations'**
  String get performanceRecommendationOptimizeCpu;

  /// Performance recommendation - use isolate
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Use Isolate for time-consuming tasks'**
  String get performanceRecommendationUseIsolate;

  /// Performance recommendation - check main thread
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Check for main thread blocking operations'**
  String get performanceRecommendationCheckMainThread;

  /// Performance recommendation - async IO
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Use async operations for IO tasks'**
  String get performanceRecommendationAsyncIO;

  /// Performance alert - critical FPS
  ///
  /// In en, this message translates to:
  /// **'Critical: FPS too low ({fps})'**
  String performanceAlertCriticalFps(String fps);

  /// Performance alert - warning FPS
  ///
  /// In en, this message translates to:
  /// **'Warning: FPS low ({fps})'**
  String performanceAlertWarningFps(String fps);

  /// Performance alert - critical memory
  ///
  /// In en, this message translates to:
  /// **'Critical: Memory usage too high ({memory}MB)'**
  String performanceAlertCriticalMemory(String memory);

  /// Performance alert - warning memory
  ///
  /// In en, this message translates to:
  /// **'Warning: Memory usage high ({memory}MB)'**
  String performanceAlertWarningMemory(String memory);

  /// Performance alert - critical CPU
  ///
  /// In en, this message translates to:
  /// **'Critical: CPU usage too high ({cpu}%)'**
  String performanceAlertCriticalCpu(String cpu);

  /// Performance alert - warning CPU
  ///
  /// In en, this message translates to:
  /// **'Warning: CPU usage high ({cpu}%)'**
  String performanceAlertWarningCpu(String cpu);

  /// Performance monitoring stream error message
  ///
  /// In en, this message translates to:
  /// **'Performance monitoring stream error'**
  String get performanceStreamError;

  /// Performance monitoring start failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to start performance monitoring'**
  String get performanceStartFailed;

  /// Performance alert prefix
  ///
  /// In en, this message translates to:
  /// **'Performance Alert'**
  String get performanceAlert;

  /// Performance detailed stats - average frame time
  ///
  /// In en, this message translates to:
  /// **'Average Frame Time'**
  String get performanceAvgFrameTime;

  /// Performance detailed stats - jank percentage
  ///
  /// In en, this message translates to:
  /// **'Jank Percentage'**
  String get performanceJankPercentage;

  /// Performance detailed stats - frame time variance
  ///
  /// In en, this message translates to:
  /// **'Frame Time Variance'**
  String get performanceFrameTimeVariance;

  /// Performance health status - excellent
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get performanceHealthExcellent;

  /// Performance health status - good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get performanceHealthGood;

  /// Performance health status - fair
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get performanceHealthFair;

  /// Performance health status - poor
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get performanceHealthPoor;

  /// Performance health status - warming up
  ///
  /// In en, this message translates to:
  /// **'Warming Up'**
  String get performanceHealthWarmingUp;

  /// Performance health status - unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get performanceHealthUnknown;

  /// Settings - OCR - language - title
  ///
  /// In en, this message translates to:
  /// **'OCR Language'**
  String get ocrLanguageTitle;

  /// Settings - OCR - language - subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose the language used for text recognition'**
  String get ocrLanguageSubtitle;

  /// Settings - OCR - min confidence - title
  ///
  /// In en, this message translates to:
  /// **'Minimum confidence threshold'**
  String get ocrMinConfidenceTitle;

  /// Settings - OCR - min confidence - subtitle
  ///
  /// In en, this message translates to:
  /// **'Ignore results below this confidence score'**
  String get ocrMinConfidenceSubtitle;

  /// Update available dialog title
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get updateAvailableTitle;

  /// Latest version prefix
  ///
  /// In en, this message translates to:
  /// **'Latest version: '**
  String get updateLatestVersionPrefix;

  /// Release notes title
  ///
  /// In en, this message translates to:
  /// **'Release notes:'**
  String get updateReleaseNotesTitle;

  /// Update later button
  ///
  /// In en, this message translates to:
  /// **'Update later'**
  String get updateLaterAction;

  /// Download now button
  ///
  /// In en, this message translates to:
  /// **'Download now'**
  String get downloadNowAction;

  /// Settings - Storage Management section title
  ///
  /// In en, this message translates to:
  /// **'Storage Management'**
  String get sectionStorage;

  /// Storage - Application Data - title
  ///
  /// In en, this message translates to:
  /// **'Application Data'**
  String get storageAppDataTitle;

  /// Storage - Application Data - subtitle
  ///
  /// In en, this message translates to:
  /// **'Show application data directory in Finder'**
  String get storageAppDataSubtitle;

  /// Developer Options title
  ///
  /// In en, this message translates to:
  /// **'Developer Options'**
  String get developerOptionsTitle;

  /// Storage - Clean Empty Data - title
  ///
  /// In en, this message translates to:
  /// **'Clean Empty Data'**
  String get storageCleanEmptyTitle;

  /// Storage - Clean Empty Data - subtitle
  ///
  /// In en, this message translates to:
  /// **'Delete clipboard records with empty content'**
  String get storageCleanEmptySubtitle;

  /// Storage - Validate Data Integrity - title
  ///
  /// In en, this message translates to:
  /// **'Validate Data Integrity'**
  String get storageValidateTitle;

  /// Storage - Validate Data Integrity - subtitle
  ///
  /// In en, this message translates to:
  /// **'Check and repair issues in the database'**
  String get storageValidateSubtitle;

  /// Performance Overlay - title
  ///
  /// In en, this message translates to:
  /// **'Performance Overlay'**
  String get performanceOverlayTitle;

  /// Performance Overlay - subtitle
  ///
  /// In en, this message translates to:
  /// **'Show real-time performance metrics'**
  String get performanceOverlaySubtitle;

  /// Developer mode status - active
  ///
  /// In en, this message translates to:
  /// **'Developer mode activated'**
  String get developerModeActive;

  /// Developer mode status - inactive
  ///
  /// In en, this message translates to:
  /// **'Developer mode deactivated'**
  String get developerModeInactive;

  /// Max history unit
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String maxHistoryUnit(int count);

  /// Clean empty data dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Clean Empty Data'**
  String get cleanEmptyDialogTitle;

  /// Clean empty data dialog content
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all records with empty content and cannot be undone. Continue?'**
  String get cleanEmptyDialogContent;

  /// Clean success message
  ///
  /// In en, this message translates to:
  /// **'Successfully cleaned {count} empty data records'**
  String cleanSuccessMessage(int count);

  /// Clean failed message
  ///
  /// In en, this message translates to:
  /// **'Clean failed: {error}'**
  String cleanErrorMessage(String error);

  /// Data validation progress text
  ///
  /// In en, this message translates to:
  /// **'Validating data...'**
  String get validateProgressText;

  /// Data validation complete dialog title
  ///
  /// In en, this message translates to:
  /// **'Validation Complete'**
  String get validateCompleteDialogTitle;

  /// Deleted empty text records stat
  ///
  /// In en, this message translates to:
  /// **'Deleted empty text records: {count}'**
  String validateEmptyTextDeleted(int count);

  /// Deleted orphan files stat
  ///
  /// In en, this message translates to:
  /// **'Deleted orphan files: {count}'**
  String validateOrphanFilesDeleted(int count);

  /// Total valid records remaining stat
  ///
  /// In en, this message translates to:
  /// **'Total valid records remaining: {count}'**
  String validateTotalRemaining(int count);

  /// Validation failed message
  ///
  /// In en, this message translates to:
  /// **'Validation failed: {error}'**
  String validateErrorMessage(String error);

  /// Check update failed message
  ///
  /// In en, this message translates to:
  /// **'Check for update failed: {error}'**
  String checkUpdateErrorMessage(String error);

  /// Feedback dialog title
  ///
  /// In en, this message translates to:
  /// **'Feedback & Help'**
  String get feedbackDialogTitle;

  /// Email feedback title
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get feedbackEmailTitle;

  /// Feedback email address
  ///
  /// In en, this message translates to:
  /// **'jr.lu.jobs@gmail.com'**
  String get feedbackEmailAddress;

  /// Issue report title
  ///
  /// In en, this message translates to:
  /// **'Submit Issue'**
  String get feedbackIssueTitle;

  /// Issue report subtitle
  ///
  /// In en, this message translates to:
  /// **'Report a bug or suggest a feature on GitHub'**
  String get feedbackIssueSubtitle;

  /// Open feedback failed message
  ///
  /// In en, this message translates to:
  /// **'Could not open feedback channel: {error}'**
  String feedbackErrorMessage(String error);

  /// Email feedback in development message
  ///
  /// In en, this message translates to:
  /// **'Email feature is under development. Please try again later.'**
  String get feedbackEmailInDevelopment;

  /// Open email failed message
  ///
  /// In en, this message translates to:
  /// **'Could not open mail client: {error}'**
  String feedbackEmailErrorMessage(String error);

  /// Issue report in development message
  ///
  /// In en, this message translates to:
  /// **'Issue reporting feature is under development. Please try again later.'**
  String get feedbackIssueInDevelopment;

  /// Open issue page failed message
  ///
  /// In en, this message translates to:
  /// **'Could not open link: {error}'**
  String feedbackIssueErrorMessage(String error);

  /// Check update progress text
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkUpdateProgressText;

  /// Check update dialog title
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdateDialogTitle;

  /// Check update dialog content
  ///
  /// In en, this message translates to:
  /// **'You are up to date'**
  String get checkUpdateDialogContent;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
