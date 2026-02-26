// habit_edit_sheet.dart
// HabitEditSheet - 습관 생성/수정 BottomSheet
//
// [모드] update==null → 생성, update!=null → 수정
// [제약] title 필수, daily_target 1~99
// [마감 알림] 오늘 기준 minimum=현재+5분, maximum=23:59 (과거 시간 방지)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/habit.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/config_ui.dart';
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
  int _dailyTarget = 1;
  bool _deadlineReminderEnabled = false;
  TimeOfDay _deadlineReminderTime = const TimeOfDay(hour: 21, minute: 0);
  String? _selectedCategoryId;

  static const int _targetMin = 1;
  static const int _targetMax = 99;

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.update?.title ?? '');
    _dailyTarget = (widget.update?.dailyTarget ?? 1).clamp(_targetMin, _targetMax);
    _titleController.addListener(() => setState(() {}));
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
        SnackBar(content: Text('deadlineReminderNoMore'.tr())),
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
    final dailyTarget = _dailyTarget;
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
    final p = context.appTheme;
    final isUpdate = widget.update != null;
    final tablet = isTablet(context);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tablet ? 32 : ConfigUI.sheetPaddingH),
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
                  hintStyle: TextStyle(color: p.textSecondary),
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
              Row(
                children: [
                  Text(
                    'habitDailyTarget'.tr(),
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filled(
                        onPressed: _dailyTarget > _targetMin
                            ? () {
                                HapticFeedback.selectionClick();
                                setState(() => _dailyTarget--);
                              }
                            : null,
                        icon: const Icon(Icons.remove, size: 20),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '$_dailyTarget',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _dailyTarget < _targetMax
                            ? () {
                                HapticFeedback.selectionClick();
                                setState(() => _dailyTarget++);
                              }
                            : null,
                        icon: const Icon(Icons.add, size: 20),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                    ],
                  ),
                ],
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
                    'deadlineReminder'.tr(),
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
                    onPressed: _canSave
                        ? () {
                            HapticFeedback.mediumImpact();
                            _onSave();
                          }
                        : null,
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
