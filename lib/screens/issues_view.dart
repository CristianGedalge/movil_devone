import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/issue_model.dart';
import '../models/project_model.dart';
import '../services/onedev_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import 'issue_detail_screen.dart';

class IssuesView extends StatefulWidget {
  final OneDevService service;

  const IssuesView({super.key, required this.service});

  @override
  State<IssuesView> createState() => _IssuesViewState();
}

class _IssuesViewState extends State<IssuesView> {
  List<IssueModel> _issues = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'ALL'; // 'ALL', 'OPEN', 'CLOSED'

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? query;
      if (_selectedFilter == 'OPEN') {
        query = '"State" is "Open"';
      } else if (_selectedFilter == 'CLOSED') {
        query = '"State" is "Closed"';
      }

      final list = await widget.service.getIssues(query: query, count: 100);
      if (mounted) {
        setState(() {
          _issues = list;
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

  void _showCreateIssueModal() async {
    List<ProjectModel> projects = [];
    try {
      projects = await widget.service.getProjects(count: 50);
    } catch (_) {}

    if (!mounted) return;

    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay proyectos disponibles para asociar la incidencia.'),
          backgroundColor: AppTheme.statusWarning,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    int selectedProjectId = projects.first.id;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_task, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Nueva Incidencia',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: selectedProjectId,
                  decoration: const InputDecoration(labelText: 'Proyecto Destino'),
                  items: projects.map((p) {
                    return DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedProjectId = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título de la incidencia *',
                    hintText: 'Ej. Corregir error en autenticación',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Detalles sobre el problema detectado...',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ingresa un título')),
                              );
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);

                            setModalState(() => isSubmitting = true);
                            try {
                              await widget.service.createIssue(
                                projectId: selectedProjectId,
                                title: title,
                                description: descController.text.trim(),
                              );
                              navigator.pop();
                              _loadIssues();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Incidencia creada con éxito'),
                                  backgroundColor: AppTheme.statusSuccess,
                                ),
                              );
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error al crear incidencia: $e'),
                                  backgroundColor: AppTheme.statusError,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Crear Incidencia'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('Todas', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('Abiertas', 'OPEN'),
                const SizedBox(width: 8),
                _buildFilterChip('Cerradas', 'CLOSED'),
              ],
            ),
          ),

          // Issues list
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateIssueModal,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Incidencia', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && _selectedFilter != value) {
          setState(() {
            _selectedFilter = value;
          });
          _loadIssues();
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? (context.isDarkMode ? AppTheme.backgroundDark : Colors.white) : context.textPrimaryColor,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        icon: Icons.cloud_off_outlined,
        title: 'Error de conexión',
        message: _errorMessage!,
        buttonText: 'Reintentar',
        onAction: _loadIssues,
      );
    }

    if (_issues.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Sin incidencias',
        message: _selectedFilter == 'ALL'
            ? 'No hay incidencias registradas en el servidor SCMDev.'
            : 'No hay incidencias con el filtro seleccionado.',
        buttonText: 'Actualizar',
        onAction: _loadIssues,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIssues,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _issues.length,
        itemBuilder: (context, index) {
          final issue = _issues[index];
          final dateStr = issue.submitDate != null
              ? DateFormat('dd/MM/yyyy').format(issue.submitDate!)
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IssueDetailScreen(issue: issue),
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
                        StatusBadge(status: issue.state),
                        const SizedBox(width: 8),
                        Text(
                          '#${issue.number}',
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
                      issue.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (issue.description != null && issue.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        issue.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: context.textSecondaryColor),
                        const SizedBox(width: 4),
                        Text(
                          issue.submitterName ?? 'Usuario',
                          style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                        ),
                        if (issue.commentCount > 0) ...[
                          const SizedBox(width: 14),
                          Icon(Icons.mode_comment_outlined, size: 13, color: context.textSecondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            '${issue.commentCount}',
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                          ),
                        ],
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
}
