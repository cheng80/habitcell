# HabitCell 앱 아이콘 & 스플래시 - Google Stitch용 프롬프트

---

## 앱 아이콘 (App Icon)

### 프롬프트 1 (히트맵 셀)
```
Simple flat app icon for a habit tracking app. A small 3x3 grid of rounded squares (heatmap style), one or two cells filled with green, rest empty or light gray. Blue (#1976D2) accent border or dot. Clean, minimalist, modern. No text. Suitable for iOS and Android app icon. Square format, 1024x1024.
```

### 프롬프트 2 (체크 + 습관)
```
Minimalist app icon for a habit tracking app. Abstract design: a checkmark overlapping a small grid or streak line. Colors: blue (#1976D2) primary, soft green (#4CAF50) for habit/success. Flat design, rounded corners, soft shadow. Clean and professional. No text. iOS/Android app icon style. Square 1024x1024.
```

### 프롬프트 3 (더 심플)
```
Clean flat app icon for habit app. Single blue (#1976D2) checkmark in a soft white rounded square. Tiny green dot for habit/success accent. Ultra minimal, no gradients. Modern productivity app. 1024x1024 square.
```

### 프롬프트 4 (연속 달성)
```
Minimal app icon. Three connected circles or dots in a row (streak concept), middle one filled green, others outlined. Blue (#1976D2) accent. Flat, rounded, habit tracker style. 1024x1024 square.
```

---

## 스플래시 이미지 (Splash Screen)

> **중요**: flutter_native_splash는 이미지 + 배경색만 지원합니다. 텍스트는 **이미지에 포함**해야 합니다. 스플래시에 "HabitCell" 앱명이 보이려면 아래처럼 텍스트를 포함한 이미지를 생성하세요.

### 프롬프트 1 (라이트 + 텍스트) ← 흰 배경 권장
```
App splash screen for a habit tracking app named "HabitCell". Minimal design. Center: blue checkmark or small heatmap grid icon with "HabitCell" text below it. Pure white (#FFFFFF) or light gray (#F5F5F5) background. Small green accent near the icon. Clean typography, sans-serif font. Portrait 9:19.5. Everything on one image - icon and text together. IMPORTANT: background must be white or very light, NOT black.
```

### 프롬프트 2 (다크 + 텍스트)
```
Splash screen for "HabitCell" habit tracking app. Dark charcoal background (#1A1A1A). Centered: white checkmark or heatmap icon, "HabitCell" text below in white. Subtle green (#4CAF50) accent for habit/success. Minimal, premium feel. Single image with icon and text. Portrait 9:19.5.
```

### 프롬프트 3 (범용 + 텍스트)
```
Minimal splash screen. "HabitCell" app name and blue (#1976D2) checkmark or heatmap icon centered. Soft neutral background. Clean, professional. Single combined image - logo and text "HabitCell" together. Portrait smartphone format.
```

### 프롬프트 4 (로고만 - 배경색 분리)
```
Splash screen center asset only. Blue (#1976D2) checkmark or heatmap grid icon with "HabitCell" text below. Transparent or white background. Minimal design. Will be placed on solid color background by flutter_native_splash. Square or portrait 1:1 ratio for center image.
```

---

## 참고 사항

| 항목 | 값 |
|------|-----|
| 앱명 | HabitCell |
| 콘셉트 | 습관 추적, 히트맵(잔디), Streak, 일일 목표 달성 |
| 프라이머리 | 파란색 #1976D2 |
| 액센트 | 초록 #4CAF50 (달성/습관), 노란 #FFB300 (알람) |
| 스타일 | Flat + Minimalism + Soft UI |

### 아이콘 규격
- iOS: 1024x1024 (App Store)
- Android: 512x512 이상 (adaptive icon용 foreground 추천)

### 스플래시 규격
- **전체 이미지**: 1242x2688 (iPhone) 또는 1080x1920 (Android) – 아이콘+텍스트 모두 포함
- **중앙 에셋만**: 512x512~1024x1024 – 배경색은 pubspec에서 별도 지정, 이미지엔 로고+HabitCell 텍스트

### 적용 방법 (이미지 생성 후)
1. 이미지를 `images/splash.png` 등에 저장
2. `pubspec.yaml`에 `flutter_native_splash` 설정 추가:
```yaml
flutter_native_splash:
  color: "#F5F5F5"
  image: images/splash.png
  # 또는 image_dark, color_dark 등으로 다크 모드 지원
```
3. `dart run flutter_native_splash:create` 실행
