// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get exitDialogTitle => '정말 종료하시나요?';

  @override
  String get exitDialogSubtitle => '다음에 또 오실 때까지 기다릴게요!';

  @override
  String get exitDialogCancel => '계속하기';

  @override
  String get exitDialogConfirm => '종료';

  @override
  String get errorLoadingPage => '페이지 로딩 실패';

  @override
  String get errorRetry => '다시 시도';
}
