// main.dart
// 앱 진입점 - 초기화, 로컬 알람, 배지, 앱 생명주기
//
// [로컬 알람] main에서 초기화·권한 요청
// [배지] 앱 시작/포그라운드 복귀 시 clearBadge() 호출

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habitcell/model/tag.dart';
import 'package:habitcell/model/todo.dart';
import 'package:habitcell/service/notification_service.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/view/home.dart';
import 'package:habitcell/service/in_app_review_service.dart';
import 'package:habitcell/util/app_locale.dart';
import 'package:habitcell/util/app_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:habitcell/vm/theme_notifier.dart';
import 'package:habitcell/vm/todo_list_notifier.dart';

Future<void> _initDateFormats() async {
  await Future.wait([
    initializeDateFormatting('ko_KR'),
    initializeDateFormatting('en_US'),
    initializeDateFormatting('ja_JP'),
    initializeDateFormatting('zh_CN'),
    initializeDateFormatting('zh_TW'),
  ]);
}

/// 앱의 메인 함수
void main() async {
  // 네이티브 스플래시 유지
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();

  /// intl DateFormat locale 초기화 (날짜 포맷용)
  await _initDateFormats();

  /// [Step 0] GetStorage 초기화 (테마 등 경량 설정 저장용)
  await GetStorage.init();

  /// [Step 0-1] 첫 실행일 저장 (스토어 리뷰 조건용)
  if (AppStorage.getFirstLaunchDate() == null) {
    await AppStorage.saveFirstLaunchDate(DateTime.now());
  }

  /// [Step 0-2] 저장된 화면 꺼짐 방지 설정 적용
  if (AppStorage.getWakelockEnabled()) {
    WakelockPlus.enable();
  } else {
    WakelockPlus.disable();
  }

  /// [Step 1] Hive를 Flutter 환경에 맞게 초기화합니다.
  await Hive.initFlutter();

  /// [Step 2] Todo, Tag TypeAdapter 등록
  Hive.registerAdapter(TodoAdapter());
  Hive.registerAdapter(TagAdapter());

  /// [Step 3] Hive Box 열기
  await Hive.openBox<Todo>("todo");
  await Hive.openBox<Tag>("tag");

  /// [Step 4] 로컬 알람 서비스 초기화 및 권한 요청
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  /// 네이티브 스플래시 제거 (초기화 완료)
  FlutterNativeSplash.remove();

  /// [Step 5] EasyLocalization + ProviderScope + MyApp
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

/// ============================================================================
/// [MyApp] - 앱의 루트 위젯
/// ============================================================================
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  bool _isInitialCleanupDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialCleanupDone) {
      _isInitialCleanupDone = true;
      _performInitialCleanup();
    }
  }

  /// 앱 시작 시: 배지 제거, 과거 알람 정리, 마감일 Todo 알람 재등록
  Future<void> _performInitialCleanup() async {
    try {
      await _notificationService.clearBadge(); // 앱 진입 = 읽음 처리
      final todos = await ref.read(todoListProvider.future);
      final notifier = ref.read(todoListProvider.notifier);
      await _notificationService.cleanupExpiredNotifications(
        todos: todos,
        updateTodo: (todo) => notifier.updateTodo(todo),
      );
      // Hive Box의 마감일 Todo 알람 재등록 (DB만으로는 OS에 알람 미등록)
      for (final todo in todos) {
        if (todo.dueDate != null) {
          await _notificationService.scheduleNotification(todo);
        }
      }
      _checkAlarmStatus(todos);
    } catch (_) {}
  }

  /// Hive Box dueDate Todo + 등록된 알람 목록 확인 (디버깅)
  void _checkAlarmStatus(List<Todo> todos) {
    final withDueDate = todos.where((t) => t.dueDate != null).toList();
    debugPrint(
      '[AlarmCheck] === Hive Box 마감일 있는 Todo ${withDueDate.length}개 ===',
    );
    for (final t in withDueDate) {
      debugPrint(
        '[AlarmCheck]   no=${t.no}, content=${t.content}, dueDate=${t.dueDate}',
      );
    }
    _notificationService.checkPendingNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _performCleanupOnResume().catchError((_) {});
    }
  }

  /// 포그라운드 복귀 시: 배지 제거, 과거 알람 정리, 알람 재등록, wakelock 재적용
  Future<void> _performCleanupOnResume() async {
    try {
      if (AppStorage.getWakelockEnabled()) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
      await _notificationService.clearBadge();
      final todos = await ref.read(todoListProvider.future);
      final notifier = ref.read(todoListProvider.notifier);
      await _notificationService.cleanupExpiredNotifications(
        todos: todos,
        updateTodo: (todo) => notifier.updateTodo(todo),
      );
      for (final todo in todos) {
        if (todo.dueDate != null) {
          await _notificationService.scheduleNotification(todo);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    appLocaleForInit = context.locale;

    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      /// 디버그 배너 제거
      debugShowCheckedModeBanner: false,

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      /// 테마 모드 (라이트/다크/시스템)
      themeMode: themeMode,

      /// 라이트/다크 ThemeData (context.palette 동작에 필요)
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF1976D2),
          onPrimary: Colors.white,
          surface: const Color(0xFFF5F5F5),
          onSurface: const Color(0xFF212121),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          onPrimary: const Color.fromRGBO(26, 26, 26, 1),
          surface: const Color.fromRGBO(26, 26, 26, 1),
          onSurface: Colors.white,
        ),
      ),

      /// 최상위 Overlay 접근을 위한 navigatorKey 연결
      navigatorKey: rootNavigatorKey,

      /// 최상위 스낵바 표시를 위한 messengerKey 연결
      scaffoldMessengerKey: rootMessengerKey,

      /// Riverpod 방식의 메인 화면
      home: const TodoHome(),
    );
  }
}
