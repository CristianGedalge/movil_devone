import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../models/project_model.dart';
import '../services/onedev_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;
  final OneDevService service;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.service,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Map<String, String> _cloneUrls = {'http': '', 'ssh': ''};
  bool _isLoadingUrls = true;

  @override
  void initState() {
    super.initState();
    _loadCloneUrls();
  }

  Future<void> _loadCloneUrls() async {
    try {
      final urls = await widget.service.getCloneUrls(widget.project.id);
      if (mounted) {
        setState(() {
          _cloneUrls = urls;
          _isLoadingUrls = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingUrls = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final dateStr = project.createDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(project.createDate!)
        : 'Desconocida';

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.folder, color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'ID: #${project.id} ${project.key != null ? "• Clave: ${project.key}" : ""}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (project.description != null && project.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      project.description!,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Technical Details Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Repositorio',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(Icons.alt_route, 'Ruta del Proyecto', project.displayPath),
                  const Divider(height: 20),
                  _buildDetailRow(Icons.calendar_today, 'Fecha de Creación', dateStr),
                  const Divider(height: 20),
                  _buildDetailRow(
                    Icons.code,
                    'Gestión de Código',
                    project.codeManagement ? 'Habilitada' : 'Deshabilitada',
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    Icons.bug_report,
                    'Gestión de Incidencias',
                    project.issueManagement ? 'Habilitada' : 'Deshabilitada',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Clone URLs Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terminal, color: AppTheme.primaryLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Comandos de Clonación Git',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingUrls)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    if (_cloneUrls['http']?.isNotEmpty == true)
                      _buildCloneUrlBlock('HTTP', _cloneUrls['http']!),
                    if (_cloneUrls['ssh']?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      _buildCloneUrlBlock('SSH', _cloneUrls['ssh']!),
                    ],
                    if (_cloneUrls['http']?.isEmpty == true && _cloneUrls['ssh']?.isEmpty == true)
                      Text(
                        'git clone ${AppConfig.instance.baseUrl.replaceAll('/~api', '')}/${project.displayPath}.git',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloneUrlBlock(String protocol, String url) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              protocol,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: AppTheme.primaryLight),
            onPressed: () => _copyToClipboard(url, 'Enlace Git $protocol'),
            tooltip: 'Copiar enlace',
          ),
        ],
      ),
    );
  }
}
