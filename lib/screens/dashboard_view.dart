import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../models/project_model.dart';
import '../models/issue_model.dart';
import '../models/pull_request_model.dart';
import '../services/onedev_service.dart';
import 'project_detail_screen.dart';

class DashboardView extends StatefulWidget {
  final OneDevService service;
  final VoidCallback onNavigateToProjects;
  final VoidCallback onNavigateToIssues;
  final VoidCallback onNavigateToPullRequests;

  const DashboardView({
    super.key,
    required this.service,
    required this.onNavigateToProjects,
    required this.onNavigateToIssues,
    required this.onNavigateToPullRequests,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  String? _syncError;
  List<ProjectModel> _recentProjects = [];
  int _totalIssues = 0;
  int _openIssues = 0;
  int _totalPulls = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _syncError = null;
    });

    try {
      final projects = await widget.service.getProjects(count: 5);

      List<IssueModel> issues = [];
      try {
        issues = await widget.service.getIssues(count: 50);
      } catch (_) {}

      List<PullRequestModel> pulls = [];
      try {
        pulls = await widget.service.getPullRequests(count: 50);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _recentProjects = projects;
          _totalIssues = issues.length;
          _openIssues = issues.where((i) => i.isOpen).length;
          _totalPulls = pulls.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Cargando tu información...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppTheme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeBanner(),
          if (_syncError != null) ...[
            const SizedBox(height: 14),
            _buildSyncErrorBanner(),
          ],
          const SizedBox(height: 16),
          _buildKpiMetricsGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'Tus Proyectos',
            actionText: 'Ver todos (${_recentProjects.length})',
            onTap: widget.onNavigateToProjects,
          ),
          const SizedBox(height: 10),
          _buildProjectsList(),
          const SizedBox(height: 20),
          _buildQuickShortcutsCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    final userName = AppConfig.instance.userDisplayName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Resumen de tus proyectos y actividad en DevOne',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppTheme.statusError, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _syncError ?? 'No se pudo sincronizar la información.',
              style: const TextStyle(fontSize: 12, color: AppTheme.statusError),
            ),
          ),
          TextButton(
            onPressed: _loadDashboardData,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Proyectos',
            count: '${_recentProjects.length}',
            icon: Icons.folder_special_outlined,
            color: AppTheme.primaryColor,
            onTap: widget.onNavigateToProjects,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Issues Abiertas',
            count: '$_openIssues',
            subtitle: 'de $_totalIssues totales',
            icon: Icons.bug_report_outlined,
            color: AppTheme.statusWarning,
            onTap: widget.onNavigateToIssues,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Pull Requests',
            count: '$_totalPulls',
            icon: Icons.call_merge_outlined,
            color: const Color(0xFF8B5CF6),
            onTap: widget.onNavigateToPullRequests,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsList() {
    if (_recentProjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.folder_open_outlined, color: context.textSecondaryColor, size: 36),
              const SizedBox(height: 10),
              Text(
                'No tienes proyectos asignados aún',
                style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Crea o únete a un proyecto en DevOne para verlo aquí',
                style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentProjects.map((project) {
        final dateStr = project.createDate != null
            ? DateFormat('dd/MM/yyyy').format(project.createDate!)
            : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.folder_outlined, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(
              project.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.description != null && project.description!.isNotEmpty)
                  Text(
                    project.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Ruta: ${project.displayPath} ${dateStr.isNotEmpty ? "• $dateStr" : ""}',
                  style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: context.textSecondaryColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailScreen(
                    project: project,
                    service: widget.service,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickShortcutsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColorHigher,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onNavigateToProjects,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Explorar Proyectos', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onNavigateToIssues,
              icon: const Icon(Icons.bug_report, size: 18),
              label: const Text('Ver Incidencias', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
