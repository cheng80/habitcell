# 알람(로컬 노티피케이션) 설정 가이드

이 문서는 TagDo 앱의 로컬 알람 기능 설정에 대한 상세 가이드를 제공합니다.

## 목차

1. [개요](#개요)
2. [패키지 의존성](#패키지-의존성)
3. [Android 설정](#android-설정)
4. [iOS 설정](#ios-설정)
5. [코드 설정](#코드-설정)
6. [사용 방법](#사용-방법)
7. [주요 파라미터 설명](#주요-파라미터-설명)
8. [앱 아이콘 배지 (iOS)](#앱-아이콘-배지-ios)
9. [트러블슈팅](#트러블슈팅)

---

## 개요

TagDo 앱은 `flutter_local_notifications` 패키지를 사용하여 로컬 알람 기능을 구현합니다.

**주요 특징:**
- 1 Todo당 최대 1개의 알람만 지원 (dueDate 기반)
- Android와 iOS 모두 지원
- 정확한 시간에 알람 발송 (exact alarm)
- **포그라운드와 백그라운드 모두에서 알림 표시**
- 앱이 종료된 상태에서도 알람 작동
- 재부팅 후에도 알람 스케줄 유지
- **앱 아이콘 배지**: 예약된 알람 개수 표시 (iOS, 로컬 푸시로 구현)

---

## 패키지 의존성

### pubspec.yaml

```yaml
dependencies:
  flutter_local_notifications: ^20.0.0
  timezone: ^0.10.0
  permission_handler: ^12.0.1
  flutter_app_badger: ^1.5.0
```

**설명:**
- `flutter_local_notifications`: 로컬 알람 기능 제공
- `timezone`: 시간대 처리 및 스케줄링
- `permission_handler`: 권한 상태 확인 및 관리 (Android 13+ 권한 처리)
- `app_badge_plus`: 앱 아이콘 배지 숫자 직접 설정 (iOS, Android 일부 런처)

---

## Android 설정

### 1. AndroidManifest.xml

**파일 위치:** `android/app/src/main/AndroidManifest.xml`

#### 1.1 권한 설정

```xml
<!-- 알람 권한 (Android 12 이하) -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- 알림 권한 (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- 정확한 알람 권한 (Android 12 이하) -->
<uses-permission 
    android:name="android.permission.SCHEDULE_EXACT_ALARM"
    android:maxSdkVersion="32"/>

<!-- 알람 및 리마인더 권한 (Android 13+) -->
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>

<!-- 진동 권한 -->
<uses-permission android:name="android.permission.VIBRATE"/>

<!-- 화면 켜짐 유지 권한 -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<!-- 전체 화면 인텐트 권한 -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

**권한 설명:**

| 권한 | 용도 | Android 버전 |
|------|------|--------------|
| `RECEIVE_BOOT_COMPLETED` | 재부팅 후 알람 스케줄 복원 | 모든 버전 |
| `POST_NOTIFICATIONS` | 알림 표시 | Android 13+ (API 33+) |
| `SCHEDULE_EXACT_ALARM` | 정확한 시간 알람 | Android 12 이하 (API 32 이하) |
| `USE_EXACT_ALARM` | 정확한 시간 알람 | Android 13+ (API 33+) |
| `VIBRATE` | 알람 진동 | 모든 버전 |
| `WAKE_LOCK` | 화면 켜짐 유지 | 모든 버전 |
| `USE_FULL_SCREEN_INTENT` | 전체 화면 알림 | 모든 버전 |

#### 1.2 Receiver 설정

```xml
<application>
    <!-- 스케줄된 알람 처리 -->
    <receiver
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
        android:exported="false"/>
    
    <!-- 재부팅 후 알람 스케줄 복원 -->
    <receiver
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
        android:exported="false">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED"/>
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
            <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
        </intent-filter>
    </receiver>
</application>
```

**Receiver 설명:**

- **ScheduledNotificationReceiver**: 스케줄된 알람을 처리하는 리시버
- **ScheduledNotificationBootReceiver**: 재부팅 후 알람 스케줄을 복원하는 리시버
  - `BOOT_COMPLETED`: 일반 재부팅
  - `MY_PACKAGE_REPLACED`: 앱 업데이트 시
  - `QUICKBOOT_POWERON`: 빠른 부팅 (일부 제조사)

#### 1.3 Activity 설정

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:showWhenLocked="true"
    android:turnScreenOn="true">
    <!-- ... -->
</activity>
```

**Activity 속성 설명:**

- `showWhenLocked="true"`: 잠금 화면에서도 알림 표시
- `turnScreenOn="true"`: 알림 수신 시 화면 자동 켜기

### 2. build.gradle.kts

**파일 위치:** `android/app/build.gradle.kts`

#### 2.1 Core Library Desugaring 설정

```kotlin
android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

**설명:**
- `flutter_local_notifications` 패키지가 Java 8+ API를 사용하므로 desugaring이 필요합니다.
- 최소 버전: `2.1.4` 이상

---

## iOS 설정

### Info.plist (필요시)

iOS는 기본적으로 추가 설정이 필요하지 않지만, 특정 기능을 사용하려면 `Info.plist`에 권한 설명을 추가할 수 있습니다.

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

---

## 코드 설정

### 1. main.dart 초기화

**파일 위치:** `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 알람 서비스 초기화
  final notificationService = NotificationService();
  await notificationService.initialize();
  // main에서는 context가 없으므로 권한만 요청
  // (영구 거부 시 다이얼로그는 표시하지 않음)
  await notificationService.requestPermission();

  runApp(const MyApp());
}
```

**설명:**
- `WidgetsFlutterBinding.ensureInitialized()`: 비동기 초기화 전 필수
- `initialize()`: 알람 서비스 초기화
- `requestPermission()`: 알람 권한 요청
  - `context` 파라미터가 없으면 영구 거부 시 다이얼로그 없이 바로 설정으로 이동
  - `context` 파라미터가 있으면 영구 거부 시 안내 다이얼로그 표시 후 설정으로 이동

### 2. NotificationService 클래스

**파일 위치:** `lib/service/notification_service.dart`

#### 2.1 초기화 설정

```dart
Future<bool> initialize() async {
  // Timezone 초기화
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  // Android 초기화 설정
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS 초기화 설정
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  // 통합 초기화 설정
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  // 알람 초기화
  final bool? initialized = await _notifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  if (initialized == true) {
    await _createNotificationChannel();
    _isInitialized = true;
    return true;
  }
  return false;
}
```

**설정 설명:**

- **Timezone**: `Asia/Seoul`로 설정 (한국 시간대)
- **Android 아이콘**: `@mipmap/ic_launcher` 사용
- **iOS 권한**: 초기화 시 권한 요청 (`requestAlertPermission`, `requestBadgePermission`, `requestSoundPermission`)

#### 2.2 알람 채널 생성 (Android)

```dart
Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'tagdo_alarm_channel',       // 채널 ID
    'TagDo 알람',                // 채널 이름
    description: '할 일 마감 알림',  // 채널 설명
    importance: Importance.high,  // 중요도
    playSound: true,              // 소리 재생
    enableVibration: true,        // 진동 활성화
  );

  await _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}
```

**채널 설정 설명:**

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| `channelId` | `daily_flow_alarm_channel` | 고유 채널 식별자 |
| `channelName` | `DailyFlow 알람` | 사용자에게 보이는 채널 이름 |
| `description` | `일정 알람 알림` | 채널 설명 |
| `importance` | `Importance.high` | 높은 중요도 (헤드업 알림) |
| `playSound` | `true` | 소리 재생 활성화 |
| `enableVibration` | `true` | 진동 활성화 |

---

## 사용 방법

### 1. 알람 등록

```dart
final notificationService = NotificationService();
final int? notificationId = await notificationService.scheduleNotification(todo);
```

**알람 등록 조건:**
- `todo.hasAlarm == true`
- `todo.time != null`
- 알람 시간이 현재 시간보다 미래

### 3. 알람 취소

```dart
await notificationService.cancelNotification(notificationId);
```

### 4. 알람 업데이트

```dart
await notificationService.updateNotification(todo);
```

**동작:**
1. 기존 알람 취소
2. 새 알람 등록

### 5. 모든 알람 취소

```dart
await notificationService.cancelAllNotifications();
```

### 6. 등록된 알람 목록 확인 (디버깅)

```dart
await notificationService.checkPendingNotifications();
```

---

## 주요 파라미터 설명

### 1. zonedSchedule 파라미터

```dart
await _notifications.zonedSchedule(
  notificationId,              // 알람 ID (고유값)
  title,                       // 알람 제목
  body,                        // 알람 내용
  scheduledDate,               // TZDateTime (예약 시간)
  notificationDetails,         // 알람 상세 설정
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: null,  // null = 일회성 알람
);
```

**androidScheduleMode 옵션:**

| 모드 | 설명 | 우선순위 |
|------|------|----------|
| `exactAllowWhileIdle` | 정확한 시간, 절전 모드에서도 작동 | 1순위 |
| `exact` | 정확한 시간 | 2순위 |
| `inexactAllowWhileIdle` | 대략적인 시간, 절전 모드에서도 작동 | 3순위 |

**matchDateTimeComponents 옵션:**

| 값 | 설명 |
|----|------|
| `null` | 일회성 알람 |
| `DateTimeComponents.time` | 매일 동일 시간 |
| `DateTimeComponents.dayOfWeekAndTime` | 매주 동일 요일/시간 |
| `DateTimeComponents.dayOfMonthAndTime` | 매월 동일 날짜/시간 |

### 2. NotificationDetails 설정

#### Android 설정

```dart
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'tagdo_alarm_channel',       // 채널 ID
  'TagDo 알람',                // 채널 이름
  channelDescription: '할 일 마감 알림',
  importance: Importance.high,  // 중요도
  priority: Priority.high,      // 우선순위
  playSound: true,              // 소리 재생
  enableVibration: true,         // 진동 활성화
);
```

**Importance 레벨:**

| 레벨 | 설명 |
|------|------|
| `Importance.max` | 헤드업 알림 (화면 켜짐) |
| `Importance.high` | 헤드업 알림 (권장) |
| `Importance.default` | 일반 알림 |
| `Importance.low` | 조용한 알림 |

#### iOS 설정

```dart
// badgeNumber: 예약된 알람 개수 (알림 도착 시 앱 아이콘에 표시)
final pending = await _notifications.pendingNotificationRequests();
final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  presentBanner: true,
  presentList: true,
  badgeNumber: pending.length + 1,  // 새 알람 포함 개수
);
```

**배지 동작:**
- `DarwinNotificationDetails.badgeNumber`: 알림 도착 시 앱 아이콘에 표시할 숫자
- `flutter_app_badger`: 알람 취소 시, 앱 진입 시 배지 직접 업데이트

### 3. TZDateTime 생성

```dart
// 현재 시간 기준
tz.TZDateTime now = tz.TZDateTime.now(tz.local);

// 특정 시간 생성
tz.TZDateTime scheduledDate = tz.TZDateTime(
  tz.local,
  2024, 1, 22,  // 년, 월, 일
  14, 30,       // 시, 분
);
```

---

## 트러블슈팅

### 1. 알람이 울리지 않는 경우

**체크리스트:**

1. ✅ 권한 확인
   - Android 13+: 설정 > 앱 > 알림 권한 확인
   - Android 12 이하: 정확한 알람 권한 확인

2. ✅ 배터리 최적화 해제
   - 설정 > 앱 > 배터리 최적화 > 제외

3. ✅ 알람 등록 확인
   ```dart
   await notificationService.checkPendingNotifications();
   ```

4. ✅ 로그 확인
   - 콘솔에서 "알람 등록 완료" 메시지 확인
   - 오류 메시지 확인

### 2. Android 13+에서 알람이 작동하지 않는 경우

**해결 방법:**

1. `POST_NOTIFICATIONS` 권한 확인
   ```dart
   final hasPermission = await notificationService.checkPermission();
   if (!hasPermission) {
     await notificationService.requestPermission(context: context);
   }
   ```

2. `USE_EXACT_ALARM` 권한 확인
   - Android 13+에서는 시스템 설정에서 확인 필요

3. 앱 설정에서 알림 권한 수동 확인
   - 설정 > 앱 > TagDo > 알림 권한 확인

4. 영구 거부 상태인 경우
   - 앱에서 권한 요청 시 안내 다이얼로그가 표시됨
   - "설정으로 이동" 버튼을 눌러 설정 앱으로 이동
   - 설정에서 알림 권한을 수동으로 허용

### 3. 재부팅 후 알람이 사라지는 경우

**체크리스트:**

1. ✅ `RECEIVE_BOOT_COMPLETED` 권한 확인
2. ✅ `ScheduledNotificationBootReceiver` 설정 확인
3. ✅ 앱이 재부팅 후 자동 실행되는지 확인

### 4. 잠금 화면에서 알람이 보이지 않는 경우

**체크리스트:**

1. ✅ `android:showWhenLocked="true"` 확인
2. ✅ `android:turnScreenOn="true"` 확인
3. ✅ `Importance.high` 또는 `Importance.max` 확인

### 5. 알람이 정확한 시간에 울리지 않는 경우

**해결 방법:**

1. `androidScheduleMode`를 `exactAllowWhileIdle` 또는 `exact`로 설정
2. 배터리 최적화 해제
3. 시간대 설정 확인 (`Asia/Seoul`)

### 6. 디버깅 팁

**로그 확인:**

```dart
// 알람 등록 시 상세 로그 출력
print('=== 알람 등록 시작 ===');
print('Todo 정보: id=${todo.id}, title=${todo.title}');
print('예정 시간: $scheduledDate');
print('현재 시간: ${DateTime.now()}');
```

**등록된 알람 확인:**

```dart
await notificationService.checkPendingNotifications();
```

**즉시 알람 테스트:**

```dart
await notificationService.showTestNotification();
```

---

## 참고 자료

- [flutter_local_notifications 공식 문서](https://pub.dev/packages/flutter_local_notifications)
- [Android 알람 권한 가이드](https://developer.android.com/training/scheduling/alarms)
- [iOS 로컬 알림 가이드](https://developer.apple.com/documentation/usernotifications)

---

## 권한 관리 상세

### Android 13+ 권한 요청 흐름

1. **권한 상태 확인**
   ```dart
   final status = await Permission.notification.status;
   ```

2. **권한 상태별 동작**
   - `isGranted`: 이미 허용됨 → 요청하지 않음
   - `isDenied`: 거부됨 → 권한 요청 다이얼로그 표시
   - `isPermanentlyDenied`: 영구 거부됨 → 안내 다이얼로그 표시 후 설정으로 이동

3. **영구 거부 시 다이얼로그**
   - 바깥 영역 탭: 닫히지 않음 (`barrierDismissible: false`)
   - 뒤로가기 버튼: 닫히지 않음 (`PopScope` 사용)
   - "설정으로 이동" 버튼: 다이얼로그 닫고 설정 앱으로 이동
   - "취소" 버튼: 다이얼로그만 닫음 (설정으로 이동하지 않음)

### 권한 요청 예제

```dart
// 권장: context를 전달하여 영구 거부 시 다이얼로그 표시
final notificationService = NotificationService();
final bool granted = await notificationService.requestPermission(
  context: context, // BuildContext 전달
);

if (!granted) {
  // 권한이 거부된 경우 처리
  print('알람 권한이 필요합니다.');
}
```

---

## 앱 아이콘 배지 (iOS)

로컬 푸시만으로도 앱 아이콘에 예약 알람 개수를 표시할 수 있습니다. (FCM 불필요)

### 동작 방식

| 시점 | 동작 |
|------|------|
| 알람 등록 | `DarwinNotificationDetails.badgeNumber` = 예약 개수 |
| 알람 도착 | 해당 숫자가 앱 아이콘에 표시 |
| 알람 취소 | `flutter_app_badger`로 배지 숫자 감소 |
| 앱 진입 | `clearBadge()` 호출로 배지 제거 (읽음 처리) |

### 관련 API

```dart
// 앱 진입 시 배지 제거
await notificationService.clearBadge();
```

---

## 버전 정보

- **flutter_local_notifications**: ^20.0.0
- **timezone**: ^0.10.0
- **permission_handler**: ^12.0.1
- **app_badge_plus**: ^1.2.6
- **desugar_jdk_libs**: 2.1.4

---

**최종 업데이트:** 2025년 2월

