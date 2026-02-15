// habit_edit_sheet.dart
// HabitEditSheet - 습관 생성/수정 BottomSheet

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/habit.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';
import 'package:habitcell/view/sheets/edit_sheet_category_selector.dart';

/// HabitEditSheet - 습관 생성/수정 BottomSheet
///
/// [update] null → 생성, not null → 수정
class HabitEditSheet extends ConsumerStatefulWidget {
  final Habit? update;

  const HabitEditSheet({super.key, this.update});

  @override
  ConsumerState<HabitEditSheet> createState() => _HabitEditSheetState();
}

class _HabitEditSheetState extends ConsumerState<HabitEditSheet> {
  late TextEditingController _titleController;
  late TextEditingController _targetController;
  bool _deadlineReminderEnabled = false;
  TimeOfDay _deadlineReminderTime = const TimeOfDay(hour: 21, minute: 0);
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.update?.title ?? '');
    _targetController = TextEditingController(
      text: (widget.update?.dailyTarget ?? 1).toString(),
    );
    _selectedCategoryId = widget.update?.categoryId;
    final dt = widget.update?.deadlineReminderTime;
    if (dt != null && dt.isNotEmpty) {
      _deadlineReminderEnabled = true;
      final parts = dt.split(':');
      if (parts.length >= 2) {
        _deadlineReminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 21,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  String _timeToStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _showDeadlineTimePicker(BuildContext context) {
    final now = DateTime.now();
    // 현재 시간 + 5분 (이전 시간 선택 방지)
    final minimum = now.add(const Duration(minutes: 5));
    final maximum = DateTime(now.year, now.month, now.day, 23, 59);
    if (minimum.isAfter(maximum)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘은 더 이상 알림 시간을 설정할 수 없습니다')),
      );
      return;
    }
    var initial = DateTime(
      now.year,
      now.month,
      now.day,
      _deadlineReminderTime.hour,
      _deadlineReminderTime.minute,
    );
    if (initial.isBefore(minimum)) initial = minimum;
    if (initial.isAfter(maximum)) initial = maximum;
    var selected = initial;
    showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (context) => _DeadlineTimePickerSheet(
        initial: initial,
        minimum: minimum,
        maximum: maximum,
        onChanged: (dt) => selected = dt,
        onConfirm: () => Navigator.of(
          context,
        ).pop(TimeOfDay(hour: selected.hour, minute: selected.minute)),
      ),
    ).then((picked) {
      if (picked != null && mounted) {
        setState(() => _deadlineReminderTime = picked);
      }
    });
  }

  void _onSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('contentRequired'.tr())));
      return;
    }
    final target = int.tryParse(_targetController.text.trim()) ?? 1;
    final dailyTarget = target < 1 ? 1 : target;
    final deadlineReminderTime = _deadlineReminderEnabled
        ? _timeToStr(_deadlineReminderTime)
        : null;

    if (widget.update != null) {
      final updated = widget.update!.copyWith(
        title: title,
        dailyTarget: dailyTarget,
        categoryId: _selectedCategoryId,
        clearCategoryId: _selectedCategoryId == null,
        deadlineReminderTime: deadlineReminderTime,
        clearDeadlineReminderTime: deadlineReminderTime == null,
      );
      Navigator.of(context).pop(HabitUpdateResult(updated));
    } else {
      Navigator.of(context).pop(
        HabitCreateResult(
          title: title,
          dailyTarget: dailyTarget,
          categoryId: _selectedCategoryId,
          deadlineReminderTime: deadlineReminderTime,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isUpdate = widget.update != null;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(ConfigUI.sheetPaddingH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isUpdate ? 'habitEdit'.tr() : 'habitAdd'.tr(),
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: ConfigUI.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                autofocus: true,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: 'habitTitle'.tr(),
                  hintText: 'habitTitleHint'.tr(),
                  counterStyle: TextStyle(color: p.textSecondary, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: ConfigUI.inputRadius,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ConfigUI.inputPaddingH,
                    vertical: ConfigUI.inputPaddingV,
                  ),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'habitDailyTarget'.tr(),
                  hintText: '1',
                  border: OutlineInputBorder(
                    borderRadius: ConfigUI.inputRadius,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ConfigUI.inputPaddingH,
                    vertical: ConfigUI.inputPaddingV,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EditSheetCategorySelector(
                selectedCategoryId: _selectedCategoryId,
                onSelected: (id) => setState(() => _selectedCategoryId = id),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '마감 알림',
                    style: TextStyle(color: p.textPrimary, fontSize: 16),
                  ),
                  const Spacer(),
                  if (_deadlineReminderEnabled) ...[
                    TextButton.icon(
                      onPressed: () => _showDeadlineTimePicker(context),
                      icon: Icon(Icons.schedule, size: 18, color: p.primary),
                      label: Text(
                        '${_deadlineReminderTime.hour.toString().padLeft(2, '0')}:${_deadlineReminderTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: p.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Switch(
                    value: _deadlineReminderEnabled,
                    onChanged: (v) =>
                        setState(() => _deadlineReminderEnabled = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr()),
                  ),
                  FilledButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _onSave();
                    },
                    child: Text(isUpdate ? 'change'.tr() : 'save'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cupertino 스타일 마감 시간 선택 시트
/// - 현재 시간 이전 선택 방지
/// - 현재 시간 + 5분 이내 선택 방지
class _DeadlineTimePickerSheet extends StatelessWidget {
  final DateTime initial;
  final DateTime minimum;
  final DateTime maximum;
  final void Function(DateTime) onChanged;
  final VoidCallback onConfirm;

  const _DeadlineTimePickerSheet({
    required this.initial,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  onPressed: onConfirm,
                  child: Text('confirm'.tr()),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initial,
                minimumDate: minimum,
                maximumDate: maximum,
                use24hFormat: true,
                onDateTimeChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// HabitEditSheet 결과 - 생성/수정 구분
sealed class HabitEditResult {
  const HabitEditResult();
}

class HabitUpdateResult extends HabitEditResult {
  final Habit habit;
  const HabitUpdateResult(this.habit);
}

class HabitCreateResult extends HabitEditResult {
  final String title;
  final int dailyTarget;
  final String? categoryId;
  final String? deadlineReminderTime;
  const HabitCreateResult({
    required this.title,
    required this.dailyTarget,
    this.categoryId,
    this.deadlineReminderTime,
  });
}
