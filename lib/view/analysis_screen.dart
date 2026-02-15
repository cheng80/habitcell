// analysis_screen.dart
// 분석 탭 - 히트맵, Streak, 통계 (추후 구현)

import 'package:flutter/material.dart';
import 'package:habitcell/theme/app_colors.dart';

/// 분석 화면 - 플레이스홀더 (MainScaffold의 body로 사용)
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: p.textSecondary),
          const SizedBox(height: 16),
          Text(
            '히트맵 (준비 중)',
            style: TextStyle(color: p.textSecondary, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
