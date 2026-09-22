import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/project_model.dart';
import '../services/onedev_service.dart';
import '../widgets/empty_state.dart';
import 'project_detail_screen.dart';

class ProjectsView extends StatefulWidget {
  final OneDevService service;

  const ProjectsView({super.key, required this.service});

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  final TextEditingController _searchController = TextEditingController();
  List<ProjectModel> _projects = [];
  List<ProjectModel> _filteredProjects = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await widget.service.getProjects(count: 100);
      if (mounted) {
        setState(() {
          _projects = list;
          _applyFilter(_searchController.text);
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

  void _applyFilter(String query) {
    if (query.trim().isEmpty) {
      _filteredProjects = List.from(_projects);
    } else {
      final q = query.toLowerCase();
      _filteredProjects = _projects.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final descMatch = p.description?.toLowerCase().contains(q) ?? false;
        final pathMatch = p.path?.toLowerCase().contains(q) ?? false;
        return nameMatch || descMatch || pathMatch;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar proyectos por nombre...',
              prefixIcon: Icon(Icons.search, color: context.textSecondaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _applyFilter(''));
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() => _applyFilter(val));
            },
          ),
        ),

        // List / States
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        icon: Icons.cloud_off_outlined,
        title: 'Error de conexión',
        message: _errorMessage!,
        buttonText: 'Reintentar',
        onAction: _loadProjects,
      );
    }

    if (_filteredProjects.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.folder_open_outlined,
        title: _searchController.text.isNotEmpty
            ? 'Sin resultados'
            : 'No hay proyectos en SCMDev',
        message: _searchController.text.isNotEmpty
            ? 'No se encontraron proyectos con el término "${_searchController.text}".'
            : 'Crea un proyecto en el servidor web de SCMDev para verlo listado aquí.',
        buttonText: 'Actualizar',
        onAction: _loadProjects,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredProjects.length,
        itemBuilder: (context, index) {
          final project = _filteredProjects[index];
          final dateStr = project.createDate != null
              ? DateFormat('dd/MM/yyyy').format(project.createDate!)
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              Text(
                                project.displayPath,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondaryColor,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: context.textSecondaryColor),
                      ],
                    ),
                    if (project.description != null && project.description!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        project.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (project.codeManagement)
                          _buildFeatureChip(context, Icons.code, 'Git'),
                        if (project.issueManagement) ...[
                          const SizedBox(width: 6),
                          _buildFeatureChip(context, Icons.bug_report_outlined, 'Issues'),
                        ],
                        const Spacer(),
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.cardColorHigher,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.textSecondaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
