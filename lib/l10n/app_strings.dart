/// 앱 문자열 (추후 flutter_localizations / arb로 전환 가능)
class AppStrings {
  AppStrings._();

  // 종료 다이얼로그
  static const Map<String, Map<String, String>> exitDialog = {
    'ko': {
      'title': '정말 종료하시나요?',
      'subtitle': '다음에 또 오실 때까지 기다릴게요!',
      'cancel': '계속하기',
      'confirm': '종료',
    },
    'en': {
      'title': 'Leaving so soon?',
      'subtitle': "We'll be waiting for your return!",
      'cancel': 'Continue',
      'confirm': 'Quit',
    },
  };

  /// 현재 언어에 맞는 종료 다이얼로그 문자열 반환
  static Map<String, String> getExitDialog(String locale) {
    return exitDialog[locale] ?? exitDialog['ko']!;
  }
}
