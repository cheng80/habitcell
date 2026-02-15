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
import 'package:habitcell/service/notification_service.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/util/app_locale.dart';
import 'package:habitcell/util/app_storage.dart';
import 'package:habitcell/view/main_scaffold.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:habitcell/vm/theme_notifier.dart';
import 'package:habitcell/vm/habit_database_handler.dart';

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
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();
  await _initDateFormats();

  await GetStorage.init();

  if (AppStorage.getFirstLaunchDate() == null) {
    await AppStorage.saveFirstLaunchDate(DateTime.now());
  }

  if (AppStorage.getWakelockEnabled()) {
    WakelockPlus.enable();
  } else {
    WakelockPlus.disable();
  }

  await HabitDatabaseHandler.database;

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  FlutterNativeSplash.remove();

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
      useFallbackTranslations: true,
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

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

  Future<void> _performInitialCleanup() async {
    try {
      await _notificationService.clearBadge();
      if (AppStorage.getPreReminderEnabled()) {
        await _notificationService.schedulePreReminders();
      } else {
        await _notificationService.cancelPreReminders();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _performCleanupOnResume().catchError((_) {});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _schedulePreRemindersOnBackground().catchError((_) {});
    }
  }

  Future<void> _performCleanupOnResume() async {
    try {
      if (AppStorage.getWakelockEnabled()) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
      await _notificationService.clearBadge();
      await _notificationService.cancelPreReminders();
    } catch (_) {}
  }

  Future<void> _schedulePreRemindersOnBackground() async {
    try {
      if (AppStorage.getPreReminderEnabled()) {
        await _notificationService.schedulePreReminders();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    appLocaleForInit = context.locale;
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: themeMode,
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
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootMessengerKey,
      home: const MainScaffold(),
    );
  }
}
