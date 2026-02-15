// ============================================================================
// [view/todo_item.dart] - Todo 아이템 위젯
// ============================================================================

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagdo/model/tag.dart';
import 'package:tagdo/model/todo.dart';
import 'package:tagdo/theme/app_colors.dart';
import 'package:tagdo/theme/config_ui.dart';
import 'package:tagdo/vm/todo_list_notifier.dart';
import 'package:tagdo/vm/tag_list_notifier.dart';
import 'package:tagdo/vm/tag_handler.dart';
import 'package:tagdo/vm/home_filter_notifier.dart';

class TodoItem extends ConsumerWidget {
  final Todo todo;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TodoItem({
    super.key,
    required this.todo,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final todoNotifier = ref.read(todoListProvider.notifier);
    final tags = ref.watch(tagListProvider).value ?? <Tag>[];

    /// 삭제 시트 표시 중인 Todo 하이라이트
    final highlightedNo = ref.watch(highlightedTodoProvider);
    final isHighlighted = highlightedNo == todo.no;

    return GestureDetector(
      /// [탭] - 수정 시트 열기
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },

      /// [길게 누르기] - 삭제 옵션 시트 표시
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: AnimatedContainer(
        duration: ConfigUI.durationMedium,
        curve: ConfigUI.curveDefault,
        margin: const EdgeInsets.only(
          left: ConfigUI.listItemMarginLeft,
          right: ConfigUI.listItemMarginRight,
          top: ConfigUI.listItemMarginTop,
          bottom: ConfigUI.listItemMarginBottom,
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          /// 1번 Soft UI: 카드 배경 + 부드러운 그림자로 "떠 있는" 느낌
          color: isHighlighted
              ? p.textPrimary.withValues(alpha: 0.08)
              : p.cardBackground,
          borderRadius: ConfigUI.cardRadius,
          border: isHighlighted
              ? Border.all(
                  color: p.textPrimary.withValues(alpha: 0.2),
                  width: ConfigUI.focusBorderWidth,
                )
              : null,
          boxShadow: isHighlighted
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// 왼쪽: 체크박스 + 태그 + 텍스트 (세로 시작 정렬)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// 체크박스 + 태그 색상원: 세로 중앙 정렬
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              todoNotifier.toggleCheck(todo);
                            },
                            child: Icon(
                              todo.isCheck
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: p.textSecondary,
                              size: 32,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: TagHandler.colorOf(tags, todo.tag),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            Text(
                              todo.content.isEmpty
                                  ? "noContent".tr()
                                  : todo.content,
                              style: todo.content.isEmpty
                                  ? TextStyle(
                                      color: p.textSecondary,
                                      fontSize: 16,
                                    )
                                  : TextStyle(
                                      color: p.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                            ),
                            Text(
                              TagHandler.nameOf(tags, todo.tag),
                              style: TextStyle(
                                color: p.textMeta,
                                fontSize: 12,
                              ),
                            ),
                            if (todo.dueDate != null)
                              Text(
                                _formatDueDate(context, todo.dueDate!),
                                style: TextStyle(
                                  color: p.textMeta,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            /// [알람 시계 아이콘] - dueDate 설정 시 표시, 미설정 시에도 영역 유지
            SizedBox(
              width: 40,
              child: Center(
                child: Icon(
                  Icons.access_alarm,
                  color: todo.dueDate != null
                      ? p.alarmAccent
                      : Colors.transparent,
                  size: 28,
                ),
              ),
            ),
            /// [드래그 핸들] - 우측 영역, 폭 축소
            ReorderableDragStartListener(
              index: index,
              child: SizedBox(
                width: 40,
                child: Center(
                  child: Icon(
                    Icons.drag_handle,
                    color: p.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 마감일 포맷 (locale별로 년월일·시간 적용)
String _formatDueDate(BuildContext context, DateTime d) {
  final localeStr = _localeToString(context.locale);
  final format = DateFormat.yMMMd(localeStr).add_jm();
  return format.format(d);
}

String _localeToString(Locale locale) {
  if (locale.countryCode != null) {
    final s = '${locale.languageCode}_${locale.countryCode}';
    if (s == 'zh_CN' || s == 'zh_TW') return s;
    if (locale.languageCode == 'ko') return 'ko_KR';
    if (locale.languageCode == 'en') return 'en_US';
    if (locale.languageCode == 'ja') return 'ja_JP';
    return s;
  }
  return locale.languageCode == 'ko'
      ? 'ko_KR'
      : locale.languageCode == 'ja'
          ? 'ja_JP'
          : locale.languageCode;
}
