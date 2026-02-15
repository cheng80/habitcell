// heatmap_theme_notifier.dart
// 히트맵 색상 테마
//
// [정의] HeatmapTheme: 7종 (github, ocean, sunset, lavender, mint, rose, monochrome)
// [정의] levels[0~3]: 달성 강도 1~4에 대응, empty: 미달성(회색)
// [저장] AppStorage(GetStorage) heatmap_theme 키

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/util/app_storage.dart';
import 'package:habitcell/view/widgets/habit_heatmap.dart';

/// 히트맵 테마 종류
enum HeatmapTheme {
  github('github'),
  ocean('ocean'),
  sunset('sunset'),
  lavender('lavender'),
  mint('mint'),
  rose('rose'),
  monochrome('monochrome');

  final String key;
  const HeatmapTheme(this.key);

  static HeatmapTheme fromKey(String? key) {
    return HeatmapTheme.values.firstWhere(
      (t) => t.key == key,
      orElse: () => HeatmapTheme.github,
    );
  }
}

/// 테마별 색상 (empty + level 1~4)
HeatmapThemeColors getHeatmapColors(HeatmapTheme theme, Color emptyColor) {
  return switch (theme) {
    HeatmapTheme.github => HeatmapThemeColors(
          empty: emptyColor,
          levels: [
            const Color(0xFF9BE9A8),
            const Color(0xFF40C463),
            const Color(0xFF30A14E),
            const Color(0xFF216E39),
          ],
        ),
    HeatmapTheme.ocean => HeatmapThemeColors(
          empty: emptyColor,
          levels: [
            const Color(0xFF9DD9F2),
            const Color(0xFF5BA4CF),
            const Color(0xFF2E7AB8),
            const Color(0xFF1A4D7A),
          ],
        ),
    HeatmapTheme.sunset => HeatmapThemeColors(
          empty: emptyColor,
          levels: [
            const Color(0xFFFFE4B5),
            const Color(0xFFFFA07A),
            const Color(0xFFFF6347),
            const Color(0xFFCD3333),
          ],
        ),
    HeatmapTheme.lavender => HeatmapThemeColors(
          empty: emptyColor,
          levels: [
            const Color(0xFFE6E6FA),
            const Color(0xFFB8B8E8),
            const Color(0xFF8B7BD4),
            const Color(0xFF5B4BB8),
          ],
        ),
    HeatmapTheme.mint => HeatmapThemeColors(
          empty: emptyColor,
          levels: [
            const Color(0xFFB2F5EA),
            const Color(0xFF5EEAD4),
            const Color(0xFF2DD4BF),
            const Color(0xFF0D9488),
          ],
        ),
    HeatmapTheme.rose => HeatmapThemeColors(
          empty: emptyColor,
          levels: [
            const Color(0xFFFFE4EC),
            const Color(0xFFF9A8D4),
            const Color(0xFFEC4899),
            const Color(0xFFBE185D),
          ],
        ),
    HeatmapTheme.monochrome => HeatmapThemeColors(
          empty: emptyColor,
          levels: [
            const Color(0xFFE5E5E5),
            const Color(0xFFA3A3A3),
            const Color(0xFF737373),
            const Color(0xFF404040),
          ],
        ),
  };
}

class HeatmapThemeColors {
  final Color empty;
  final List<Color> levels;
  const HeatmapThemeColors({required this.empty, required this.levels});
}

final heatmapThemeNotifierProvider =
    NotifierProvider<HeatmapThemeNotifier, HeatmapTheme>(HeatmapThemeNotifier.new);

class HeatmapThemeNotifier extends Notifier<HeatmapTheme> {
  @override
  HeatmapTheme build() =>
      HeatmapTheme.fromKey(AppStorage.getHeatmapTheme());

  void setTheme(HeatmapTheme theme) {
    state = theme;
    AppStorage.saveHeatmapTheme(theme.key);
  }
}
