import 'package:flutter/material.dart';

// 공용 컬러 스키마
//
// 앱 전체에서 사용하는 시맨틱 컬러를 정의합니다.
// 하드코딩 색상 대신 이 스키마의 필드를 사용합니다.
class CommonColorScheme {
  // ─── 배경 ───
  final Color background; // 전체 배경 (Scaffold, AppBar)
  final Color cardBackground; // 카드/패널 배경
  final Color sheetBackground; // BottomSheet 배경

  // ─── 브랜드 ───
  final Color primary; // 주요 포인트 색
  final Color accent; // 보조 포인트 / 경고 (삭제 등)

  // ─── 텍스트 ───
  final Color textPrimary; // 기본 텍스트
  final Color textSecondary; // 보조 텍스트 (비활성, 플레이스홀더)
  final Color textMeta; // 메타 텍스트 (날짜, 태그 이름)
  final Color textOnPrimary; // Primary 배경 위 텍스트
  final Color textOnSheet; // BottomSheet 위 텍스트

  // ─── UI 요소 ───
  final Color divider; // 구분선
  final Color icon; // 아이콘 기본 색
  final Color iconOnSheet; // BottomSheet 위 아이콘
  final Color chipSelectedBg; // 필터 칩 선택 배경
  final Color chipSelectedText; // 필터 칩 선택 텍스트
  final Color chipUnselectedBg; // 필터 칩 비선택 배경
  final Color chipUnselectedText; // 필터 칩 비선택 텍스트
  final Color dropdownBg; // 드롭다운 배경
  final Color searchFieldBg; // 검색 필드 배경
  final Color searchFieldText; // 검색 필드 텍스트
  final Color searchFieldHint; // 검색 필드 힌트
  final Color alarmAccent; // 마감일/알람 아이콘 색 (노란 계열)

  const CommonColorScheme({
    required this.background,
    required this.cardBackground,
    required this.sheetBackground,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMeta,
    required this.textOnPrimary,
    required this.textOnSheet,
    required this.divider,
    required this.icon,
    required this.iconOnSheet,
    required this.chipSelectedBg,
    required this.chipSelectedText,
    required this.chipUnselectedBg,
    required this.chipUnselectedText,
    required this.dropdownBg,
    required this.searchFieldBg,
    required this.searchFieldText,
    required this.searchFieldHint,
    required this.alarmAccent,
  });
}
