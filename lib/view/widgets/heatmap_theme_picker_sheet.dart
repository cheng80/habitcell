// heatmap_theme_picker_sheet.dart
// 잔디(히트맵) 테마 선택 바텀시트

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';
import 'package:habitcell/vm/heatmap_theme_notifier.dart';

/// 잔디 테마 선택 바텀시트 표시
void showHeatmapThemePickerSheet(
  BuildContext context,
  HeatmapThemeNotifier notifier,
  HeatmapTheme current,
) {
  final p = context.appTheme;
  showModalBottomSheet(
    context: context,
    backgroundColor: p.sheetBackground,
    shape: defaultSheetShape,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ConfigUI.paddingCard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'heatmapTheme'.tr(),
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: HeatmapTheme.values.map((theme) {
                final isSelected = current == theme;
                final colors = getHeatmapColors(theme, p.divider);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.setTheme(theme);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.all(ConfigUI.chipPaddingHCompact),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? p.primary.withValues(alpha: 0.2)
                          : p.cardBackground,
                      borderRadius: ConfigUI.cardRadius,
                      border: Border.all(
                        color: isSelected ? p.primary : p.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (i) => Padding(
                              padding: const EdgeInsets.all(1),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.levels[
                                      i.clamp(0, colors.levels.length - 1)],
                                  borderRadius: ConfigUI.heatmapCellRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'heatmapTheme_${theme.key}'.tr(),
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
