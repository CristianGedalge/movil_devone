import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    IconData icon;

    final normalized = status.toUpperCase();

    switch (normalized) {
      case 'OPEN':
        bg = AppTheme.statusSuccess.withValues(alpha: 0.12);
        text = AppTheme.statusSuccess;
        icon = Icons.radio_button_checked;
        break;
      case 'CLOSED':
        bg = AppTheme.textSecondary.withValues(alpha: 0.15);
        text = AppTheme.textSecondary;
        icon = Icons.check_circle_outline;
        break;
      case 'MERGED':
        bg = const Color(0xFF8B5CF6).withValues(alpha: 0.12); // Purple
        text = const Color(0xFF8B5CF6);
        icon = Icons.merge_type;
        break;
      case 'DISCARDED':
        bg = AppTheme.statusError.withValues(alpha: 0.12);
        text = AppTheme.statusError;
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = AppTheme.accentColor.withValues(alpha: 0.12);
        text = AppTheme.accentColor;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
