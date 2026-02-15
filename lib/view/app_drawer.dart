// app_drawer.dart
// 앱 사이드 메뉴 (Drawer)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/todo.dart';
import 'package:habitcell/service/in_app_review_service.dart';
import 'package:habitcell/service/notification_service.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/util/app_storage.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:habitcell/view/sheets/todo_edit_sheet.dart';
import 'package:habitcell/view/tag_settings.dart';
import 'package:habitcell/vm/theme_notifier.dart';
import 'package:habitcell/vm/todo_list_notifier.dart';
import 'package:habitcell/vm/wakelock_notifier.dart';

/// AppDrawer - 설정 및 부가 기능을 위한 사이드 메뉴
///
/// - 세팅 헤더 길게 누르면 개발용 버튼(더미 데이터, 추가) 표시/숨김
/// - tagManageShowcaseKey: 튜토리얼 1단계(태그 관리) Showcase용
/// - onTutorialReplay: Drawer "튜토리얼 다시 보기" 탭 시 콜백
class AppDrawer extends ConsumerStatefulWidget {
  final VoidCallback? onTutorialReplay;
  final GlobalKey? tagManageShowcaseKey;

  const AppDrawer({super.key, this.onTutorialReplay, this.tagManageShowcaseKey});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _showDevButtons = false;

