// backup_service.dart
// 백업/복구 API 연동
//
// [payload] schema_version, device_uuid, exported_at, settings, categories, habits, logs, heatmap_snapshots

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:habitcell/util/app_storage.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/util/date_util.dart';
import 'package:habitcell/vm/habit_database_handler.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final HabitDatabaseHandler _handler = HabitDatabaseHandler();

  /// 스냅샷 payload 생성
  Future<Map<String, dynamic>> buildPayload() async {
    final today = dateToday();
    final startDate = addDays(today, -730); // 2년

    final categories =
        (await _handler.getAllCategories()).map((c) => c.toMap()).toList();
    final habits = (await _handler.getAllHabitsIncludingDeleted())
        .map((h) => h.toMap())
        .toList();
    final logs = (await _handler.getLogsInDateRange(startDate, today))
        .map((l) => l.toMap())
        .toList();
    final heatmapRows =
        await _handler.getHeatmapSnapshots(startDate, today);
    final heatmapSnapshots = heatmapRows
        .map((r) => {
              'date': r['date'],
              'achieved': r['achieved'],
              'total': r['total'],
              'level': r['level'],
            })
        .toList();

    return {
      'schema_version': 1,
      'device_uuid': await AppStorage.ensureDeviceUuid(),
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'categories': categories,
      'habits': habits,
      'logs': logs,
      'heatmap_snapshots': heatmapSnapshots,
    };
  }

  /// 수동 백업 실행
  /// 성공 시 last_backup_at 저장, is_dirty 클리어(추후)
  /// [trigger] 백업 트리거 구분용 (디버깅)
  Future<BackupResult> backup({String? trigger}) async {
    debugPrint('[BackupService] ★ 백업 트리거: ${trigger ?? 'unknown'}');
    await AppStorage.saveLastBackupAttemptAt(DateTime.now());

    try {
      debugPrint('[BackupService] payload 생성 중...');
      final payload = await buildPayload();
      final base = getApiBaseUrl();
      final uri = Uri.parse('$base/v1/backups');
      debugPrint('[BackupService] POST $uri');
      debugPrint('[BackupService] device_uuid: ${payload['device_uuid']}');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[BackupService] HTTP ${response.statusCode} ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await AppStorage.saveLastBackupAt(DateTime.now());
        debugPrint('[BackupService] 백업 성공');
        return BackupResult.success();
      }
      debugPrint('[BackupService] 백업 실패: HTTP ${response.statusCode}');
      return BackupResult.failure(
          'HTTP ${response.statusCode}: ${response.body}');
    } catch (e, st) {
      debugPrint('[BackupService] backup error: $e\n$st');
      return BackupResult.failure(e.toString());
    }
  }

  /// 최신 백업 조회
  /// 1) 같은 기기: GET /v1/backups/latest?device_uuid=...
  /// 2) 다른 기기: 404 시 GET /v1/recovery/backup?device_uuid=... (이메일 인증 필요)
  /// 성공 시 payload 반환, 실패 시 null. [errorHint] 403 시 'email_required'
  Future<FetchBackupResult> fetchLatestBackup() async {
    try {
      final deviceUuid = await AppStorage.ensureDeviceUuid();
      final base = getApiBaseUrl();

      // 1) 같은 기기 백업 시도
      final latestUri = Uri.parse('$base/v1/backups/latest')
          .replace(queryParameters: {'device_uuid': deviceUuid});
      debugPrint('[BackupService] fetchLatestBackup: GET $latestUri');
      var response = await http.get(latestUri).timeout(const Duration(seconds: 30));
      debugPrint('[BackupService] fetchLatestBackup: HTTP ${response.statusCode}');

      // 2) 404면 다른 기기 복구 시도 (이메일로 조회)
      if (response.statusCode == 404) {
        debugPrint('[BackupService] fetchLatestBackup: 같은 기기 백업 없음 → 다른 기기(이메일) 조회 시도');
        final recoveryUri = Uri.parse('$base/v1/recovery/backup')
            .replace(queryParameters: {'device_uuid': deviceUuid});
        response = await http.get(recoveryUri).timeout(const Duration(seconds: 30));
        debugPrint('[BackupService] fetchLatestBackup (recovery): HTTP ${response.statusCode}');
      }

      if (response.statusCode == 404) {
        debugPrint('[BackupService] fetchLatestBackup: 백업 없음');
        return FetchBackupResult(payload: null);
      }
      if (response.statusCode == 403) {
        debugPrint('[BackupService] fetchLatestBackup: 이메일 인증 필요 (다른 기기 복구)');
        return FetchBackupResult(payload: null, errorHint: 'email_required');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[BackupService] fetchLatestBackup fail: ${response.body}');
        return FetchBackupResult(payload: null);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = json['payload'] as Map<String, dynamic>?;
      if (payload != null) {
        final habits = (payload['habits'] as List?)?.length ?? 0;
        final exportedAt = payload['exported_at'] as String? ?? '?';
        debugPrint('[BackupService] fetchLatestBackup: 복구할 백업 발견 - exported_at=$exportedAt, 습관 ${habits}개');
      } else {
        debugPrint('[BackupService] fetchLatestBackup: payload가 null');
      }
      return FetchBackupResult(payload: payload);
    } catch (e, st) {
      debugPrint('[BackupService] fetchLatestBackup error: $e\n$st');
      return FetchBackupResult(payload: null);
    }
  }

  /// 복구용 이메일 인증 상태 조회 (GET /v1/recovery/status)
  Future<RecoveryStatus> fetchRecoveryStatus() async {
    try {
      final deviceUuid = await AppStorage.ensureDeviceUuid();
      final base = getApiBaseUrl();
      final uri = Uri.parse('$base/v1/recovery/status')
          .replace(queryParameters: {'device_uuid': deviceUuid});
      debugPrint('[BackupService] GET $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      debugPrint('[BackupService] recovery status HTTP ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return RecoveryStatus(emailVerified: false, email: null, hasBackup: false, lastBackupAt: null);
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RecoveryStatus(
        emailVerified: json['email_verified'] as bool? ?? false,
        email: json['email'] as String?,
        hasBackup: json['has_backup'] as bool? ?? false,
        lastBackupAt: json['last_backup_at'] as String?,
      );
    } catch (e, st) {
      debugPrint('[BackupService] fetchRecoveryStatus error: $e\n$st');
      return RecoveryStatus(emailVerified: false, email: null, hasBackup: false, lastBackupAt: null);
    }
  }

  /// 이메일 인증 코드 요청 (POST /v1/recovery/email/request)
  Future<RecoveryResult> requestEmailVerification(String email) async {
    try {
      final deviceUuid = await AppStorage.ensureDeviceUuid();
      final base = getApiBaseUrl();
      final uri = Uri.parse('$base/v1/recovery/email/request');
      debugPrint('[BackupService] POST $uri');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'device_uuid': deviceUuid, 'email': email.trim().toLowerCase()}),
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('[BackupService] request verification HTTP ${response.statusCode} ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return RecoveryResult.success();
      }
      final body = response.body;
      String msg = 'HTTP ${response.statusCode}';
      try {
        final j = jsonDecode(body) as Map<String, dynamic>;
        if (j['detail'] != null) msg = j['detail'] as String;
      } catch (_) {}
      return RecoveryResult.failure(msg);
    } catch (e, st) {
      debugPrint('[BackupService] requestEmailVerification error: $e\n$st');
      return RecoveryResult.failure(e.toString());
    }
  }

  /// 이메일 인증 코드 검증 (POST /v1/recovery/email/verify)
  Future<RecoveryResult> verifyEmailCode(String email, String code) async {
    try {
      final deviceUuid = await AppStorage.ensureDeviceUuid();
      final base = getApiBaseUrl();
      final uri = Uri.parse('$base/v1/recovery/email/verify');
      debugPrint('[BackupService] POST $uri');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device_uuid': deviceUuid,
              'email': email.trim().toLowerCase(),
              'code': code.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      debugPrint('[BackupService] verify HTTP ${response.statusCode} ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return RecoveryResult.success();
      }
      final body = response.body;
      String msg = 'HTTP ${response.statusCode}';
      try {
        final j = jsonDecode(body) as Map<String, dynamic>;
        if (j['detail'] != null) msg = j['detail'] as String;
      } catch (_) {}
      return RecoveryResult.failure(msg);
    } catch (e, st) {
      debugPrint('[BackupService] verifyEmailCode error: $e\n$st');
      return RecoveryResult.failure(e.toString());
    }
  }

  /// payload로 SQLite 복구
  Future<RestoreResult> restore(Map<String, dynamic> payload) async {
    try {
      final habits = (payload['habits'] as List?)?.length ?? 0;
      final categories = (payload['categories'] as List?)?.length ?? 0;
      final logs = (payload['logs'] as List?)?.length ?? 0;
      debugPrint('[BackupService] restore: 복구 시작 - categories=$categories, habits=$habits, logs=$logs');
      await _handler.restoreFromPayload(payload);
      debugPrint('[BackupService] restore: 복구 완료 성공');
      return RestoreResult.success();
    } catch (e, st) {
      debugPrint('[BackupService] restore error: $e\n$st');
      return RestoreResult.failure(e.toString());
    }
  }

  /// 자동 백업 (조건 충족 시에만 실행, 실패 시 조용히 스킵)
  /// - auto_backup_enabled ON
  /// - [fromBackground] true: 쿨다운 무시 (백그라운드 전환 시마다 백업)
  /// - [fromBackground] false: 쿨다운 적용 (인앱 액션 연속 시 스팸 방지)
  /// - [trigger] 백업 트리거 구분용 (디버깅)
  Future<void> autoBackupIfNeeded({bool fromBackground = false, String? trigger}) async {
    if (!AppStorage.getAutoBackupEnabled()) return;
    if (!fromBackground) {
      final lastAt = AppStorage.getLastBackupAttemptAt();
      if (lastAt != null) {
        try {
          final last = DateTime.parse(lastAt);
          final cooldown = Duration(minutes: AppStorage.getCooldownMinutes());
          if (DateTime.now().difference(last) < cooldown) return;
        } catch (_) {}
      }
    }
    try {
      final result = await backup(trigger: trigger ?? (fromBackground ? 'auto_background' : 'auto_in_app'));
      if (!result.success) {
        debugPrint('[BackupService] 자동 백업 실패(스킵): ${result.errorMessage}');
      }
    } catch (_) {}
  }
}

