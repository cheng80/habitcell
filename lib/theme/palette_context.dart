import 'package:flutter/material.dart';
import 'app_colors.dart';

// BuildContext 확장 – context.palette로 현재 팔레트 접근
//
// 사용 예시:
// ```dart
// final p = context.palette; // AppColorScheme
// Container(color: p.primary)
// ```
extension PaletteContext on BuildContext {
  // 현재 테마 모드에 맞는 AppColorScheme 반환
  //
  // Theme.of(context).brightness를 기준으로 라이트/다크 모드를 판단합니다.
  AppColorScheme get palette {
    final brightness = Theme.of(this).brightness;
    if (brightness == Brightness.dark) {
      return AppColors.dark;
    } else {
      return AppColors.light;
    }
  }
}