  /// 태그 관리 ListTile - tagManageShowcaseKey 있으면 Showcase로 감싸서 튜토리얼 1단계 대상
  Widget _wrapTagManageTile(BuildContext context, AppColorScheme p) {
    final tile = ListTile(
      leading: Icon(Icons.label_outline, color: p.icon),
      title: Text(
        'tagManage'.tr(),
        style: TextStyle(color: p.textPrimary, fontSize: 16),
      ),
      trailing: Icon(Icons.chevron_right, color: p.textSecondary),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TagSettings()),
        );
      },
    );
    final key = widget.tagManageShowcaseKey;
    if (key != null) {
      return Showcase(
        key: key,
        description: 'tutorial_step_1'.tr(),
        tooltipBackgroundColor: p.sheetBackground,
        textColor: p.textOnSheet,
        tooltipBorderRadius: ConfigUI.cardRadius,
        child: tile,
      );
    }
    return tile;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Drawer(
      backgroundColor: p.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 헤더 (설정 아이콘 + 타이틀) - 길게 누르면 개발용 버튼 토글
            GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                setState(() => _showDevButtons = !_showDevButtons);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ConfigUI.screenPaddingH, 24, ConfigUI.screenPaddingH, 16,
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(Icons.settings, color: p.icon, size: 28),
                    Text(
                      'settings'.tr(),
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showDevButtons) ...[
              ListTile(
                leading: Icon(Icons.data_object, color: p.icon),
                title: Text(
                  'dummyData'.tr(),
                  style: TextStyle(color: p.textPrimary, fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _insertDummyData(ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.add, color: p.icon),
                title: Text(
                  'add'.tr(),
                  style: TextStyle(color: p.textPrimary, fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _showAddSheet(context, ref);
                },
              ),
              Divider(color: p.divider, height: 1),
            ],
            Divider(color: p.divider, height: 1),

            /// 다크모드 스위치
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ConfigUI.screenPaddingH,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'darkMode'.tr(),
                    style: TextStyle(color: p.textPrimary, fontSize: 16),
                  ),
                  Switch(
                    value: isDark,
                    activeThumbColor: p.chipSelectedBg,
                    activeTrackColor: p.chipUnselectedBg,
                    inactiveThumbColor: p.textMeta,
                    inactiveTrackColor: p.chipUnselectedBg,
                    onChanged: (_) {
                      ref.read(themeNotifierProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            ),

            /// 화면 꺼짐 방지 스위치
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ConfigUI.screenPaddingH,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'screenWakeLock'.tr(),
                    style: TextStyle(color: p.textPrimary, fontSize: 16),
                  ),
                  Switch(
                    value: ref.watch(wakelockNotifierProvider),
                    activeThumbColor: p.chipSelectedBg,
                    activeTrackColor: p.chipUnselectedBg,
                    inactiveThumbColor: p.textMeta,
                    inactiveTrackColor: p.chipUnselectedBg,
                    onChanged: (_) {
                      ref.read(wakelockNotifierProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            ),

            Divider(color: p.divider, height: 1),

            /// 언어 선택
            ListTile(
              leading: Icon(Icons.language, color: p.icon),
              title: Text(
                'language'.tr(),
                style: TextStyle(color: p.textPrimary, fontSize: 16),
              ),
              trailing: Icon(Icons.chevron_right, color: p.textSecondary),
              onTap: () {
                Navigator.pop(context);
                _showLanguagePicker(context);
              },
            ),

            /// 평점 남기기
            ListTile(
              leading: Icon(Icons.star_outline, color: p.icon),
              title: Text(
                'rateApp'.tr(),
                style: TextStyle(color: p.textPrimary, fontSize: 16),
              ),
              trailing: Icon(Icons.open_in_new, color: p.textSecondary, size: 20),
              onTap: () async {
                Navigator.pop(context);
                final ok = await InAppReviewService().openStoreListing();
                if (context.mounted && !ok) {
                  showCommonSnackBar(
                    context,
                    message: '평점 기능은 앱 출시 후 이용 가능합니다.',
                  );
                }
              },
            ),

            /// 태그 관리 버튼
            _wrapTagManageTile(context, p),

            /// 튜토리얼 다시 보기
            ListTile(
              leading: Icon(Icons.school_outlined, color: p.icon),
              title: Text(
                'tutorial_replay'.tr(),
                style: TextStyle(color: p.textPrimary, fontSize: 16),
              ),
              trailing: Icon(Icons.chevron_right, color: p.textSecondary),
              onTap: () {
                Navigator.pop(context);
                AppStorage.resetTutorialCompleted();
                widget.onTutorialReplay?.call();
              },
            ),

            /// 알람 상태 확인 (디버깅)
            ListTile(
              leading: Icon(Icons.access_alarm, color: p.icon),
              title: Text(
                'alarmStatusCheck'.tr(),
                style: TextStyle(color: p.textPrimary, fontSize: 16),
              ),
              trailing: Icon(Icons.info_outline, color: p.textSecondary),
              onTap: () async {
                Navigator.pop(context);
                final todos = await ref.read(todoListProvider.future);
                final withDueDate =
                    todos.where((t) => t.dueDate != null).toList();
                final pending =
                    await NotificationService().checkPendingNotifications();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'alarmStatusSummary'.tr(namedArgs: {
                          'count': '${withDueDate.length}',
                          'alarmCount': '${pending.length}',
                        }),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 개발용: 더미 Todo 일괄 삽입
  Future<void> _insertDummyData(WidgetRef ref) async {
    final now = DateTime.now();
    final baseNo = now.millisecondsSinceEpoch;
    final items = [
      ('회의 준비 자료 정리', 0, null),
      ('이메일 답장하기', 0, now.add(const Duration(hours: 2))),
      ('운동하기', 4, null),
      ('영어 단어 10개 외우기', 2, null),
      ('장보기', 5, now.add(const Duration(days: 1))),
      ('책 읽기 30분', 3, null),
      ('가족 저녁 약속', 6, now.add(const Duration(days: 2))),
      ('용돈 기입장 작성', 7, null),
      ('기차표 예약', 8, now.add(const Duration(days: 3))),
      ('기타 잡무 처리', 9, null),
    ];
    final dummyTodos = <Todo>[];
    for (var i = 0; i < items.length; i++) {
      final (content, tag, dueDate) = items[i];
      final todo = Todo.create(content, tag, dueDate: dueDate)
          .copyWith(no: baseNo + i);
      dummyTodos.add(todo);
    }
    dummyTodos.add(
      Todo.create('완료된 할 일 샘플', 0).copyWith(no: baseNo + 10, isCheck: true),
    );
    await ref.read(todoListProvider.notifier).insertDummyTodos(dummyTodos);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${dummyTodos.length}개 추가됨')),
      );
    }
  }

  /// 개발용: Todo 추가 시트 표시
  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final result = await showModalBottomSheet<Todo>(
      context: context,
      backgroundColor: p.sheetBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ConfigUI.radiusSheet),
        ),
      ),
      builder: (ctx) => TodoEditSheet(update: null),
      isScrollControlled: true,
    );
    if (result != null && context.mounted) {
      await ref.read(todoListProvider.notifier).insertTodo(result);
    }
  }
}

void _showLanguagePicker(BuildContext context) {
  final p = context.palette;
  showModalBottomSheet(
      context: context,
      backgroundColor: p.sheetBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ConfigUI.radiusSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langTile(ctx, const Locale('ko'), 'langKo'.tr()),
            _langTile(ctx, const Locale('en'), 'langEn'.tr()),
            _langTile(ctx, const Locale('ja'), 'langJa'.tr()),
            _langTile(ctx, const Locale('zh', 'CN'), 'langZhCN'.tr()),
            _langTile(ctx, const Locale('zh', 'TW'), 'langZhTW'.tr()),
          ],
        ),
      ),
    );
}

Widget _langTile(BuildContext context, Locale locale, String label) {
    final p = context.palette;
    final isSelected = context.locale == locale;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? p.accent : p.icon,
      ),
      title: Text(label, style: TextStyle(color: p.textOnSheet)),
      onTap: () {
      context.setLocale(locale);
      Navigator.pop(context);
    },
  );
}
