// habit_item.dart
// 습관 아이템 - "하루 한 칸" (Ticka 스타일)
//
// [레이아웃] 6열 그리드, daily_target만큼 칸 표시, 탭으로 +1/-1
// [달성] count >= daily_target → 시각 변화, 완료 버튼 표시
// [완료 토글] count >= target일 때만, 토글 시 순서 변경 없음 (sort_order 유지)
// [카테고리] categoryId 있으면 상단 바 색상, 없으면 미표시

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/config_ui.dart';
import 'package:habitcell/util/color_util.dart';
import 'package:habitcell/util/tutorial_keys.dart';
import 'package:habitcell/model/category.dart';
import 'package:habitcell/model/habit.dart';
import 'package:habitcell/vm/category_list_notifier.dart';
import 'package:habitcell/vm/habit_database_handler.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';
import 'package:showcaseview/showcaseview.dart';


class HabitItem extends ConsumerWidget {
  final HabitWithTodayCount item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double? leftMargin;
  final double? rightMargin;
  final bool isHighlighted;
  final bool isExpanded;
  final TutorialKeys? tutorialKeys;

  const HabitItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.leftMargin,
    this.rightMargin,
    this.isHighlighted = false,
    this.isExpanded = true,
    this.tutorialKeys,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.appTheme;
    final habit = item.habit;
    final todayCount = item.todayCount;
    final categories = ref.watch(categoryListProvider).value ?? [];
    final category = habit.categoryId != null
        ? categories.where((c) => c.id == habit.categoryId).firstOrNull
        : null;
    final target = habit.dailyTarget;
    final achieved = todayCount >= target;
    final isCompleted = item.isCompleted;
    final keys = tutorialKeys;