class BackupResult {
  final bool success;
  final String? errorMessage;
  const BackupResult._({required this.success, this.errorMessage});

  factory BackupResult.success() => const BackupResult._(success: true);
  factory BackupResult.failure(String message) =>
      BackupResult._(success: false, errorMessage: message);
}

class RestoreResult {
  final bool success;
  final String? errorMessage;
  const RestoreResult._({required this.success, this.errorMessage});

  factory RestoreResult.success() => const RestoreResult._(success: true);
  factory RestoreResult.failure(String message) =>
      RestoreResult._(success: false, errorMessage: message);
}

/// 복구용 이메일 인증 상태
/// 백업 조회 결과 (같은 기기 + 다른 기기)
class FetchBackupResult {
  final Map<String, dynamic>? payload;
  final String? errorHint; // 'email_required' 등
  const FetchBackupResult({this.payload, this.errorHint});
}

class RecoveryStatus {
  final bool emailVerified;
  final String? email;
  /// 서버에 저장된 백업 존재 여부
  final bool hasBackup;
  /// 마지막 백업 시각 (ISO8601, null이면 없음)
  final String? lastBackupAt;
  const RecoveryStatus({
    required this.emailVerified,
    this.email,
    this.hasBackup = false,
    this.lastBackupAt,
  });
}

/// 복구 API 결과 (request/verify)
class RecoveryResult {
  final bool success;
  final String? errorMessage;
  const RecoveryResult._({required this.success, this.errorMessage});

  factory RecoveryResult.success() => const RecoveryResult._(success: true);
  factory RecoveryResult.failure(String message) =>
      RecoveryResult._(success: false, errorMessage: message);
}
