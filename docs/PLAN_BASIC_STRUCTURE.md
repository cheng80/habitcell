# Plan: HabitCell 기본 구조 완성

> **목표**: 로컬 SQLite 기반 HabitCell 앱의 기본 구조가 완전히 나올 때까지

---

## 완료 상태 (2025-02-15)

### Phase 1: Todo/Tag/Hive 제거 ✅
- main.dart: Hive 제거, Todo cleanup 제거
- pubspec.yaml: hive, hive_flutter 제거
- Todo/Tag 관련 파일 삭제 (model, vm, view)
- AppDrawer: 습관 전용으로 단순화
- NotificationService: Todo 의존 제거

### Phase 2: 기본 네비게이션 ✅
- MainScaffold: 홈/분석 BottomNav
- Drawer: 설정 메뉴 (다크모드, 화면꺼짐, 언어, 평점, 습관관리)

### Phase 3: 화면 골격 ✅
- 분석 화면: "히트맵 (준비 중)" 플레이스홀더
- 습관 관리: 플레이스홀더 (Drawer 메뉴)

### Phase 4: 정리
- todo.md 갱신 필요

---

## 제외 (후순위)

- 히트맵 실제 구현
- Streak/통계
- 로컬 알림 (습관 reminder)
- 백업/복구
- FastAPI/MySQL
