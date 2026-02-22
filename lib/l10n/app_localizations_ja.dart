// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get exitDialogTitle => '本当に終了しますか？';

  @override
  String get exitDialogSubtitle => 'またのお越しをお待ちしています！';

  @override
  String get exitDialogCancel => '続ける';

  @override
  String get exitDialogConfirm => '終了';

  @override
  String get errorLoadingPage => 'ページの読み込みに失敗しました';

  @override
  String get errorRetry => '再試行';
}
