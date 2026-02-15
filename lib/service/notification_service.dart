// notification_service.dart
// Todo 마감일(dueDate) 기반 로컬 알람 - 포그라운드/백그라운드 모두 지원
//
// [기능]
// - 로컬 알람: flutter_local_notifications로 마감일 알림 예약
// - 앱 아이콘 배지: 예약된 알람 개수 표시 (app_badge_plus)
// - 앱 진입 시 배지 제거 (읽음 처리)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tagdo/model/todo.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 로컬 알람 서비스
///
/// flutter_local_notifications를 사용하여 Todo 마감일 알람을 관리합니다.
/// 1 Todo당 최대 1개의 알람만 지원합니다.
/// 포그라운드/백그라운드 모두에서 알림이 표시됩니다.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  static const String _channelId = 'tagdo_alarm_channel';
  static const String _channelName = 'TagDo 알람';
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

  /// Android 알람 ID는 32비트 제한 → todo.no를 안전한 ID로 변환
  static int _toNotificationId(int todoNo) {
    return (todoNo % 0x7FFFFFFF).abs();
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

  /// 알람 등록 (dueDate가 설정된 Todo만)
  Future<int?> scheduleNotification(Todo todo) async {
    if (todo.dueDate == null) return null;

    final dueDate = todo.dueDate!;
    final now = DateTime.now();
    if (dueDate.isBefore(now)) return null;

    final duration = dueDate.difference(now);
    if (duration.inMinutes < 1) return null;

    if (!_isInitialized) await initialize();

    final notificationId = _toNotificationId(todo.no);

    try {
      await cancelNotification(todo.no); // 기존 알람 있으면 먼저 취소

      // 배지 숫자 = 현재 예약 개수 + 이번에 추가하는 1개
      final pending = await _notifications.pendingNotificationRequests();
      final badgeNumber = pending.length + 1;

      final scheduledDate = tz.TZDateTime(
        tz.local,
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueDate.hour,
        dueDate.minute,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      // iOS: 알림 도착 시 앱 아이콘에 badgeNumber 표시
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        badgeNumber: badgeNumber,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id: notificationId,
        title: todo.content.isEmpty ? 'todoDefaultTitle'.tr() : todo.content,
        body: 'dueTimeBody'.tr(),
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: dueDate.toIso8601String(),
      );

      return todo.no;
    } catch (e) {
      debugPrint('[Notification] 알람 등록 오류: $e');
      return null;
    }
  }

  /// 알람 취소 (todoNo 전달 시 내부에서 32비트 ID로 변환)
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

  /// 과거 마감일 알람 정리 (앱 시작/포그라운드 복귀 시 main에서 호출)
  /// 마감일 지난 Todo의 알람을 취소하고 DB dueDate는 유지
  Future<void> cleanupExpiredNotifications({
    required List<Todo> todos,
    required Future<void> Function(Todo) updateTodo,
  }) async {
    final now = DateTime.now();
    for (final todo in todos) {
      if (todo.dueDate == null) continue;
      if (todo.dueDate!.isBefore(now)) {
        await cancelNotification(todo.no);
      }
    }
  }
}

