// edit_sheet_tag_selector.dart
// TodoEditSheet 태그 선택 + 태그 관리 버튼

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagdo/model/tag.dart';
import 'package:tagdo/theme/app_colors.dart';
import 'package:tagdo/theme/config_ui.dart';
import 'package:tagdo/view/tag_settings.dart';
import 'package:tagdo/vm/edit_sheet_notifier.dart';
import 'package:tagdo/vm/tag_list_notifier.dart';

/// [EditSheetTagSelector] - 태그 선택 영역 + 태그 관리 버튼
class EditSheetTagSelector extends ConsumerWidget {
  const EditSheetTagSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final selectedId = ref.watch(editTagProvider);
    final tags = ref.watch(tagListProvider).value ?? <Tag>[];
    final itemWidth =
        (MediaQuery.of(context).size.width - 48 - 12 * 4) / 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: ConfigUI.sheetPaddingH),
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            "tag",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: p.iconOnSheet,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 12,
              runSpacing: 16,
              children: tags.map((tag) {
                final isSelected = selectedId == tag.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(editTagProvider.notifier).setTag(tag.id);
                  },
                  child: SizedBox(
                    width: itemWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Container(
                          width: ConfigUI.minTouchTarget,
                          height: ConfigUI.minTouchTarget,
                          decoration: BoxDecoration(
                            border: isSelected
                                ? Border.all(
                                    color: p.iconOnSheet,
                                    width: ConfigUI.focusBorderWidth,
                                  )
                                : null,
                            borderRadius: ConfigUI.tagCellRadius,
                            color: isSelected
                                ? tag.color
                                : tag.color.withValues(alpha: 0.6),
                          ),
                          child: Visibility(
                            visible: isSelected,
                            child: Icon(
                              Icons.check,
                              color: p.textOnSheet,
                            ),
                          ),
                        ),
                        Text(
                          tag.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textOnSheet,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ConfigUI.sheetPaddingH,
              vertical: 8,
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const TagSettings(),
                  ),
                );
              },
              child: Container(
                height: ConfigUI.minTouchTarget,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: ConfigUI.buttonRadius,
                  border: Border.all(color: p.iconOnSheet, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 6,
                  children: [
                    Icon(Icons.settings, size: 18, color: p.iconOnSheet),
                    Text(
                      "tagManage".tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: p.textOnSheet,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
