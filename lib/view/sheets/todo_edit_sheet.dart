// todo_edit_sheet.dart
// TodoEditSheet - Todo 생성/수정 BottomSheet
// 내부 위젯은 todo_edit_sheet/ 폴더에 분리됨

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitcell/model/todo.dart';
import 'package:habitcell/view/sheets/todo_edit_sheet/edit_sheet_content_field.dart';
import 'package:habitcell/view/sheets/todo_edit_sheet/edit_sheet_due_date_field.dart';
import 'package:habitcell/view/sheets/todo_edit_sheet/edit_sheet_header.dart';
import 'package:habitcell/view/sheets/todo_edit_sheet/edit_sheet_tag_selector.dart';
import 'package:habitcell/vm/edit_sheet_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TodoEditSheet - Todo 생성/수정 BottomSheet 위젯
///
/// [update] 파라미터:
/// - null → 생성 모드 (빈 입력 필드, SAVE 버튼)
/// - not null → 수정 모드 (기존 값 표시, CHANGE 버튼)
class TodoEditSheet extends ConsumerStatefulWidget {
  final Todo? update;

  const TodoEditSheet({super.key, required this.update});

  @override
  ConsumerState<TodoEditSheet> createState() => _TodoEditSheetState();
}

class _TodoEditSheetState extends ConsumerState<TodoEditSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    if (widget.update != null) {
      _controller = TextEditingController(text: widget.update!.content);
    } else {
      _controller = TextEditingController();
    }

    final initialTag = widget.update?.tag ?? 0;
    final initialEmpty = _controller.text.trim().isEmpty;
    final initialDueDate = widget.update?.dueDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editTagProvider.notifier).setTag(initialTag);
      ref.read(isContentEmptyProvider.notifier).setEmpty(initialEmpty);
      ref.read(editDueDateProvider.notifier).setDueDate(initialDueDate);
    });
    _controller.addListener(() {
      final isEmpty = _controller.text.trim().isEmpty;
      if (ref.read(isContentEmptyProvider) != isEmpty) {
        ref.read(isContentEmptyProvider.notifier).setEmpty(isEmpty);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height - kToolbarHeight;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SizedBox(
        height: sheetHeight,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            EditSheetHeader(isUpdate: widget.update != null, onSave: _onSave),
            EditSheetContentField(controller: _controller),
            EditSheetDueDateField(onPickDate: _pickDateAndTime),
            Expanded(child: EditSheetTagSelector()),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    HapticFeedback.mediumImpact();

    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final selectedTag = ref.read(editTagProvider);
    final dueDate = ref.read(editDueDateProvider);

    final Todo result;
    if (widget.update == null) {
      result = Todo.create(content, selectedTag, dueDate: dueDate);
    } else {
      result = widget.update!.copyWith(
        content: content,
        tag: selectedTag,
        dueDate: dueDate,
        clearDueDate: dueDate == null,
        updatedAt: DateTime.now(),
      );
    }

    Navigator.of(context).pop(result);
  }

  Future<void> _pickDateAndTime() async {
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final savedDueDate = ref.read(editDueDateProvider) ?? now;
    // 과거 마감일이면 initialDate를 오늘로 (showDatePicker assertion 방지)
    final initialDate = savedDueDate.isBefore(today) ? today : savedDueDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(now.year + 5),
      helpText: "dateSelect".tr(),
    );
    if (date == null || !mounted) return;

    final time = await _showCupertinoTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(savedDueDate),
    );
    if (time == null || !mounted) return;

    final result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    ref.read(editDueDateProvider.notifier).setDueDate(result);
  }

  /// Cupertino 스타일 시간 선택 모달 (달력 showDatePicker와 동일하게 다이얼로그 형태)
  static Future<TimeOfDay?> _showCupertinoTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    DateTime selected = DateTime(
      2000,
      1,
      1,
      initialTime.hour,
      initialTime.minute,
    );

    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (ctx) => CupertinoTheme(
        data: CupertinoThemeData(brightness: Theme.of(ctx).brightness),
        child: Container(
          height: 280,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더: 취소 | 시간 선택 | 확인 (텍스트와 피커 간 간격 확보)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text("cancel".tr()),
                      ),
                      Expanded(
                        child: Text(
                          "timeSelect".tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label.resolveFrom(ctx),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(ctx).pop(
                          TimeOfDay(
                            hour: selected.hour,
                            minute: selected.minute,
                          ),
                        ),
                        child: Text("confirm".tr()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: selected,
                    use24hFormat: use24h,
                    minuteInterval: 1,
                    onDateTimeChanged: (dt) => selected = dt,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
