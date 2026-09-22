import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/issue_model.dart';
import '../widgets/status_badge.dart';

class IssueDetailScreen extends StatelessWidget {
  final IssueModel issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final dateStr = issue.submitDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(issue.submitDate!)
        : 'Desconocida';

    return Scaffold(
      appBar: AppBar(
        title: Text('Incidencia #${issue.number}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Info Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(status: issue.state),
                      const SizedBox(width: 10),
                      Text(
                        '#${issue.number}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (issue.projectId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.cardColorHigher,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Proyecto #${issue.projectId}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    issue.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: context.textSecondaryColor),
                      const SizedBox(width: 6),
                      Text(
                        issue.submitterName ?? 'Usuario SCMDev',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 15, color: context.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (issue.description != null && issue.description!.isNotEmpty)
                    Text(
                      issue.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textPrimaryColor,
                        height: 1.5,
                      ),
                    )
                  else
                    Text(
                      'Esta incidencia no cuenta con una descripción detallada.',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: context.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Activity / Comments count card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.mode_comment_outlined, color: AppTheme.primaryLight, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '${issue.commentCount} comentarios registrados',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
