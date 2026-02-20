// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get exitDialogTitle => 'Leaving so soon?';

  @override
  String get exitDialogSubtitle => 'We\'ll be waiting for your return!';

  @override
  String get exitDialogCancel => 'Continue';

  @override
  String get exitDialogConfirm => 'Quit';

  @override
  String get errorLoadingPage => 'Failed to load page';

  @override
  String get errorRetry => 'Retry';

  @override
  String get notificationReturnTitle => 'The Shaman awaits your return';

  @override
  String get notificationReturnBody =>
      'The Demon Gate is opening again. Come back and hold the line!';

  @override
  String get notificationDailyTitle => 'Today\'s challenge awaits';

  @override
  String get notificationDailyBody => 'The world of Seolhwa is calling you.';

  @override
  String get notificationInactiveTitle => 'Death\'s Envoy is calling';

  @override
  String get notificationInactiveBody =>
      'The Demon Gate grew stronger while you were away. Time to return!';
}