    Widget cardContent = GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(
          left: leftMargin ?? ConfigUI.listItemMarginLeft,
          right: rightMargin ?? ConfigUI.listItemMarginRight,
          top: ConfigUI.listItemMarginTop,
          bottom: ConfigUI.listItemMarginBottom,
        ),
        decoration: BoxDecoration(
          color: p.cardBackground,
          borderRadius: ConfigUI.cardRadius,
          border: isHighlighted
              ? Border.all(color: p.primary, width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isHighlighted ? 0.12 : 0.06,
              ),
              blurRadius: isHighlighted ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: ConfigUI.cardRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category != null) _buildCategoryBar(category),
              ExpansionTile(
                key: ValueKey('${habit.id}_$isExpanded'),
                initiallyExpanded: isExpanded,
                tilePadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                controlAffinity: ListTileControlAffinity.trailing,
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  side: BorderSide.none,
                ),
                collapsedShape: const RoundedRectangleBorder(
                  side: BorderSide.none,
                ),
                expandedAlignment: Alignment.topLeft,
                title: _buildHeaderRow(context, ref, habit, p, onTap),
                children: [
                  Divider(color: p.divider, height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        _wrapCountRow(
                          keys,
                          habit,
                          todayCount,
                          target,
                          achieved,
                          isCompleted,
                          p,
                          ref,
                        ),
                        _wrapCellGrid(
                          keys,
                          todayCount,
                          target,
                          isCompleted,
                          habit.id,
                          ref,
                          p,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (keys != null) {
      cardContent = Showcase(
        key: keys.habitCard,
        description: 'tutorial_step_1'.tr(),
        tooltipBackgroundColor: p.sheetBackground,
        textColor: p.textOnSheet,
        tooltipBorderRadius: ConfigUI.cardRadius,
        disableDefaultTargetGestures: true,
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _wrapCountRow(
    TutorialKeys? keys,
    Habit habit,
    int todayCount,
    int target,
    bool achieved,
    bool isCompleted,
    AppThemeColorsHelper p,
    WidgetRef ref,
  ) {
    final row = _buildCountRow(
      habit,
      todayCount,
      target,
      achieved,
      isCompleted,
      p,
      ref,
    );
    if (keys != null) {
      return Showcase(
        key: keys.completeRow,
        description: 'tutorial_step_3'.tr(),
        tooltipBackgroundColor: p.sheetBackground,
        textColor: p.textOnSheet,
        tooltipBorderRadius: ConfigUI.cardRadius,
        disableDefaultTargetGestures: true,
        child: row,
      );
    }
    return row;
  }

  Widget _wrapCellGrid(
    TutorialKeys? keys,
    int count,
    int target,
    bool isCompleted,
    String habitId,
    WidgetRef ref,
    AppThemeColorsHelper p,
  ) {
    final grid = _CellGrid(
      count: count,
      target: target,
      isCompleted: isCompleted,
      onFill: () => ref.read(habitListProvider.notifier).incrementCount(habitId),
      onUnfill: () => ref.read(habitListProvider.notifier).decrementCount(habitId),
      palette: p,
    );
    if (keys != null) {
      return Showcase(
        key: keys.cellGrid,
        description: 'tutorial_step_2'.tr(),
        tooltipBackgroundColor: p.sheetBackground,
        textColor: p.textOnSheet,
        tooltipBorderRadius: ConfigUI.cardRadius,
        disableDefaultTargetGestures: true,
        child: grid,
      );
    }
    return grid;
  }
}

Widget _buildCategoryBar(Category category) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    color: category.color,
    child: Text(
      category.name,
      style: TextStyle(
        color: contrastColor(category.color),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _buildHeaderRow(
  BuildContext context,
  WidgetRef ref,
  Habit habit,
  AppThemeColorsHelper p,
  VoidCallback onTap,
) {
  return Row(
    spacing: 4,
    children: [
      IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        icon: Icon(Icons.edit_outlined, color: p.primary, size: 20),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(4),
          minimumSize: const Size(36, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      Expanded(
        child: Text(
          habit.title,
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _buildCountRow(
  Habit habit,
  int todayCount,
  int target,
  bool achieved,
  bool isCompleted,
  AppThemeColorsHelper p,
  WidgetRef ref,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    spacing: 8,
    children: [
      Icon(
        Icons.access_alarm,
        color: habit.deadlineReminderTime != null
            ? p.alarmAccent
            : Colors.transparent,
        size: 24,
      ),
      Text(
        '$todayCount/$target${'countTimes'.tr()}',
        style: TextStyle(
          color: p.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (achieved)
        _CompleteButton(
          isCompleted: isCompleted,
          onToggle: () =>
              ref.read(habitListProvider.notifier).toggleCompleted(habit.id),
          palette: p,
        ),
    ],
  );
}

/// 완료 버튼 - 전체 채워졌을 때만 표시, 토글 가능
class _CompleteButton extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onToggle;
  final AppThemeColorsHelper palette;

  const _CompleteButton({
    required this.isCompleted,
    required this.onToggle,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCompleted
          ? palette.primary.withValues(alpha: 0.2)
          : palette.primary.withValues(alpha: 0.12),
      borderRadius: ConfigUI.buttonRadius,
      child: InkWell(
        onTap: () {
          HapticFeedback.heavyImpact();
          onToggle();
        },
        borderRadius: ConfigUI.buttonRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: palette.primary,
                size: 22,
              ),
              Text(
                'completeButton'.tr(),
                style: TextStyle(
                  color: palette.primary,
                  fontSize: ConfigUI.fontSizeButton,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6열 그리드 - 칸 탭으로 채우기/되돌리기 (완료 전까지)
class _CellGrid extends StatelessWidget {
  final int count;
  final int target;
  final bool isCompleted;
  final VoidCallback onFill;
  final VoidCallback onUnfill;
  final AppThemeColorsHelper palette;

  const _CellGrid({
    required this.count,
    required this.target,
    required this.isCompleted,
    required this.onFill,
    required this.onUnfill,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = ConfigUI.habitCardGridColumns;
        final spacing = ConfigUI.habitCardCellSpacing;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : cols * ConfigUI.habitCardCellSizeMax + (cols - 1) * spacing;
        final idealCellSize =
            (availableWidth - (cols - 1) * spacing) / cols;
        final cellSize = idealCellSize.clamp(
            ConfigUI.habitCardCellSizeMin, ConfigUI.habitCardCellSizeMax);
        return Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(target, (i) {
            final filled = i < count;
            final isNextToFill = i == count && count < target;
            final canUnfill = filled && !isCompleted;
            return SizedBox(
              width: cellSize,
              height: cellSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (isNextToFill) {
                    // 목표 달성 시(마지막 칸) 더 강한 진동
                    (count + 1 == target
                        ? HapticFeedback.heavyImpact
                        : HapticFeedback.mediumImpact)();
                    onFill();
                  } else if (canUnfill) {
                    HapticFeedback.mediumImpact();
                    onUnfill();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: filled
                        ? palette.primary.withValues(alpha: 0.25)
                        : palette.cardBackground,
                    borderRadius: ConfigUI.inputRadius,
                    border: Border.all(
                      color: filled ? palette.primary : palette.divider,
                      width: filled ? 1.5 : 1,
                    ),
                  ),
                  child: filled
                      ? Icon(
                          Icons.check_rounded,
                          color: palette.primary,
                          size: 20,
                        )
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
