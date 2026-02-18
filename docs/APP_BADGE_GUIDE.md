# 앱 아이콘 배지 가이드 (app_badge_plus)

HabitCell 앱에서 **예약된 알람 개수**를 앱 아이콘 배지로 표시하는 기능에 대한 문서입니다.

---

## 목차

1. [개요](#개요)
2. [패키지 정보](#패키지-정보)
3. [동작 방식](#동작-방식)
4. [구현 흐름](#구현-흐름)
5. [주요 API](#주요-api)
6. [플랫폼 지원](#플랫폼-지원)
7. [변경 이력](#변경-이력)

---

## 개요

HabitCell은 `app_badge_plus` 패키지를 사용해 **예약된 마감 알림 개수**를 앱 아이콘 배지 숫자로 표시합니다.

| 시점 | 동작 |
|------|------|
| 마감 알림 예약 | `pendingNotificationRequests().length` → 배지 숫자 반영 |
| 마감 알림 취소 | 남은 예약 개수로 배지 갱신 |
| 앱 진입(포그라운드) | `clearBadge()` 호출로 배지 0 (읽음 처리) |

---

## 패키지 정보

### pubspec.yaml

```yaml
dependencies:
  # 앱 아이콘 배지 (예약 알람 개수 표시)
  app_badge_plus: ^1.2.6
```

- **용도**: 앱 아이콘에 배지 숫자 직접 설정
- **연동**: `flutter_local_notifications`의 `pendingNotificationRequests()` 결과와 동기화

---

## 동작 방식

### 배지 숫자 계산

배지 숫자 = **현재 예약된 로컬 알람 개수**

```dart
final pending = await _notifications.pendingNotificationRequests();
await _updateBadgeCount(pending.length);
```

### 갱신 시점

| 시점 | 호출 위치 | 동작 |
|------|-----------|------|
| 마감 알림 예약 후 | `scheduleDeadlineReminderForHabit()` | `_updateBadgeCount(pending.length)` |
| 마감 알림 취소 후 | `cancelDeadlineReminderForHabit()` | `_updateBadgeCount(pending.length)` |
| 알람 취소 후 | `cancelNotification()` | `_updateBadgeCount(pending.length)` |
| 앱 진입 시 | `main.dart` → `_performInitialCleanup()` | `clearBadge()` → 배지 0 |
| 포그라운드 복귀 시 | `didChangeAppLifecycleState(resumed)` | `clearBadge()` → 배지 0 |

---

## 구현 흐름

### 1. 배지 업데이트 (내부)

```dart
/// 예약된 알람 개수 → 앱 아이콘 배지 숫자 반영 (iOS, Android 일부 런처)
Future<void> _updateBadgeCount(int count) async {
  try {
    await AppBadgePlus.updateBadge(count);
  } catch (_) {}
}
```

### 2. 배지 제거 (앱 진입 시)

```dart
/// 앱 진입 시 배지 제거 (읽음 처리)
Future<void> clearBadge() async {
  await _updateBadgeCount(0);
}
```

### 3. 마감 알림 예약 시 배지 갱신

```dart
// scheduleDeadlineReminderForHabit() 내부
await _notifications.zonedSchedule(...);
final pending = await _notifications.pendingNotificationRequests();
await _updateBadgeCount(pending.length);
```

### 4. 마감 알림 취소 시 배지 갱신

```dart
// cancelDeadlineReminderForHabit() 내부
await _notifications.cancel(id: _deadlineReminderId(habitId));
final pending = await _notifications.pendingNotificationRequests();
await _updateBadgeCount(pending.length);
```

---

## 주요 API

| 메서드 | 설명 | 호출 위치 |
|--------|------|-----------|
| `clearBadge()` | 배지를 0으로 설정 (읽음 처리) | main.dart (앱 시작, 포그라운드 복귀) |
| `_updateBadgeCount(int)` | 배지 숫자 직접 설정 (내부) | 알람 예약/취소 후 |

---

## 플랫폼 지원

| 플랫폼 | 지원 | 비고 |
|--------|------|------|
| iOS | ✅ | 기본 지원 |
| Android | ⚠️ | 일부 런처만 지원 (삼성, Xiaomi 등) |

---

## 변경 이력

### f95ec319 (2026-02-15) - Initial commit

- `app_badge_plus: ^1.2.6` 추가
- `notification_service.dart`에 배지 로직 구현
  - `_updateBadgeCount()`: 예약 개수 → 배지 숫자
  - `clearBadge()`: 앱 진입 시 배지 제거
  - `scheduleNotification()`: Todo 마감일 알람 등록 시 `badgeNumber = pending.length + 1`
  - `cancelNotification()`: 취소 후 남은 개수로 배지 갱신

### 6441d06b (2026-02-15) - TagDo → HabitCell 전환

- Todo 기반 마감일 알람 → Habit 기반 마감 알림으로 리팩터링
- 배지 관련 로직 유지: `_updateBadgeCount`, `clearBadge`, 취소 후 배지 갱신

### 이후 (HabitCell 마감 알림 완성)

- `scheduleDeadlineReminderForHabit()`: 습관별 마감 알림 예약 후 `_updateBadgeCount(pending.length)`
- `cancelDeadlineReminderForHabit()`: 취소 후 `_updateBadgeCount(pending.length)`
- Pre-reminder(점심/저녁)는 배지에 포함되지 않음 (앱 진입 시 취소되므로)

---

## 참고

- [app_badge_plus pub.dev](https://pub.dev/packages/app_badge_plus)
- [NOTIFICATION_SETUP.md](./NOTIFICATION_SETUP.md) - 로컬 알람 전체 설정 가이드
