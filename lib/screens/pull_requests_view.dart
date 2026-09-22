import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/pull_request_model.dart';
import '../services/onedev_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

class PullRequestsView extends StatefulWidget {
  final OneDevService service;

  const PullRequestsView({super.key, required this.service});

  @override
  State<PullRequestsView> createState() => _PullRequestsViewState();
}

class _PullRequestsViewState extends State<PullRequestsView> {
  List<PullRequestModel> _pullRequests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPullRequests();
  }

  Future<void> _loadPullRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await widget.service.getPullRequests(count: 100);
      if (mounted) {
        setState(() {
          _pullRequests = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        icon: Icons.cloud_off_outlined,
        title: 'Error al cargar Pull Requests',
        message: _errorMessage!,
        buttonText: 'Reintentar',
        onAction: _loadPullRequests,
      );
    }

    if (_pullRequests.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.call_merge_outlined,
        title: 'Sin Pull Requests',
        message: 'No se encontraron solicitudes de cambio activas o archivadas en el servidor.',
        buttonText: 'Actualizar',
        onAction: _loadPullRequests,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPullRequests,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pullRequests.length,
        itemBuilder: (context, index) {
          final pr = _pullRequests[index];
          final dateStr = pr.submitDate != null
              ? DateFormat('dd/MM/yyyy').format(pr.submitDate!)
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(status: pr.status),
                      const SizedBox(width: 8),
                      Text(
                        '#${pr.number}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pr.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Branches flow container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.cardColorHigher,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fork_right, size: 14, color: AppTheme.primaryLight),
                        const SizedBox(width: 4),
                        Text(
                          pr.sourceBranch,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward, size: 12, color: context.textSecondaryColor),
                        ),
                        Text(
                          pr.targetBranch,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: context.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        pr.submitterName ?? 'Colaborador SCMDev',
                        style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
