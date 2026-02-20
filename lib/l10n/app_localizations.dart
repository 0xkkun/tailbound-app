import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('ko'),
  ];

  /// 앱 종료 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'정말 종료하시나요?'**
  String get exitDialogTitle;

  /// 앱 종료 확인 다이얼로그 부제목
  ///
  /// In ko, this message translates to:
  /// **'다음에 또 오실 때까지 기다릴게요!'**
  String get exitDialogSubtitle;

  /// 종료 취소 버튼
  ///
  /// In ko, this message translates to:
  /// **'계속하기'**
  String get exitDialogCancel;

  /// 종료 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get exitDialogConfirm;

  /// WebView 페이지 로딩 실패 메시지
  ///
  /// In ko, this message translates to:
  /// **'페이지 로딩 실패'**
  String get errorLoadingPage;

  /// 재시도 버튼
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get errorRetry;

  /// 복귀 알림 제목
  ///
  /// In ko, this message translates to:
  /// **'무녀가 기다리고 있어요'**
  String get notificationReturnTitle;

  /// 복귀 알림 본문
  ///
  /// In ko, this message translates to:
  /// **'귀문이 다시 열리고 있어요. 돌아와서 막아주세요!'**
  String get notificationReturnBody;

  /// 데일리 알림 제목
  ///
  /// In ko, this message translates to:
  /// **'오늘의 도전이 기다립니다'**
  String get notificationDailyTitle;

  /// 데일리 알림 본문
  ///
  /// In ko, this message translates to:
  /// **'설화 속 세계가 당신을 부르고 있어요.'**
  String get notificationDailyBody;

  /// 장기이탈 알림 제목
  ///
  /// In ko, this message translates to:
  /// **'저승사자가 부르고 있어요'**
  String get notificationInactiveTitle;

  /// 장기이탈 알림 본문
  ///
  /// In ko, this message translates to:
  /// **'오래 비웠더니 귀문이 더 강해졌어요. 돌아올 때가 됐어요!'**
  String get notificationInactiveBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
