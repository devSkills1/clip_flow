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
