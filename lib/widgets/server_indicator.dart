import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/server_status.dart';

class ServerIndicator extends StatelessWidget {
  final ServerStatus? status;
  final VoidCallback onTap;

  const ServerIndicator({super.key, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOnline = status?.isOnline ?? false;
    final dotColor = isOnline ? AppTheme.statusSuccess : AppTheme.statusError;
    final label = isOnline ? 'OneDev Online' : 'OneDev Offline';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: dotColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dotColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: dotColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isOnline && status?.pingDuration != null) ...[
              const SizedBox(width: 4),
              Text(
                '(${status!.pingDuration!.inMilliseconds}ms)',
                style: TextStyle(
                  color: dotColor.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
