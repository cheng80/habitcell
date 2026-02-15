// app_locale.dart
// TagHandler 등 VM에서 locale 접근용 (EasyLocalization context 확보 전)

import 'package:flutter/material.dart';

/// 앱 루트에서 설정한 locale. TagHandler 기본 태그 생성 시 사용
Locale? appLocaleForInit;
