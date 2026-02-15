// email_registration_card.dart
// 이메일 등록/인증 카드 위젯 (백업 설정 화면에서 분리)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitcell/service/backup_service.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/common_util.dart';

/// 이메일 등록/인증 카드
///
/// [recoveryStatus] - 현재 복구 상태 (null이면 아직 로드 전)
/// [isLoadingStatus] - 상태 로딩 중 여부
/// [onStatusReloaded] - 상태 재로드 완료 콜백
class EmailRegistrationCard extends StatefulWidget {
  final RecoveryStatus? recoveryStatus;
  final bool isLoadingStatus;
  final VoidCallback onStatusReloaded;

  const EmailRegistrationCard({
    super.key,
    required this.recoveryStatus,
    required this.isLoadingStatus,
    required this.onStatusReloaded,
  });

  @override
  State<EmailRegistrationCard> createState() => _EmailRegistrationCardState();
}

class _EmailRegistrationCardState extends State<EmailRegistrationCard> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String? _emailForVerify;
  bool _codeSent = false;
  bool _isRequesting = false;
  bool _isVerifying = false;
  bool _isReRegistering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isEmailVerified =>
      widget.recoveryStatus?.emailVerified == true;

  // ─── 이메일 마스킹 ────────────────────────────────────────────
  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return '***@***';
    final local = parts[0];
    final domain = parts[1];
    if (local.isEmpty) return '***@$domain';
    if (local.length == 1) return '${local[0]}***@$domain';
    return '${local[0]}***${local[local.length - 1]}@$domain';
  }

  // ─── 이메일 개인정보 안내 다이얼로그 ──────────────────────────
  Future<void> _showEmailPrivacyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('emailPrivacyTitle'.tr()),
        content: Text('emailPrivacyNotice'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }

  // ─── 인증 코드 발송 ──────────────────────────────────────────
  Future<void> _onSendVerificationCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showOverlaySnackBar(context, message: 'emailRequired'.tr());
      return;
    }
    setState(() => _isRequesting = true);
    final result = await BackupService().requestEmailVerification(email);
    if (!mounted) return;
    setState(() => _isRequesting = false);
    if (result.success) {
      _emailForVerify = email;
      _codeSent = true;
      _codeController.clear();
      setState(() {});
      showOverlaySnackBar(context, message: 'verificationCodeSent'.tr());
    } else {
      showOverlaySnackBar(context,
          message: result.errorMessage ?? 'errorOccurred'.tr());
    }
  }

  // ─── 인증 코드 확인 ──────────────────────────────────────────
  Future<void> _onVerifyCode() async {
    final email = _emailForVerify ?? _emailController.text.trim();
    final code = _codeController.text.trim();
    if (email.isEmpty || code.length != 6) {
      showOverlaySnackBar(context,
          message: 'verificationCodePlaceholder'.tr());
      return;
    }
    setState(() => _isVerifying = true);
    final result = await BackupService().verifyEmailCode(email, code);
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (result.success) {
      _codeSent = false;
      _emailForVerify = null;
      _emailController.clear();
      _codeController.clear();
      _isReRegistering = false;
      widget.onStatusReloaded();
      showOverlaySnackBar(context, message: 'emailRegistered'.tr());
    } else {
      showOverlaySnackBar(context,
          message: result.errorMessage ?? 'errorOccurred'.tr());
    }
  }

  void _resetEmailFlow() {
    setState(() {
      _codeSent = false;
      _emailForVerify = null;
      _codeController.clear();
      _isReRegistering = false;
    });
  }

  void _startReRegister() {
    setState(() {
      _isReRegistering = true;
      _emailController.clear();
      _codeController.clear();
      _emailForVerify = null;
      _codeSent = false;
    });
  }

  // ─── build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ConfigUI.screenPaddingH,
        vertical: 8,
      ),
      child: Card(
        color: p.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(p),
              if (widget.isLoadingStatus)
                _buildLoadingIndicator(p)
              else if (_isEmailVerified && !_isReRegistering)
                _buildVerifiedRow(p)
              else
                _buildRegistrationForm(p),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 카드 헤더 ────────────────────────────────────────────────
  Widget _buildHeader(AppColorScheme p) {
    return Row(
      children: [
        Icon(Icons.email_outlined, color: p.icon, size: 20),
        const SizedBox(width: 8),
        Text(
          'emailRegistration'.tr(),
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.info_outline, color: p.textSecondary, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: _showEmailPrivacyDialog,
        ),
      ],
    );
  }

  // ─── 로딩 표시 ────────────────────────────────────────────────
  Widget _buildLoadingIndicator(AppColorScheme p) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.icon),
          ),
          const SizedBox(width: 8),
          Text('lastBackupNever'.tr(),
              style: TextStyle(color: p.textMeta, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── 인증 완료 상태 ──────────────────────────────────────────
  Widget _buildVerifiedRow(AppColorScheme p) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${'emailRegistered'.tr()}: ${_maskEmail(widget.recoveryStatus?.email ?? '')}',
              style: TextStyle(color: p.textSecondary, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: _startReRegister,
            child: Text('changeEmail'.tr()),
          ),
        ],
      ),
    );
  }

  // ─── 이메일 등록 폼 ──────────────────────────────────────────
  Widget _buildRegistrationForm(AppColorScheme p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isReRegistering)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'changeEmailHint'.tr(),
              style: TextStyle(color: p.textSecondary, fontSize: 13),
            ),
          )
        else
          const SizedBox(height: 12),
        if (!_isReRegistering) ...[
          Text(
            'emailRegistrationHint'.tr(),
            style: TextStyle(color: p.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailController,
          enabled: !_codeSent,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'emailPlaceholder'.tr(),
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: TextStyle(color: p.textPrimary, fontSize: 14),
        ),
        if (_codeSent) ...[
          const SizedBox(height: 12),
          Text(
            'verificationCodeLabel'.tr(),
            style: TextStyle(color: p.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'verificationCodePlaceholder'.tr(),
              border: const OutlineInputBorder(),
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: TextStyle(
                color: p.textPrimary, fontSize: 18, letterSpacing: 4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _isRequesting ? null : _resetEmailFlow,
                child: Text('cancel'.tr()),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isVerifying ? null : _onVerifyCode,
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('verify'.tr()),
              ),
            ],
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (_isReRegistering)
                  TextButton(
                    onPressed: () =>
                        setState(() => _isReRegistering = false),
                    child: Text('cancel'.tr()),
                  ),
                if (_isReRegistering) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _isRequesting ? null : _onSendVerificationCode,
                    child: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('sendVerificationCode'.tr()),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
