// sheet_util.dart
// BottomSheet 공통 스타일 (iPad / Android 태블릿 공통 대응)

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habitcell/util/config_ui.dart';

/// 기본 BottomSheet 모양 (둥근 상단 모서리)
ShapeBorder get defaultSheetShape => RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ConfigUI.radiusSheet),
      ),
    );

/// shortestSide >= 600 → 태블릿 (iPad, Android 패드 모두 포함)
bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// 태블릿 바텀시트 최대 너비
const double _tabletSheetMaxWidth = 580.0;

/// 화면 크기 기반 바텀시트 constraints.
///
/// - 태블릿(shortestSide≥600): 너비 제한 + 최소 높이 보장
/// - 폰: 전체 너비, 최소 높이만 적용
/// - landscape에서 minHeight가 화면의 절반을 넘지 않도록 클램프
BoxConstraints sheetConstraints(
  BuildContext context, {
  double minHeightRatio = 0.3,
  double maxHeightRatio = 0.85,
}) {
  final size = MediaQuery.sizeOf(context);
  final tablet = size.shortestSide >= 600;

  final effectiveMin = min(size.height * minHeightRatio, size.height * 0.5);
  final effectiveMax = size.height * maxHeightRatio;

  return BoxConstraints(
    minHeight: effectiveMin,
    maxHeight: effectiveMax,
    maxWidth: tablet
        ? min(size.width * 0.65, _tabletSheetMaxWidth)
        : size.width,
  );
}
