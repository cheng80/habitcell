// main_scaffold.dart
// 홈/분석 탭 네비게이션

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/config_ui.dart';
import 'package:habitcell/util/app_storage.dart';
import 'package:habitcell/util/sheet_util.dart';
import 'package:habitcell/util/tutorial_keys.dart';
import 'package:habitcell/view/analysis_screen.dart';
import 'package:habitcell/view/app_drawer.dart';
import 'package:habitcell/view/habit_home.dart';
import 'package:habitcell/view/sheets/habit_edit_sheet.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';
import 'package:showcaseview/showcaseview.dart';

/// 메인 스캐폴드 - BottomNav로 홈/분석 전환
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _tutorialKeys = TutorialKeys();
  bool _showcaseRegistered = false;

  @override
  void initState() {
    super.initState();
    if (!AppStorage.getTutorialCompleted()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTutorial();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_showcaseRegistered) {
      _showcaseRegistered = true;
      _initTutorial(context);
    }
  }

  /// 가이드 4.3: ShowcaseView 등록
  void _initTutorial(BuildContext context) {
    final p = context.appTheme;
    ShowcaseView.register(
      enableShowcase: !AppStorage.getTutorialCompleted(),

      // 건너뛰기(dismiss) 시 플래그 저장 + Drawer 닫기
      onDismiss: (_) {
        debugPrint('[Tutorial] onDismiss – 건너뛰기');
        AppStorage.setTutorialCompleted();
        _scaffoldKey.currentState?.closeDrawer();
      },

      // 마지막 단계 완료 시 플래그 저장 + Drawer 닫기
      onFinish: () {
        debugPrint('[Tutorial] onFinish – 튜토리얼 완료');
        AppStorage.setTutorialCompleted();
        _scaffoldKey.currentState?.closeDrawer();
      },

      // 단계 전환 콜백: Drawer 단계 끝나면 Drawer 닫기
      onComplete: (index, key) {
        debugPrint('[Tutorial] onComplete index=$index (${_keyName(key)})');
        if (key == _tutorialKeys.menu) {
          _scaffoldKey.currentState?.closeDrawer();
        }
      },

      onStart: (index, key) {
        debugPrint('[Tutorial] onStart index=$index (${_keyName(key)})');
      },

      // 가이드 4.3: inside + spaceBetween
      globalTooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.spaceBetween,
        position: TooltipActionPosition.inside,
      ),
      globalTooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'tutorial_skip'.tr(),
          onTap: () => ShowcaseView.get().dismiss(),
          backgroundColor: Colors.transparent,
          textStyle: TextStyle(
            color: p.textOnSheet,
            fontWeight: FontWeight.w600,
          ),
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'tutorial_next'.tr(),
          backgroundColor: Colors.transparent,
          textStyle: TextStyle(
            color: p.textOnSheet,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 가이드 4.4: 튜토리얼 시작 (Drawer 먼저 열기)
  void _startTutorial() async {
    if (!mounted) return;
    debugPrint('[Tutorial] _startTutorial called');

    // Drawer 내 위젯이 포함된 경우: 먼저 Drawer 열기
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _scaffoldKey.currentState?.openDrawer();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    // 습관이 있으면 전체 단계, 없으면 축소 단계
    final items = ref.read(habitListProvider).value ?? [];
    final keys = items.isNotEmpty
        ? _tutorialKeys.all
        : [
            _tutorialKeys.menu,
            _tutorialKeys.addHabit,
            _tutorialKeys.analysisTab,
          ];
    debugPrint('[Tutorial] keys: ${keys.map(_keyName).toList()}');
    ShowcaseView.get().startShowCase(keys);
  }

  /// 가이드 4.6: 재시작 콜백
  void _restartTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      _scaffoldKey.currentState?.openDrawer();
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      final items = ref.read(habitListProvider).value ?? [];
      final keys = items.isNotEmpty
          ? _tutorialKeys.all
          : [
              _tutorialKeys.menu,
              _tutorialKeys.addHabit,
              _tutorialKeys.analysisTab,
            ];
      debugPrint('[Tutorial] restart keys: ${keys.map(_keyName).toList()}');
      final sv = ShowcaseView.get();
      sv.enableShowcase = true;
      sv.startShowCase(keys);
    });
  }

  String _keyName(GlobalKey key) {
    if (key == _tutorialKeys.menu) return 'menu';
    if (key == _tutorialKeys.habitCard) return 'habitCard';
    if (key == _tutorialKeys.cellGrid) return 'cellGrid';
    if (key == _tutorialKeys.completeRow) return 'completeRow';
    if (key == _tutorialKeys.addHabit) return 'addHabit';
    if (key == _tutorialKeys.analysisTab) return 'analysisTab';
    return 'unknown';
  }

  @override
  void dispose() {
    ShowcaseView.get().unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.appTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: p.background,
      drawer: AppDrawer(
        onReplayTutorial: _restartTutorial,
        menuShowcaseKey: _tutorialKeys.menu,
      ),
      appBar: AppBar(
        backgroundColor: p.background,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: p.icon),
        leading: IconButton(
          icon: Icon(Icons.menu, color: p.icon, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _currentIndex == 0 ? 'HabitCell' : 'navAnalysis'.tr(),
          style: TextStyle(color: p.textPrimary, fontSize: ConfigUI.fontSizeAppBar),
        ),
        actions: _currentIndex == 0
            ? [
                Showcase(
                  key: _tutorialKeys.addHabit,
                  description: 'tutorial_step_4'.tr(),
                  tooltipBackgroundColor: p.sheetBackground,
                  textColor: p.textOnSheet,
                  tooltipBorderRadius: ConfigUI.cardRadius,
                  disableDefaultTargetGestures: true,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _openHabitAddSheet();
                    },
                    icon: Icon(Icons.add_box_outlined, color: p.icon, size: 32),
                  ),
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HabitHome(tutorialKeys: _tutorialKeys),
          const AnalysisScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.cardBackground,
          border: Border(top: BorderSide(color: p.divider)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  label: 'navHome'.tr(),
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                  palette: p,
                ),
                Showcase(
                  key: _tutorialKeys.analysisTab,
                  description: 'tutorial_step_6'.tr(),
                  tooltipBackgroundColor: p.sheetBackground,
                  textColor: p.textOnSheet,
                  tooltipBorderRadius: ConfigUI.cardRadius,
                  disableDefaultTargetGestures: true,
                  child: _NavItem(
                    icon: Icons.analytics_outlined,
                    label: 'navAnalysis'.tr(),
                    isSelected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                    palette: p,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openHabitAddSheet() {
    final p = context.appTheme;
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    showModalBottomSheet<HabitEditResult>(
      context: rootContext,
      useRootNavigator: true,
      isDismissible: false,
      backgroundColor: p.sheetBackground,
      isScrollControlled: true,
      shape: defaultSheetShape,
      builder: (context) => const HabitEditSheet(update: null),
    ).then((result) async {
      if (result != null && mounted) {
        final notifier = ref.read(habitListProvider.notifier);
        switch (result) {
          case HabitCreateResult(:final title, :final dailyTarget, :final categoryId, :final deadlineReminderTime):
            await notifier.createHabit(
              title: title,
              dailyTarget: dailyTarget,
              categoryId: categoryId,
              deadlineReminderTime: deadlineReminderTime,
            );
          case HabitUpdateResult():
            break;
        }
      }
    });
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final dynamic palette;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? palette.primary : palette.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? palette.primary : palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
