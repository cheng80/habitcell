// home_widgets.dart
// 홈 화면에서 사용하는 분리된 위젯 모음

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:habitcell/model/tag.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/vm/home_filter_notifier.dart';
import 'package:habitcell/vm/tag_list_notifier.dart';

/// ─────────────────────────────────────────────────
/// 앱바 타이틀 (빈 영역 탭 → 검색 모드 전환)
/// ─────────────────────────────────────────────────
class HomeTitleBar extends StatelessWidget {
  final VoidCallback onToggleSearch;

  const HomeTitleBar({super.key, required this.onToggleSearch});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Text(
          "TODO",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: p.textPrimary,
            fontSize: 24,
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onToggleSearch,
            child: SizedBox(height: ConfigUI.minTouchTarget),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────
/// 앱바 검색 입력 필드
/// ─────────────────────────────────────────────────
class HomeSearchField extends ConsumerWidget {
  final TextEditingController controller;
  final VoidCallback onToggleSearch;

  const HomeSearchField({
    super.key,
    required this.controller,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final hasText = ref.watch(searchQueryProvider).trim().isNotEmpty;

    return TextField(
      controller: controller,
      style: TextStyle(color: p.searchFieldText, fontSize: 16),
      cursorColor: p.searchFieldText,
      decoration: InputDecoration(
        hintText: 'search'.tr(),
        hintStyle: TextStyle(color: p.searchFieldHint),
        filled: true,
        fillColor: p.searchFieldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ConfigUI.inputPaddingH,
          vertical: ConfigUI.inputPaddingV,
        ),
        border: OutlineInputBorder(
          borderRadius: ConfigUI.inputRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ConfigUI.inputRadius,
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            if (hasText) {
              controller.clear();
              ref.read(searchQueryProvider.notifier).setQuery('');
            } else {
              onToggleSearch();
            }
          },
          icon: Icon(
            hasText ? Icons.clear : Icons.close,
            color: p.searchFieldText,
          ),
        ),
      ),
      textInputAction: TextInputAction.search,
    );
  }
}

/// ─────────────────────────────────────────────────
/// 필터 바 (태그 드롭다운 + 상태 칩)
/// filterShowcaseKey: 튜토리얼 5단계(전체/미완료/완료) Showcase용
/// ─────────────────────────────────────────────────
class HomeFilterRow extends ConsumerWidget {
  final GlobalKey? filterShowcaseKey;

  const HomeFilterRow({super.key, this.filterShowcaseKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = _buildStatusChips(context, ref);
    final p = context.palette;
    final chipsWidget = filterShowcaseKey != null
        ? Showcase(
            key: filterShowcaseKey!,
            description: 'tutorial_step_5'.tr(),
            tooltipBackgroundColor: p.sheetBackground,
            textColor: p.textOnSheet,
            tooltipBorderRadius: ConfigUI.cardRadius,
            child: chips,
          )
        : chips;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConfigUI.screenPaddingH,
        12,
        ConfigUI.screenPaddingH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// [전체][미완료][완료] 왼쪽 / [🔔] 오른쪽 정렬
          Row(
            children: [
              chipsWidget,
              const Spacer(),
              _buildDueDateFilterIcon(context, ref),
            ],
          ),
          _buildTagDropdown(context, ref),
        ],
      ),
    );
  }

  /// 마감일 필터 아이콘 (탭 시 마감일 있는 것만 ↔ 전체)
  Widget _buildDueDateFilterIcon(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isActive = ref.watch(dueDateFilterProvider) == true;

    return IconButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        ref.read(dueDateFilterProvider.notifier).toggle();
      },
      icon: Icon(
        Icons.access_alarm,
        color: isActive ? p.alarmAccent : p.icon,
        size: 28,
      ),
      tooltip: isActive ? 'dueDateFilterOn'.tr() : 'dueDateFilterOff'.tr(),
    );
  }

  /// 태그 드롭다운
  Widget _buildTagDropdown(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tagNames = ref.watch(tagListProvider).value ?? <Tag>[];

    final items = <DropdownMenuItem<int?>>[
      DropdownMenuItem<int?>(value: null, child: Text('all'.tr())),
      ...tagNames.map(
        (tag) => DropdownMenuItem<int?>(
          value: tag.id,
          child: Row(
            spacing: 8,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: tag.color,
                  shape: BoxShape.circle,
                ),
              ),
              Text(tag.name),
            ],
          ),
        ),
      ),
    ];

    final selectedTag = ref.watch(selectedTagProvider);

    /// isExpanded: 부모 너비를 그대로 사용 → 선택 변경 시 흔들림 방지
    return DropdownButtonHideUnderline(
      child: DropdownButton<int?>(
        isExpanded: true,
        dropdownColor: p.dropdownBg,
        value: selectedTag,
        iconEnabledColor: p.icon,
        style: TextStyle(color: p.textPrimary, fontSize: 14),
        items: items,
        selectedItemBuilder: (context) {
          return [
            /// '전체' 항목
            Align(alignment: Alignment.centerLeft, child: Text('all'.tr())),

            /// 태그 항목 (색상 원 + 이름)
            ...tagNames.map(
              (tag) => Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: tag.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(tag.name),
                  ],
                ),
              ),
            ),
          ];
        },
        onChanged: (value) {
          ref.read(selectedTagProvider.notifier).setTag(value);
        },
      ),
    );
  }

  /// 상태 필터 칩 (전체/미완료/완료)
  Widget _buildStatusChips(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final current = ref.watch(todoStatusProvider);

    Widget chip(TodoStatus status, String label) {
      final selected = current == status;
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          ref.read(todoStatusProvider.notifier).setStatus(status);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ConfigUI.chipPaddingH,
            vertical: ConfigUI.chipPaddingV,
          ),
          decoration: BoxDecoration(
            color: selected ? p.chipSelectedBg : p.chipUnselectedBg,
            borderRadius: ConfigUI.chipRadius,

            /// 3번 Soft UI: 칩에 살짝 입체감
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? p.chipSelectedText : p.chipUnselectedText,
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Row(
      spacing: 8,
      children: [
        chip(TodoStatus.all, 'all'.tr()),
        chip(TodoStatus.unchecked, 'unchecked'.tr()),
        chip(TodoStatus.checked, 'checked'.tr()),
      ],
    );
  }
}
