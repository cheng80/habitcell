// habit_home.dart
// 홈 탭 - 습관 목록, +1/-1, CRUD (MainScaffold의 body로 사용)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/view/habit_item.dart';
import 'package:habitcell/view/sheets/habit_delete_sheet.dart';
import 'package:habitcell/view/sheets/habit_edit_sheet.dart';
import 'package:habitcell/vm/habit_database_handler.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';

/// HabitHome - 습관 목록 (AppBar/Scaffold는 MainScaffold에서 제공)
class HabitHome extends ConsumerStatefulWidget {
  const HabitHome({super.key});

  @override
  ConsumerState<HabitHome> createState() => _HabitHomeState();
}

class _HabitHomeState extends ConsumerState<HabitHome> {
  String? _selectedForDeleteId;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final habitsAsync = ref.watch(habitListProvider);

    ref.listen<AsyncValue<List<HabitWithTodayCount>>>(habitListProvider, (previous, next) {
      if (next is AsyncError) {
        showCommonSnackBar(
          context,
          message: '${'errorOccurred'.tr()}: ${next.error}',
          action: SnackBarAction(label: 'retry'.tr(), onPressed: () => _reloadData()),
        );
      }
    });

    Widget body = habitsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(p);
        }
        final now = DateTime.now();
        final todayStr = '${now.month}월 ${now.day}일';

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  '오늘, $todayStr',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SliverReorderableList(
              onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) newIndex--;
                final ids = items.map((e) => e.habit.id).toList();
                final id = ids.removeAt(oldIndex);
                ids.insert(newIndex, id);
                await ref.read(habitListProvider.notifier).reorderHabits(ids);
              },
              proxyDecorator: (child, index, animation) =>
                  _buildDragProxyDecorator(p, child, animation),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  key: ValueKey(item.habit.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: HabitItem(
                        item: item,
                        onTap: () => _showEditSheet(item: item),
                        onLongPress: () => _showDeleteSheet(context, item),
                        rightMargin: 8,
                        isHighlighted: item.habit.id == _selectedForDeleteId,
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                          top: 20,
                        ),
                        child: Icon(
                          Icons.drag_handle,
                          color: p.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                );
              },
              itemCount: items.length,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Text('${'errorOccurred'.tr()}: $error', style: TextStyle(color: p.textPrimary)),
            ElevatedButton(
              onPressed: () => _reloadData(),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        children: [
          Divider(color: p.divider, height: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  Future<void> _showEditSheet({HabitWithTodayCount? item}) async {
    final p = context.palette;
    final result = await showModalBottomSheet<HabitEditResult>(
      context: context,
      backgroundColor: p.sheetBackground,
      isScrollControlled: true,
      shape: defaultSheetShape,
      builder: (context) => HabitEditSheet(update: item?.habit),
    );

    if (result != null && mounted) {
      final notifier = ref.read(habitListProvider.notifier);
      switch (result) {
        case HabitUpdateResult(:final habit):
          await notifier.updateHabit(habit);
        case HabitCreateResult(:final title, :final dailyTarget, :final categoryId, :final deadlineReminderTime):
          await notifier.createHabit(
            title: title,
            dailyTarget: dailyTarget,
            categoryId: categoryId,
            deadlineReminderTime: deadlineReminderTime,
          );
      }
    }
  }

  Future<void> _showDeleteSheet(BuildContext context, HabitWithTodayCount item) async {
    final p = context.palette;
    setState(() => _selectedForDeleteId = item.habit.id);
    await showModalBottomSheet(
      context: context,
      backgroundColor: p.sheetBackground,
      shape: defaultSheetShape,
      builder: (context) => HabitDeleteSheet(
        habitTitle: item.habit.title,
        onDelete: () => ref.read(habitListProvider.notifier).deleteHabit(item.habit.id),
      ),
    );
    if (mounted) setState(() => _selectedForDeleteId = null);
  }

  void _reloadData() {
    ref.read(habitListProvider.notifier).reloadData();
  }
}

Widget _buildEmptyState(AppColorScheme p) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Icon(Icons.track_changes_outlined, size: 56, color: p.textSecondary),
          const SizedBox(height: 8),
          Text(
            'emptyHabitHint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, fontSize: 16),
          ),
          Text(
            '작은 시작이 하루를 바꿉니다',
            style: TextStyle(color: p.textMeta, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDragProxyDecorator(
  AppColorScheme p,
  Widget child,
  Animation<double> animation,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) => Container(
      decoration: BoxDecoration(
        borderRadius: ConfigUI.cardRadius,
        border: Border.all(
          color: p.primary.withValues(alpha: 0.3 + animation.value * 0.5),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    ),
  );
}
