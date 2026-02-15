import 'package:flutter/material.dart';
import 'common_color_scheme.dart';

// 앱 전체 컬러 스키마
//
// CommonColorScheme을 감싸서 getter로 간편 접근을 제공합니다.
// 추후 앱 전용 스키마가 필요하면 여기에 추가합니다.
class AppColorScheme {
  final CommonColorScheme common;

  const AppColorScheme({required this.common});

  // ─── 배경 ───
  Color get background => common.background;
  Color get cardBackground => common.cardBackground;
  Color get sheetBackground => common.sheetBackground;

  // ─── 브랜드 ───
  Color get primary => common.primary;
  Color get accent => common.accent;

  // ─── 텍스트 ───
  Color get textPrimary => common.textPrimary;
  Color get textSecondary => common.textSecondary;
  Color get textMeta => common.textMeta;
  Color get textOnPrimary => common.textOnPrimary;
  Color get textOnSheet => common.textOnSheet;

  // ─── UI 요소 ───
  Color get divider => common.divider;
  Color get icon => common.icon;
  Color get iconOnSheet => common.iconOnSheet;
  Color get chipSelectedBg => common.chipSelectedBg;
  Color get chipSelectedText => common.chipSelectedText;
  Color get chipUnselectedBg => common.chipUnselectedBg;
  Color get chipUnselectedText => common.chipUnselectedText;
  Color get dropdownBg => common.dropdownBg;
  Color get searchFieldBg => common.searchFieldBg;
  Color get searchFieldText => common.searchFieldText;
  Color get searchFieldHint => common.searchFieldHint;
  Color get alarmAccent => common.alarmAccent;
}
