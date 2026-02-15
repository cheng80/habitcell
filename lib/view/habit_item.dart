// habit_item.dart
// 습관 아이템 - "하루 한 칸" (Ticka 스타일)
// 6칸 기준 그리드, 탭으로 채우기/되돌리기, 완료 버튼

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/color_util.dart';
import 'package:habitcell/model/category.dart';
import 'package:habitcell/model/habit.dart';
import 'package:habitcell/vm/category_list_notifier.dart';
import 'package:habitcell/vm/habit_database_handler.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';

const int _gridColumns = 6;
const double _cellSizeMin = 36.0;
const double _cellSizeMax = 52.0;
const double _cellSpacing = 8.0;

class HabitItem extends ConsumerWidget {
  final HabitWithTodayCount item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double? leftMargin;
  final double? rightMargin;
  final bool isHighlighted;

  const HabitItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.leftMargin,
    this.rightMargin,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final habit = item.habit;
    final todayCount = item.todayCount;
    final categories = ref.watch(categoryListProvider).value ?? [];
    final category = habit.categoryId != null
        ? categories.where((c) => c.id == habit.categoryId).firstOrNull
        : null;
    final target = habit.dailyTarget;
    final achieved = todayCount >= target;
    final isCompleted = item.isCompleted;

    return GestureDetector(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    _buildHeaderRow(context, ref, habit, p, onTap),
                    Divider(color: p.divider, height: 1),
                    _buildCountRow(
                      habit,
                      todayCount,
                      target,
                      achieved,
                      isCompleted,
                      p,
                      ref,
                    ),
                    _CellGrid(
                      count: todayCount,
                      target: target,
                      isCompleted: isCompleted,
                      onFill: () => ref
                          .read(habitListProvider.notifier)
                          .incrementCount(habit.id),
                      onUnfill: () => ref
                          .read(habitListProvider.notifier)
                          .decrementCount(habit.id),
                      palette: p,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  AppColorScheme p,
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
  AppColorScheme p,
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
        '$todayCount/$target회',
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
  final AppColorScheme palette;

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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onToggle();
        },
        borderRadius: BorderRadius.circular(10),
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
                '완료',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 15,
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
  final AppColorScheme palette;

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
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _gridColumns * _cellSizeMax + (_gridColumns - 1) * _cellSpacing;
        final idealCellSize =
            (availableWidth - (_gridColumns - 1) * _cellSpacing) / _gridColumns;
        final cellSize = idealCellSize.clamp(_cellSizeMin, _cellSizeMax);
        return Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: _cellSpacing,
          runSpacing: _cellSpacing,
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
                    HapticFeedback.mediumImpact();
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
                    borderRadius: BorderRadius.circular(8),
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
