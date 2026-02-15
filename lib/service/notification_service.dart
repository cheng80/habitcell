// notification_service.dart
// 로컬 알람 - Pre-reminder(점심·저녁) + 마감 알림
//
// [기능]
// - 앱 아이콘 배지: 예약된 알람 개수 (app_badge_plus), 앱 진입 시 clearBadge
// - Pre-reminder: 점심·저녁에 오늘 습관 리마인드 (PreReminderNotifier 연동)
// - 마감 알림: deadline_reminder_time 기반 예약 (Habit별)
// - 타임존: Asia/Seoul 고정 (IANA ID, GPS 아님)

import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 마감 알림 스케줄용 항목 (호출자가 전달)
class DeadlineReminderItem {
  final String habitId;
  final String title;
  final String? deadlineReminderTime;
  final bool isCompletedToday;
  const DeadlineReminderItem(
    this.habitId,
    this.title,
    this.deadlineReminderTime,
    this.isCompletedToday,
  );
}

/// 로컬 알람 서비스
///
/// Pre-reminder + 마감 알림(deadline_reminder_time) 지원.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  static const String _channelId = 'habitcell_alarm_channel';
  static const String _channelName = 'HabitCell 알람';
  static const String _channelDescription = '할 일 마감 알림';

  /// 알람 서비스 초기화 (앱 시작 시 main에서 1회 호출)
  ///
  /// - 타임존: Asia/Seoul (스케줄 시간대)
  /// - Android: 채널 생성, 권한 요청
  /// - iOS: alert/badge/sound 권한 요청
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul')); // GPS 아님, IANA 타임존 ID

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS: 포그라운드에서도 알림 표시
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            defaultPresentAlert: true,
            defaultPresentSound: true,
            defaultPresentBadge: true,
            defaultPresentBanner: true,
            defaultPresentList: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        await _createNotificationChannel();
        await _requestAndroidNotificationPermission();
        _isInitialized = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[Notification] 초기화 오류: $e');
      return false;
    }
  }

  /// Android 알람 채널 생성 (Android 8+ 필수)
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Android 13+ 알림 권한 요청
  Future<void> _requestAndroidNotificationPermission() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('[Notification] Android 권한 요청 실패: $e');
    }
  }

  /// 알람 권한 확인
  Future<bool> checkPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 알람 권한 요청
  Future<bool> requestPermission({BuildContext? context}) async {
    if (!_isInitialized) await initialize();

    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        if (context != null && context.mounted) {
          final shouldOpen = await _showPermissionDeniedDialog(context);
          if (shouldOpen) await openAppSettings();
        } else {
          await openAppSettings();
        }
        return false;
      }
      final bool? result = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (context != null && context.mounted) {
        final shouldOpen = await _showPermissionDeniedDialog(context);
        if (shouldOpen) await openAppSettings();
      } else {
        await openAppSettings();
      }
      return false;
    }

    if (status.isDenied) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
    }

    return false;
  }

  /// 알림 권한 영구 거부 시: 설정 이동 안내 다이얼로그
  Future<bool> _showPermissionDeniedDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text('notificationPermission'.tr()),
          content: Text('notificationPermissionMessage'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('openSettings'.tr()),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  static int _toNotificationId(int id) {
    return (id % 0x7FFFFFFF).abs();
  }

  /// 예약된 알람 개수 → 앱 아이콘 배지 숫자 반영 (iOS, Android 일부 런처)
  Future<void> _updateBadgeCount(int count) async {
    try {
      await AppBadgePlus.updateBadge(count);
    } catch (_) {}
  }

  /// 앱 진입 시 배지 제거 (읽음 처리)
  Future<void> clearBadge() async {
    await _updateBadgeCount(0);
  }

  /// 알람 예약 (마감 알림 등에 사용)
  Future<int?> scheduleNotification(int id, String title, DateTime dueDate) async {
    // 마감 알림은 scheduleDeadlineReminders에서 별도 처리
    return null;
  }

  /// 습관 마감 알림 ID (habitId → 고정 ID, scheduleDeadlineReminders와 동일 규칙)
  static int _deadlineReminderId(String habitId) =>
      _toNotificationId(10000 + habitId.hashCode);

  /// 단일 습관 마감 알림 예약/취소
  /// [isCompletedToday] true면 취소, false이고 [deadlineReminderTime] 있으면 오늘 해당 시각에 예약
  Future<void> scheduleDeadlineReminderForHabit(
    String habitId,
    String title,
    String? deadlineReminderTime, {
    required bool isCompletedToday,
  }) async {
    if (!_isInitialized) await initialize();
    try {
      if (isCompletedToday || deadlineReminderTime == null) {
        await cancelDeadlineReminderForHabit(habitId);
        return;
      }
      final parts = deadlineReminderTime.split(':');
      if (parts.length < 2) return;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final now = tz.TZDateTime.now(tz.local);
      final scheduled = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!scheduled.isAfter(now)) {
        await cancelDeadlineReminderForHabit(habitId);
        return;
      }
      await _notifications.zonedSchedule(
        id: _deadlineReminderId(habitId),
        title: title,
        body: '마감 시간입니다.',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      final pending = await _notifications.pendingNotificationRequests();
      await _updateBadgeCount(pending.length);
      debugPrint('[Notification] 마감 알림 예약: $title ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('[Notification] 마감 알림 예약 오류: $e');
    }
  }

  /// 전체 습관 마감 알림 동기화 (앱 시작 시 호출)
  Future<void> scheduleDeadlineReminders(List<DeadlineReminderItem> items) async {
    if (!_isInitialized) await initialize();
    for (final item in items) {
      await scheduleDeadlineReminderForHabit(
        item.habitId,
        item.title,
        item.deadlineReminderTime,
        isCompletedToday: item.isCompletedToday,
      );
    }
  }

  /// 당일 목표 달성 시 해당 습관 마감 알림 취소
  Future<void> cancelDeadlineReminderForHabit(String habitId) async {
    try {
      await _notifications.cancel(id: _deadlineReminderId(habitId));
      final pending = await _notifications.pendingNotificationRequests();
      await _updateBadgeCount(pending.length);
    } catch (e) {
      debugPrint('[Notification] 마감 알림 취소 오류: $e');
    }
  }

  /// 알람 취소
  /// 취소 후 남은 예약 개수로 배지 업데이트
  Future<void> cancelNotification(int todoNo) async {
    try {
      await _notifications.cancel(id: _toNotificationId(todoNo));
      final pending = await _notifications.pendingNotificationRequests();
      await _updateBadgeCount(pending.length); // 배지 숫자 갱신
    } catch (e) {
      debugPrint('[Notification] 알람 취소 오류: $e');
    }
  }

  /// 모든 알람 취소 (전체 삭제 시 호출)
  /// 배지도 0으로 초기화
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      await _updateBadgeCount(0);
    } catch (e) {
      debugPrint('[Notification] 전체 알람 취소 오류: $e');
    }
  }

  /// 알람 탭 시 콜백 (추후 딥링크 등 확장 가능)
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[Notification] 알람 탭됨: id=${response.id}');
  }

  /// 예약된 알람 목록 반환 (출력 없음)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('[Notification] 알람 목록 조회 오류: $e');
      return [];
    }
  }

  /// 등록된 알람 목록 확인 (디버깅용)
  Future<List<PendingNotificationRequest>> checkPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      debugPrint('[Notification] === 등록된 알람 ${pending.length}개 ===');
      for (final p in pending) {
        final dueStr = _formatDueDateFromPayload(p.payload);
        debugPrint(
          '[Notification]   ID: ${p.id}, 제목: ${p.title}, 본문: ${p.body}'
          '${dueStr != null ? ', dueDate: $dueStr' : ''}',
        );
      }
      return pending;
    } catch (e) {
      debugPrint('[Notification] 알람 목록 확인 오류: $e');
      return [];
    }
  }

  static String? _formatDueDateFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final dt = DateTime.parse(payload);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return payload;
    }
  }

  /// 과거 알람 정리 (Habit 연동 시 구현)
  Future<void> cleanupExpiredNotifications() async {
    // TODO: Habit reminder 연동
  }

  // ─── 미리 알림 (점심/저녁 푸시) ─────────────────
  static const int _idLunch = 9001;
  static const int _idDinner = 9002;
  static const String _title = '습관을 체크해 보아요';
  static const String _body = '오늘의 습관을 확인해 보세요';

  /// 점심(12:00±30분), 저녁(19:00±30분) 푸시 스케줄
  /// 해당 시간대 1시간 내 랜덤 시각으로 예약
  /// 앱이 백그라운드일 때만 의미 있음 (포그라운드 시 main에서 취소)
  Future<void> schedulePreReminders() async {
    if (!_isInitialized) await initialize();
    try {
      final now = tz.TZDateTime.now(tz.local);
      final today = tz.TZDateTime(now.location, now.year, now.month, now.day);
      final random = Random();

      // 점심: 11:30 ~ 12:30 (30분 랜덤)
      final lunchMinuteOffset = random.nextInt(61);
      final lunch = today.add(const Duration(hours: 11, minutes: 30)).add(Duration(minutes: lunchMinuteOffset));

      // 저녁: 18:30 ~ 19:30 (30분 랜덤)
      final dinnerMinuteOffset = random.nextInt(61);
      final dinner = today.add(const Duration(hours: 18, minutes: 30)).add(Duration(minutes: dinnerMinuteOffset));

      if (lunch.isAfter(now)) {
        await _notifications.zonedSchedule(
          id: _idLunch,
          title: _title,
          body: _body,
          scheduledDate: lunch,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('[Notification] 미리알림 점심 예약: ${lunch.hour}:${lunch.minute}');
      }
      if (dinner.isAfter(now)) {
        await _notifications.zonedSchedule(
          id: _idDinner,
          title: _title,
          body: _body,
          scheduledDate: dinner,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('[Notification] 미리알림 저녁 예약: ${dinner.hour}:${dinner.minute}');
      }
    } catch (e) {
      debugPrint('[Notification] 미리알림 예약 오류: $e');
    }
  }

  /// 미리 알림 예약 취소 (포그라운드 진입 시 호출)
  Future<void> cancelPreReminders() async {
    try {
      await _notifications.cancel(id: _idLunch);
      await _notifications.cancel(id: _idDinner);
      debugPrint('[Notification] 미리알림 취소');
    } catch (e) {
      debugPrint('[Notification] 미리알림 취소 오류: $e');
    }
  }
}

