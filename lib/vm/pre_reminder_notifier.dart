// pre_reminder_notifier.dart
// 미리 알림 (점심/저녁 푸시) 설정
//
// [정의] 습관별 마감 알림과 별개, "오늘 할 일 있음" 리마인드용
// [저장] AppStorage pre_reminder_enabled
// [동작] ON → schedulePreReminders, OFF → cancelPreReminders

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/util/app_storage.dart';
import 'package:habitcell/service/notification_service.dart';

/// 미리 알림 설정 Notifier
class PreReminderNotifier extends Notifier<bool> {
  @override
  bool build() {
    return AppStorage.getPreReminderEnabled();
  }

  /// 미리 알림 토글
  Future<void> toggle() async {
    final next = !state;
    state = next;
    await AppStorage.setPreReminderEnabled(next);
    debugPrint('[PreReminder] toggle: $next');
    final svc = NotificationService();
    if (next) {
      await svc.schedulePreReminders();
    } else {
      await svc.cancelPreReminders();
    }
  }
}

final preReminderNotifierProvider =
    NotifierProvider<PreReminderNotifier, bool>(PreReminderNotifier.new);
