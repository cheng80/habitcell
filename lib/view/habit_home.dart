// habit_home.dart
// 홈 탭 - 습관 목록, +1/-1, CRUD (MainScaffold의 body로 사용)
//
// [필터 정책] all=전체, completed=count>=target, uncompleted=미달성
// [정렬] sort_order(등록순·드래그)만 사용, 완료 토글 시 순서 변경 없음. "전체"에서만 드래그 핸들 표시
// [정책] 필터 결과 없어도 날짜·필터 버튼은 항상 표시 (다른 필터로 전환 가능)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/util/tutorial_keys.dart';
import 'package:habitcell/view/habit_item.dart';
import 'package:habitcell/view/sheets/habit_delete_sheet.dart';
import 'package:habitcell/view/sheets/habit_edit_sheet.dart';
import 'package:habitcell/vm/habit_database_handler.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';

/// HabitHome - 습관 목록 (AppBar/Scaffold는 MainScaffold에서 제공)
class HabitHome extends ConsumerStatefulWidget {
  const HabitHome({super.key, this.tutorialKeys});

  final TutorialKeys? tutorialKeys;

  @override
  ConsumerState<HabitHome> createState() => _HabitHomeState();
}

enum _HabitFilter { all, completed, uncompleted }

class _HabitHomeState extends ConsumerState<HabitHome> {
  String? _selectedForDeleteId;
  bool _allExpanded = true;
  _HabitFilter _filter = _HabitFilter.all;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.appTheme;
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
        final dateStr = DateFormat.MMMd(locale).format(now);
        final weekdayStr = DateFormat.E(locale).format(now);
        final todayStr = '$dateStr ($weekdayStr)';

        final filteredItems = switch (_filter) {
          _HabitFilter.all => items,
          _HabitFilter.completed => items.where((e) => e.isCompleted).toList(),
          _HabitFilter.uncompleted => items.where((e) => !e.isCompleted).toList(),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ConfigUI.screenPaddingH, 16, ConfigUI.screenPaddingH, 8),
              child: Row(
                children: [
                  Text(
                    '${'today'.tr()}, $todayStr',
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
                      padding: const EdgeInsets.symmetric(
          horizontal: ConfigUI.chipPaddingHCompact, vertical: ConfigUI.chipPaddingV),
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
                      padding: const EdgeInsets.symmetric(
          horizontal: ConfigUI.chipPaddingHCompact, vertical: ConfigUI.chipPaddingV),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('expandAll'.tr(), style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ConfigUI.screenPaddingH, 0, ConfigUI.screenPaddingH, 12),
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
              child: filteredItems.isEmpty
                  ? _buildFilteredEmptyState(p, _filter)
                  : CustomScrollView(
                controller: _scrollController,
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
                        final isFirst = index == 0;
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
                                tutorialKeys: isFirst ? widget.tutorialKeys : null,
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
                          final isFirst = index == 0;
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
                              tutorialKeys: isFirst ? widget.tutorialKeys : null,
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
    final p = context.appTheme;
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final result = await showModalBottomSheet<HabitEditResult>(
      context: rootContext,
      useRootNavigator: true,
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
    final p = context.appTheme;
    setState(() => _selectedForDeleteId = item.habit.id);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    await showModalBottomSheet(
      context: rootContext,
      useRootNavigator: true,
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
  final AppThemeColorsHelper palette;

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
      padding: const EdgeInsets.symmetric(
          horizontal: ConfigUI.chipPaddingHCompact, vertical: ConfigUI.chipPaddingV),
      showCheckmark: false,
    );
  }
}

Widget _buildFilteredEmptyState(AppThemeColorsHelper p, _HabitFilter filter) {
  final message = switch (filter) {
    _HabitFilter.all => '',
    _HabitFilter.completed => 'filterEmptyCompleted'.tr(),
    _HabitFilter.uncompleted => 'filterEmptyUncompleted'.tr(),
  };
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(ConfigUI.paddingEmptyState),
      child: Text(
        message,
        style: TextStyle(color: p.textSecondary, fontSize: 16),
      ),
    ),
  );
}

Widget _buildEmptyState(AppThemeColorsHelper p) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(ConfigUI.paddingEmptyState),
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
            'emptyHabitSubtitle'.tr(),
            style: TextStyle(color: p.textMeta, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDragProxyDecorator(
  AppThemeColorsHelper p,
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
