import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 로컬 푸시 알림 서비스
/// 리텐션 알림(복귀, 데일리, 장기이탈)을 스케줄링합니다.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // 알림 ID 상수
  static const int returnReminderId = 1001;
  static const int dailyReminderId = 1002;
  static const int inactiveReminderId = 1003;

  // 야간 금지 시간 (KST)
  static const int quietHourStart = 23; // 23:00
  static const int quietHourEnd = 8; // 08:00

  /// 알림 채널 (Android)
  static const String _channelId = 'tailbound_reminders';
  static const String _channelName = '설화 알림';
  static const String _channelDescription = '게임 리마인더 알림';

  /// 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    // timezone 초기화
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint('[NotificationService] iOS permission: $result');
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final result = await android?.requestNotificationsPermission();
      debugPrint('[NotificationService] Android permission: $result');
      return result ?? false;
    }

    return false;
  }

  /// 복귀 알림 스케줄 (N시간 후)
  Future<void> scheduleReturnReminder({
    int hours = 4,
    required String title,
    required String body,
  }) async {
    final scheduledTime = _adjustForQuietHours(
      tz.TZDateTime.now(tz.local).add(Duration(hours: hours)),
    );

    await _scheduleNotification(
      id: returnReminderId,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );

    debugPrint('[NotificationService] Return reminder scheduled: $scheduledTime');
  }

  /// 데일리 알림 스케줄 (매일 지정 시간)
  Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
    required String title,
    required String body,
  }) async {
    // 야간 금지 시간대면 08시로 조정
    int adjustedHour = hour;
    if (_isQuietHour(hour)) {
      adjustedHour = quietHourEnd;
      debugPrint('[NotificationService] Daily reminder adjusted to $adjustedHour:00 (quiet hours)');
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      adjustedHour,
      minute,
    );

    // 이미 지난 시간이면 내일로
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      dailyReminderId,
      title,
      body,
      scheduledTime,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('[NotificationService] Daily reminder scheduled: $adjustedHour:${minute.toString().padLeft(2, '0')}');
  }

  /// 장기 이탈 알림 스케줄 (24시간 후)
  Future<void> scheduleInactiveReminder({
    int hours = 24,
    required String title,
    required String body,
  }) async {
    final scheduledTime = _adjustForQuietHours(
      tz.TZDateTime.now(tz.local).add(Duration(hours: hours)),
    );

    await _scheduleNotification(
      id: inactiveReminderId,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );

    debugPrint('[NotificationService] Inactive reminder scheduled: $scheduledTime');
  }

  /// 복귀 알림 취소 (앱 복귀 시)
  Future<void> cancelReturnReminder() async {
    await _plugin.cancel(returnReminderId);
    debugPrint('[NotificationService] Return reminder cancelled');
  }

  /// 장기 이탈 알림 취소
  Future<void> cancelInactiveReminder() async {
    await _plugin.cancel(inactiveReminderId);
    debugPrint('[NotificationService] Inactive reminder cancelled');
  }

  /// 모든 알림 취소
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled');
  }

  /// 특정 ID 알림 취소
  Future<void> cancelById(int id) async {
    await _plugin.cancel(id);
  }

  // === Private ===

  /// 알림 탭 콜백
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.id}');
    // 앱이 열리면서 자연스럽게 게임으로 이동
  }

  /// 야간 금지 시간대 체크
  bool _isQuietHour(int hour) {
    return hour >= quietHourStart || hour < quietHourEnd;
  }

  /// 야간 금지 시간대면 다음날 08시로 조정
  tz.TZDateTime _adjustForQuietHours(tz.TZDateTime dateTime) {
    if (_isQuietHour(dateTime.hour)) {
      // 다음날 08시로 밀기
      var adjusted = tz.TZDateTime(
        tz.local,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        quietHourEnd,
        0,
      );
      // 현재 시간이 자정 이전이면 내일로
      if (dateTime.hour >= quietHourStart) {
        adjusted = adjusted.add(const Duration(days: 1));
      }
      return adjusted;
    }
    return dateTime;
  }

  /// 알림 스케줄 (공통)
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// 알림 디테일 (Android 채널 + iOS 설정)
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
