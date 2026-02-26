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
  final rootContext = Navigator.of(context, rootNavigator: true).context;
  showModalBottomSheet(
    context: rootContext,
    useRootNavigator: true,
    backgroundColor: p.sheetBackground,
    shape: defaultSheetShape,
    constraints: sheetConstraints(rootContext, minHeightRatio: 0.35),
    builder: (ctx) {
      final tablet = isTablet(ctx);
      final cardWidth = tablet ? 116.0 : 88.0;
      final cellSize = tablet ? 14.0 : 10.0;
      final cellPad = tablet ? 3.0 : 2.0;
      final gap = tablet ? 20.0 : 16.0;
      final labelSize = tablet ? ConfigUI.fontSizeLabel : ConfigUI.fontSizeMeta;

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? 32 : ConfigUI.sheetPaddingH,
            vertical: tablet ? 24 : ConfigUI.paddingCard,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'heatmapTheme'.tr(),
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: tablet
                      ? ConfigUI.fontSizeTitle
                      : ConfigUI.fontSizeSubtitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: tablet ? 28 : 20),
              Flexible(
                child: Center(
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    alignment: WrapAlignment.center,
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
                          width: cardWidth,
                          padding: EdgeInsets.symmetric(
                            horizontal: tablet ? 10 : 8,
                            vertical: tablet ? 16 : 12,
                          ),
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
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    4,
                                    (i) => Padding(
                                      padding: EdgeInsets.all(cellPad),
                                      child: Container(
                                        width: cellSize,
                                        height: cellSize,
                                        decoration: BoxDecoration(
                                          color: colors.levels[i.clamp(
                                              0, colors.levels.length - 1)],
                                          borderRadius:
                                              ConfigUI.heatmapCellRadius,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: tablet ? 12 : 10),
                              Text(
                                'heatmapTheme_${theme.key}'.tr(),
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontSize: labelSize,
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
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
