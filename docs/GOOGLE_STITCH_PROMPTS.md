# TagDo 앱 아이콘 & 스플래시 - Google Stitch용 프롬프트

---

## 앱 아이콘 (App Icon)

### 프롬프트 1 (미니멀 체크리스트)
```
Simple flat app icon for a todo and task management app. A single checkmark inside a rounded square badge. Soft gradient background from light gray to white. Blue (#1976D2) checkmark with a subtle yellow (#FFB300) accent dot. Clean, minimalist, modern. No text. Suitable for iOS and Android app icon. Square format, 1024x1024.
```

### 프롬프트 2 (태그 + 할 일)
```
Minimalist app icon for a tag-based todo app. Abstract design: a small colored tag or label shape overlapping a checklist line. Colors: blue primary, soft yellow accent. Flat design, rounded corners, soft shadow. Clean and professional. No text. iOS/Android app icon style. Square 1024x1024.
```

### 프롬프트 3 (더 심플)
```
Clean flat app icon. Single blue checkmark in a soft white rounded square. Tiny yellow dot for alarm/reminder accent. Ultra minimal, no gradients. Modern productivity app. 1024x1024 square.
```

---

## 스플래시 이미지 (Splash Screen)

> **중요**: flutter_native_splash는 이미지 + 배경색만 지원합니다. 텍스트는 **이미지에 포함**해야 합니다. 스플래시에 "TagDo" 앱명이 보이려면 아래처럼 텍스트를 포함한 이미지를 생성하세요.

### 프롬프트 1 (라이트 + 텍스트) ← 흰 배경 권장
```
App splash screen for a todo app named "TagDo". Minimal design. Center: blue checkmark icon with "TagDo" text below it. Pure white (#FFFFFF) or light gray (#F5F5F5) background. Small yellow accent near the icon. Clean typography, sans-serif font. Portrait 9:19.5. Everything on one image - icon and text together. IMPORTANT: background must be white or very light, NOT black.
```

### 프롬프트 2 (다크 + 텍스트)
```
Splash screen for "TagDo" app. Dark charcoal background (#1A1A1A). Centered: white checkmark icon, "TagDo" text below in white. Subtle yellow (#FFB300) accent. Minimal, premium feel. Single image with icon and text. Portrait 9:19.5.
```

### 프롬프트 3 (범용 + 텍스트)
```
Minimal splash screen. "TagDo" app name and blue checkmark icon centered. Soft neutral background. Clean, professional. Single combined image - logo and text "TagDo" together. Portrait smartphone format.
```

### 프롬프트 4 (로고만 - 배경색 분리)
```
Splash screen center asset only. Blue checkmark icon with "TagDo" text below. Transparent or white background. Minimal design. Will be placed on solid color background by flutter_native_splash. Square or portrait 1:1 ratio for center image.
```

---

## 참고 사항

| 항목 | 값 |
|------|-----|
| 앱명 | TagDo |
| 콘셉트 | 태그 기반 Todo, 마감일, 알람 |
| 프라이머리 | 파란색 #1976D2 |
| 액센트 | 노란색 #FFB300 (알람/마감) |
| 스타일 | Flat + Minimalism + Soft UI |

### 아이콘 규격
- iOS: 1024x1024 (App Store)
- Android: 512x512 이상 (adaptive icon용 foreground 추천)

### 스플래시 규격
- **전체 이미지**: 1242x2688 (iPhone) 또는 1080x1920 (Android) – 아이콘+텍스트 모두 포함
- **중앙 에셋만**: 512x512~1024x1024 – 배경색은 pubspec에서 별도 지정, 이미지엔 로고+TagDo 텍스트

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
