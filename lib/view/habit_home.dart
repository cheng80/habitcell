// habit_home.dart
// 홈 탭 - 습관 목록, +1/-1, CRUD (MainScaffold의 body로 사용)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

enum _HabitFilter { all, completed, uncompleted }

class _HabitHomeState extends ConsumerState<HabitHome> {
  String? _selectedForDeleteId;
  bool _allExpanded = true;
  _HabitFilter _filter = _HabitFilter.all;

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
        final locale = context.locale.toString();
        final todayStr = '${now.month}월 ${now.day}일 (${DateFormat.E(locale).format(now)})';

        final filteredItems = switch (_filter) {
          _HabitFilter.all => items,
          _HabitFilter.completed => items.where((e) => e.isCompleted).toList(),
          _HabitFilter.uncompleted => items.where((e) => !e.isCompleted).toList(),
        };

        if (filteredItems.isEmpty) {
          return _buildFilteredEmptyState(p, _filter);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    '오늘, $todayStr',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _allExpanded = false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.textPrimary,
                      side: BorderSide(color: p.divider),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('collapseAll'.tr(), style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _allExpanded = true);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.textPrimary,
                      side: BorderSide(color: p.divider),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('expandAll'.tr(), style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                spacing: 8,
                children: [
                  _FilterChip(
                    label: 'all'.tr(),
                    selected: _filter == _HabitFilter.all,
                    onSelected: () {
                      HapticFeedback.selectionClick();
                      setState(() => _filter = _HabitFilter.all);
                    },
                    palette: p,
                  ),
                  _FilterChip(
                    label: 'checked'.tr(),
                    selected: _filter == _HabitFilter.completed,
                    onSelected: () {
                      HapticFeedback.selectionClick();
                      setState(() => _filter = _HabitFilter.completed);
                    },
                    palette: p,
                  ),
                  _FilterChip(
                    label: 'unchecked'.tr(),
                    selected: _filter == _HabitFilter.uncompleted,
                    onSelected: () {
                      HapticFeedback.selectionClick();
                      setState(() => _filter = _HabitFilter.uncompleted);
                    },
                    palette: p,
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (_filter == _HabitFilter.all)
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
                        final item = filteredItems[index];
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
                                isExpanded: _allExpanded,
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
                      itemCount: filteredItems.length,
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: ConfigUI.listItemMarginLeft,
                              right: ConfigUI.listItemMarginRight + 32,
                              top: ConfigUI.listItemMarginTop,
                              bottom: ConfigUI.listItemMarginBottom,
                            ),
                            child: HabitItem(
                              item: item,
                              onTap: () => _showEditSheet(item: item),
                              onLongPress: () => _showDeleteSheet(context, item),
                              rightMargin: 0,
                              isHighlighted: item.habit.id == _selectedForDeleteId,
                              isExpanded: _allExpanded,
                            ),
                          );
                        },
                        childCount: filteredItems.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final AppColorScheme palette;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 13)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: palette.chipSelectedBg,
      checkmarkColor: palette.chipSelectedText,
      labelStyle: TextStyle(
        color: selected ? palette.chipSelectedText : palette.chipUnselectedText,
        fontSize: 13,
      ),
      backgroundColor: palette.chipUnselectedBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
    );
  }
}

Widget _buildFilteredEmptyState(AppColorScheme p, _HabitFilter filter) {
  final message = switch (filter) {
    _HabitFilter.all => '',
    _HabitFilter.completed => 'filterEmptyCompleted'.tr(),
    _HabitFilter.uncompleted => 'filterEmptyUncompleted'.tr(),
  };
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        style: TextStyle(color: p.textSecondary, fontSize: 16),
      ),
    ),
  );
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
