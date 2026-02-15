// main_scaffold.dart
// 홈/분석 탭 네비게이션

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';
import 'package:habitcell/view/analysis_screen.dart';
import 'package:habitcell/view/app_drawer.dart';
import 'package:habitcell/view/habit_home.dart';
import 'package:habitcell/view/sheets/habit_edit_sheet.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';

/// 메인 스캐폴드 - BottomNav로 홈/분석 전환
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: p.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: p.background,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: p.icon),
        leading: IconButton(
          icon: Icon(Icons.menu, color: p.icon, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _currentIndex == 0 ? 'HabitCell' : '분석',
          style: TextStyle(color: p.textPrimary, fontSize: ConfigUI.fontSizeAppBar),
        ),
        actions: _currentIndex == 0
            ? [
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _openHabitAddSheet();
                  },
                  icon: Icon(Icons.add_box_outlined, color: p.icon, size: 32),
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HabitHome(),
          AnalysisScreen(),
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
                  label: '홈',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                  palette: p,
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  label: '분석',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                  palette: p,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openHabitAddSheet() {
    final p = context.palette;
    showModalBottomSheet<HabitEditResult>(
      context: context,
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
