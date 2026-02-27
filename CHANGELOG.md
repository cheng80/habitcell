# Changelog

## 1.0.1+3 (2026-02-26)

### 개선
- 습관 카드 체크 즉시 반영 (Optimistic Update 적용, DB 대기 제거)
- 체크/해제 애니메이션 제거 → 즉각 반응
- 카드 접힌 상태에서 하단 여백 터치 시에도 체크(+1) 가능
- 바텀시트 태블릿(iPad, Android 패드) 대응: 최소 높이·최대 너비 제한
- 잔디 색상 테마 시트: 셀 크기 확대, 태블릿 레이아웃 개선
- 언어 선택 시트: 타이틀 추가, 태블릿 패딩·폰트 확대
- 습관 편집/삭제/카테고리 편집 시트: 태블릿 패딩 확대
- 키보드 unfocus 처리 (빈 영역 터치 시 키보드 내려감)
- 습관 편집 시트 스크롤 가능 (소형 기기 오버플로우 해결)

### 웹페이지
- TagDo / HabitCell 스토어 링크 적용 (Google Play, App Store)
- App Hub 포털에 스토어 링크 추가
- "다음 앱 자리" 템플릿 카드 주석 처리

### Google Play 출시 노트 (한국어)

```
[v1.0.1 업데이트]

- 체크 속도 개선: 습관 체크/해제가 즉시 반영됩니다
- 터치 영역 확대: 카드 접힌 상태에서도 터치하면 바로 체크됩니다
- 태블릿 지원 개선: iPad, Android 태블릿에서 시트 레이아웃이 더 보기 좋게 개선되었습니다
- 잔디 테마 선택 화면 개선: 색상 미리보기가 더 크고 선택하기 쉬워졌습니다
- 키보드 자동 내림: 입력 필드 외 영역 터치 시 키보드가 자동으로 내려갑니다
- 기타 안정성 개선
```

### Google Play Release Notes (English)

```
[v1.0.1 Update]

- Faster check: Habit check/uncheck now reflects instantly
- Larger touch area: Tap anywhere on a collapsed card to quickly check in
- Tablet support: Improved sheet layout for iPad and Android tablets
- Theme picker: Larger color previews for easier selection
- Auto keyboard dismiss: Keyboard hides when tapping outside input fields
- Other stability improvements
```

---

## 1.0.0+2 (2026-02 초)

- 첫 출시 (Google Play / App Store)
- 일별 +1/-1 기록, 히트맵, Streak 분석
- 카테고리 커스터마이징, 알림, 배지
- 라이트/다크/시스템 테마
- 한국어, 영어, 일본어, 중국어(간체/번체) 지원
- 완전 오프라인 (데이터 기기 로컬 저장)
