// restore_option_card.dart
// 복구 다이얼로그 내 옵션 카드 위젯

import 'package:flutter/material.dart';
import 'package:habitcell/theme/app_colors.dart';

/// 복구 다이얼로그 옵션 카드
class RestoreOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final AppColorScheme palette;
  final bool isCancel;

  const RestoreOptionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.palette,
    this.isCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCancel ? palette.chipUnselectedBg : palette.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isCancel ? palette.textSecondary : palette.icon,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isCancel
                            ? palette.textSecondary
                            : palette.textPrimary,
                        fontSize: 15,
                        fontWeight:
                            isCancel ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: palette.textMeta,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.textMeta, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
