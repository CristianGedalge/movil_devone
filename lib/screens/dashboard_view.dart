import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../models/server_status.dart';
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
  final VoidCallback onOpenSettings;

  const DashboardView({
    super.key,
    required this.service,
    required this.onNavigateToProjects,
    required this.onNavigateToIssues,
    required this.onNavigateToPullRequests,
    required this.onOpenSettings,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  ServerStatus? _serverStatus;
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
    });

    try {
      final status = await widget.service.checkServerStatus();
      _serverStatus = status;

      if (status.isOnline) {
        final projectsFuture = widget.service.getProjects(count: 5);
        final issuesFuture = widget.service.getIssues(count: 50);
        final pullsFuture = widget.service.getPullRequests(count: 50);

        final results = await Future.wait([projectsFuture, issuesFuture, pullsFuture]);

        _recentProjects = results[0] as List<ProjectModel>;
        final issues = results[1] as List<IssueModel>;
        final pulls = results[2] as List<PullRequestModel>;

        _totalIssues = issues.length;
        _openIssues = issues.where((i) => i.isOpen).length;
        _totalPulls = pulls.length;
      }
    } catch (_) {
      // Status error is handled via _serverStatus
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
              'Conectando con el servidor OneDev...',
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
          _buildServerStatusBanner(),
          const SizedBox(height: 16),
          _buildKpiMetricsGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'Proyectos Recientes',
            actionText: 'Ver todos (${_recentProjects.length})',
            onTap: widget.onNavigateToProjects,
          ),
          const SizedBox(height: 10),
          _buildProjectsList(),
          const SizedBox(height: 24),
          _buildDevTipCard(),
        ],
      ),
    );
  }

  Widget _buildServerStatusBanner() {
    final isOnline = _serverStatus?.isOnline ?? false;
    final bannerBg = isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final borderColor = isOnline ? AppTheme.statusSuccess : AppTheme.statusError;
    final icon = isOnline ? Icons.check_circle : Icons.error_outline;
    final title = isOnline ? 'Servidor OneDev Conectado' : 'Servidor No Disponible';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: borderColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isOnline && _serverStatus?.version != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'v${_serverStatus!.version}',
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Host: ${AppConfig.instance.baseUrl}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
          if (!isOnline && _serverStatus?.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _serverStatus!.errorMessage!,
              style: const TextStyle(fontSize: 12, color: AppTheme.statusError),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: widget.onOpenSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Configurar IP en Ajustes', style: TextStyle(fontSize: 12)),
            ),
          ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
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
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Center(
          child: Text(
            'No se encontraron proyectos aún en el servidor OneDev.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.folder_outlined, color: AppTheme.primaryColor),
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
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Ruta: ${project.displayPath} ${dateStr.isNotEmpty ? "• $dateStr" : ""}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
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

  Widget _buildDevTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppTheme.primaryLight, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejo de Desarrollo:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Si estás en emulador Android usa la IP 10.0.2.2:6610. Si usas un dispositivo físico por Wi-Fi, ingresa la IP local de tu PC en la pestaña Ajustes.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
