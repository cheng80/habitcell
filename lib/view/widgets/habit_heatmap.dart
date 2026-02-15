// habit_heatmap.dart
// 히트맵 - 기간별 레이아웃 (주/월/년/전체)
//
// [레이아웃 정책]
// - 주: 7셀 1행, 월~일, max 175px
// - 월: 7×5 달력형, 일~토, startWeekday로 1일 위치 결정, max 210px
// - 년/전체: 데이터 있는 월만 표시, 12개월 초과 시 최근 12개월, 3열 그리드, 왼쪽 정렬
// [level] 0=emptyColor, 1~4=levelColors[0~3]

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:habitcell/model/habit_stats.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/date_util.dart';

/// 기간별 히트맵
/// - 주: 7개 셀 1행
/// - 월: 달력형 7x5
/// - 년: 월단위 3개씩 4행, 간격
/// - 전체: 년단위 블록 아래로 추가
/// availableWidth: MediaQuery로 전달 시 가로 폭을 채워 표시
class HabitHeatmap extends StatelessWidget {
  final List<DayAchievement> dayAchievements;
  final Color emptyColor;
  final List<Color> levelColors; // level 1~4
  final HeatmapRange range;
  final double? availableWidth;

  const HabitHeatmap({
    super.key,
    required this.dayAchievements,
    required this.emptyColor,
    required this.levelColors,
    required this.range,
    this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (dayAchievements.isEmpty) return const SizedBox.shrink();

    return switch (range) {
      HeatmapRange.week => _buildWeekView(context),
      HeatmapRange.month => _buildMonthView(context),
      HeatmapRange.year => _buildYearView(context),
      HeatmapRange.all => _buildAllView(context),
    };
  }

  Color _colorForLevel(int level) {
    if (level == 0) return emptyColor;
    return levelColors[(level - 1).clamp(0, levelColors.length - 1)];
  }

  /// 주: 7개 셀 1행 (월~일), 최대 175px로 제한
  Widget _buildWeekView(BuildContext context) {
    const gap = 3.0;
    const maxWidth = 175.0;
    final dateMap = {for (final d in dayAchievements) d.date: d.level};
    final startDate = dayAchievements.first.date;
    final dates = dateRange(startDate, addDays(startDate, 6));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Row(
          children: List.generate(7, (i) {
            final date = i < dates.length ? dates[i] : null;
            final level = date != null ? (dateMap[date] ?? 0) : 0;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 6 ? gap : 0),
                child: AspectRatio(
                  aspectRatio: 1,
                    child: Container(
                    decoration: BoxDecoration(
                      color: _colorForLevel(level),
                      borderRadius: ConfigUI.heatmapCellRadius,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// 월: 달력형 7x5 (일~토), 최대 210px로 제한
  Widget _buildMonthView(BuildContext context) {
    const gap = 2.0;
    const cols = 7;
    const rows = 5;
    const maxWidth = 210.0;

    final firstDate = dayAchievements.first.date;
    final firstDt = DateTime.parse(firstDate);
    final year = firstDt.year;
    final month = firstDt.month;
    // weekday: 1=Mon..7=Sun → %7: 0=Sun, 1=Mon, ... (일요일이 첫 열)
    final startWeekday = firstDt.weekday % 7;
    final lastDay = DateTime(year, month + 1, 0).day;
    final dateMap = {for (final d in dayAchievements) d.date: d.level};

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(rows, (row) {
            return Padding(
              padding: EdgeInsets.only(bottom: row < rows - 1 ? gap : 0),
              child: Row(
                children: List.generate(cols, (col) {
                  final cellIdx = row * cols + col;
                  final dayIdx = cellIdx - startWeekday; // 1일이 startWeekday 열에 옴
                  int level = 0;
                  if (dayIdx >= 0 && dayIdx < lastDay) {
                    final d = DateTime(year, month, dayIdx + 1);
                    final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                    level = dateMap[dateStr] ?? 0;
                  }
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: col < cols - 1 ? gap : 0),
                      child: AspectRatio(
                        aspectRatio: 1,
                    child: Container(
                    decoration: BoxDecoration(
                      color: _colorForLevel(level),
                      borderRadius: ConfigUI.heatmapCellRadius,
                    ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// 년: 데이터 있는 월만 표시 (12개월 미만이면 있는 만큼만, 12개월 이상이면 최근 12개월)
  Widget _buildYearView(BuildContext context) {
    const monthsPerRow = 3;
    const monthGap = 12.0;
    const cellGap = 1.0;
    final w = availableWidth ?? 320.0;
    final monthWidth = (w - (monthsPerRow - 1) * monthGap) / monthsPerRow;
    final cellSize = ((monthWidth - 6 * cellGap) / 7).clamp(4.0, 12.0);

    final dateMap = {for (final d in dayAchievements) d.date: d.level};

    // 데이터가 있는 (year, month) 수집, 정렬
    final monthsWithData = <({int year, int month})>{};
    for (final d in dayAchievements) {
      final dt = DateTime.parse(d.date);
      monthsWithData.add((year: dt.year, month: dt.month));
    }
    var monthsToShow = monthsWithData.toList()
      ..sort((a, b) => a.year != b.year ? a.year.compareTo(b.year) : a.month.compareTo(b.month));

    // 12개월 이상이면 최근 12개월만
    if (monthsToShow.length >= 12) {
      monthsToShow = monthsToShow.sublist(monthsToShow.length - 12);
    }

    Widget buildMonthGrid(int year, int month, BuildContext context) {
      final start = firstDayOfMonth(year, month);
      final startDt = DateTime.parse(start);
      final end = lastDayOfMonth(year, month);
      final endDt = DateTime.parse(end);
      final startWeekday = startDt.weekday % 7;
      final daysInMonth = endDt.day;
      final textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.MMM(context.locale.toString()).format(DateTime(year, month)),
            style: TextStyle(fontSize: 10, color: textColor),
          ),
          const SizedBox(height: 2),
          for (var row = 0; row < ((daysInMonth + startWeekday + 6) / 7).ceil(); row++)
            Padding(
              padding: EdgeInsets.only(
                bottom: row < ((daysInMonth + startWeekday + 6) / 7).ceil() - 1 ? cellGap : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (col) {
                  final dayIdx = row * 7 + col - startWeekday;
                  int level = 0;
                  if (dayIdx >= 0 && dayIdx < daysInMonth) {
                    final d = startDt.add(Duration(days: dayIdx));
                    final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                    level = dateMap[dateStr] ?? 0;
                  }
                  return Padding(
                    padding: EdgeInsets.only(right: col < 6 ? cellGap : 0),
                    child: _HeatmapCell(size: cellSize, color: _colorForLevel(level)),
                  );
                }),
              ),
            ),
        ],
      );
    }

    if (monthsToShow.isEmpty) return const SizedBox.shrink();

    final monthRows = <Widget>[];
    for (var i = 0; i < monthsToShow.length; i += monthsPerRow) {
      final rowMonths = monthsToShow.skip(i).take(monthsPerRow).toList();
      monthRows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + monthsPerRow < monthsToShow.length ? monthGap : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(rowMonths.length, (col) {
              final m = rowMonths[col];
              return Padding(
                padding: EdgeInsets.only(right: col < rowMonths.length - 1 ? monthGap : 0),
                child: buildMonthGrid(m.year, m.month, context),
              );
            }),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: monthRows,
    );
  }

  /// 전체: 년단위 블록 아래로 추가
  Widget _buildAllView(BuildContext context) {
    if (dayAchievements.isEmpty) return const SizedBox.shrink();

    final years = <int>{};
    for (final d in dayAchievements) {
      years.add(DateTime.parse(d.date).year);
    }
    final sortedYears = years.toList()..sort();

    const yearGap = 16.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedYears.map((year) {
        final yearData = dayAchievements
            .where((d) => DateTime.parse(d.date).year == year)
            .toList();
        return Padding(
          padding: EdgeInsets.only(bottom: year != sortedYears.last ? yearGap : 0),
          child: _YearBlock(
            year: year,
            dayAchievements: yearData,
            emptyColor: emptyColor,
            levelColors: levelColors,
            colorForLevel: _colorForLevel,
            textColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            availableWidth: availableWidth,
          ),
        );
      }).toList(),
    );
  }
}

/// 년 단위 블록 - 데이터 있는 월만 표시 (3개씩), 가로 폭 채움
class _YearBlock extends StatelessWidget {
  final int year;
  final List<DayAchievement> dayAchievements;
  final Color emptyColor;
  final List<Color> levelColors;
  final Color Function(int level) colorForLevel;
  final Color textColor;
  final double? availableWidth;

  const _YearBlock({
    required this.year,
    required this.dayAchievements,
    required this.emptyColor,
    required this.levelColors,
    required this.colorForLevel,
    required this.textColor,
    this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    const monthsPerRow = 3;
    const monthGap = 12.0;
    const cellGap = 1.0;
    final w = availableWidth ?? 320.0;
    final monthWidth = (w - (monthsPerRow - 1) * monthGap) / monthsPerRow;
    final cellSize = ((monthWidth - 6 * cellGap) / 7).clamp(3.0, 10.0);

    final dateMap = {for (final d in dayAchievements) d.date: d.level};

    // 데이터가 있는 월만 (1~12 중)
    final monthsWithData = <int>{};
    for (final d in dayAchievements) {
      final dt = DateTime.parse(d.date);
      if (dt.year == year) monthsWithData.add(dt.month);
    }
    final sortedMonths = monthsWithData.toList()..sort();

    if (sortedMonths.isEmpty) return const SizedBox.shrink();

    Widget buildMonthGrid(int month) {
      final start = firstDayOfMonth(year, month);
      final startDt = DateTime.parse(start);
      final end = lastDayOfMonth(year, month);
      final endDt = DateTime.parse(end);
      final startWeekday = startDt.weekday % 7;
      final daysInMonth = endDt.day;
      final totalCells = ((daysInMonth + startWeekday + 6) / 7).ceil() * 7;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var row = 0; row < (totalCells / 7).ceil(); row++)
            Padding(
              padding: EdgeInsets.only(bottom: row < (totalCells / 7).ceil() - 1 ? cellGap : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (col) {
                  final dayIdx = row * 7 + col - startWeekday;
                  int level = 0;
                  if (dayIdx >= 0 && dayIdx < daysInMonth) {
                    final d = startDt.add(Duration(days: dayIdx));
                    final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                    level = dateMap[dateStr] ?? 0;
                  }
                  return Padding(
                    padding: EdgeInsets.only(right: col < 6 ? cellGap : 0),
                    child: _HeatmapCell(size: cellSize, color: colorForLevel(level)),
                  );
                }),
              ),
            ),
        ],
      );
    }

    final monthRows = <Widget>[];
    for (var i = 0; i < sortedMonths.length; i += monthsPerRow) {
      final rowMonths = sortedMonths.skip(i).take(monthsPerRow).toList();
      monthRows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + monthsPerRow < sortedMonths.length ? monthGap : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(rowMonths.length, (col) {
              final month = rowMonths[col];
              return Padding(
                padding: EdgeInsets.only(right: col < rowMonths.length - 1 ? monthGap : 0),
                child: buildMonthGrid(month),
              );
            }),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$year', style: TextStyle(fontSize: 11, color: textColor)),
        const SizedBox(height: 4),
        ...monthRows,
      ],
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final double size;
  final Color color;

  const _HeatmapCell({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: ConfigUI.heatmapCellRadius,
      ),
    );
  }
}

/// 카테고리 색상 기반 레벨 색상 (level 1~4)
/// HSL 기반으로 4단계 구분을 명확히 함 (밝기 0.78→0.58→0.42→0.28)
List<Color> levelColorsFromBase(Color baseColor, Color emptyColor) {
  final hsl = HSLColor.fromColor(baseColor);
  final h = hsl.hue;
  final s = hsl.saturation < 0.15 ? 0.5 : hsl.saturation.clamp(0.4, 1.0);
  return [
    HSLColor.fromAHSL(1, h, s, 0.78).toColor(), // 1단계: 연함
    HSLColor.fromAHSL(1, h, s, 0.58).toColor(), // 2단계
    HSLColor.fromAHSL(1, h, s, 0.42).toColor(), // 3단계
    HSLColor.fromAHSL(1, h, s, 0.28).toColor(), // 4단계: 가장 진함
  ];
}

/// 습관 카드용 컴팩트 히트맵 - 최근 30일, 10x3 그리드
class CompactHabitHeatmap extends StatelessWidget {
  final List<DayAchievement> dayAchievements;
  final Color emptyColor;
  final List<Color> levelColors;
  final double cellSize;

  const CompactHabitHeatmap({
    super.key,
    required this.dayAchievements,
    required this.emptyColor,
    required this.levelColors,
    this.cellSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    const gap = 2.0;
    const daysToShow = 30;
    const cols = 10;
    const rows = 3;

    if (dayAchievements.isEmpty) return const SizedBox.shrink();

    final startIdx = dayAchievements.length > daysToShow
        ? dayAchievements.length - daysToShow
        : 0;
    final slice = dayAchievements.sublist(startIdx);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rows, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row < rows - 1 ? gap : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(cols, (col) {
              final i = row * cols + col;
              final da = i < slice.length ? slice[i] : null;
              final level = da?.level ?? 0;
              final color = level == 0
                  ? emptyColor
                  : levelColors[(level - 1).clamp(0, levelColors.length - 1)];
              return Padding(
                padding: EdgeInsets.only(right: col < cols - 1 ? gap : 0),
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: ConfigUI.heatmapCellRadius,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
