// stat_item.dart
// 분석 화면용 라벨+값 통계 아이템

import 'package:flutter/material.dart';
import 'package:habitcell/theme/app_theme_colors.dart';

/// 라벨 + 값 표시 (7일/30일/연속 등)
class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColorsHelper palette;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: palette.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
