// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get exitDialogTitle => '确定要退出吗？';

  @override
  String get exitDialogSubtitle => '我们会等你回来的！';

  @override
  String get exitDialogCancel => '继续';

  @override
  String get exitDialogConfirm => '退出';

  @override
  String get errorLoadingPage => '页面加载失败';

  @override
  String get errorRetry => '重试';
}
