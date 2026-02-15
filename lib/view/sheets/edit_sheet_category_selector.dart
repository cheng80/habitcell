// edit_sheet_category_selector.dart
// 습관 편집 시트용 카테고리 선택 위젯 (hivetodo EditSheetTagSelector 방식)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/view/category_settings.dart';
import 'package:habitcell/vm/category_list_notifier.dart';

/// 카테고리 선택 위젯
/// - 색상 칸 위, 이름 아래 (바깥에 배치, 최대 10자, 2줄)
/// - 5열 그리드, 카테고리 관리 버튼
class EditSheetCategorySelector extends ConsumerWidget {
  final String? selectedCategoryId;
  final void Function(String?) onSelected;

  const EditSheetCategorySelector({
    super.key,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final categoriesAsync = ref.watch(categoryListProvider);
    final itemWidth = (MediaQuery.of(context).size.width - 48 - 12 * 4) / 5;

    return categoriesAsync.when(
      data: (categories) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'category'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  _CategoryGridItem(
                    label: '없음',
                    color: Colors.grey,
                    isSelected: selectedCategoryId == null,
                    itemWidth: itemWidth,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onSelected(null);
                    },
                    palette: p,
                  ),
                  ...categories.map((c) => _CategoryGridItem(
                        label: c.name,
                        color: c.color,
                        isSelected: selectedCategoryId == c.id,
                        itemWidth: itemWidth,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onSelected(c.id);
                        },
                        palette: p,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const CategorySettings(),
                  ),
                );
              },
              child: Container(
                height: ConfigUI.minTouchTarget,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: ConfigUI.buttonRadius,
                  border: Border.all(color: p.divider, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Icon(Icons.settings, size: 18, color: p.icon),
                    Text(
                      'categoryManage'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }
}

/// 그리드 아이템: 색상 칸 위, 이름 아래 (최대 10자, 2줄)
class _CategoryGridItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final double itemWidth;
  final VoidCallback onTap;
  final AppColorScheme palette;

  const _CategoryGridItem({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.itemWidth,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ConfigUI.minTouchTarget,
              height: ConfigUI.minTouchTarget,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(
                        color: palette.primary,
                        width: ConfigUI.focusBorderWidth,
                      )
                    : null,
                borderRadius: ConfigUI.tagCellRadius,
                color: isSelected
                    ? color
                    : color.withValues(alpha: 0.6),
              ),
              child: Visibility(
                visible: isSelected,
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: palette.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
