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
}
