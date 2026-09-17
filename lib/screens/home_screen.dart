import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/server_status.dart';
import '../services/onedev_service.dart';
import '../widgets/server_indicator.dart';
import 'dashboard_view.dart';
import 'projects_view.dart';
import 'issues_view.dart';
import 'pull_requests_view.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final OneDevService _service = OneDevService();
  ServerStatus? _serverStatus;

  // Key to force refresh views when config changes
  Key _viewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await _service.checkServerStatus();
    if (mounted) {
      setState(() {
        _serverStatus = status;
      });
    }
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          service: _service,
          onConfigChanged: () {
            setState(() {
              _viewKey = UniqueKey();
            });
            _checkStatus();
          },
        ),
      ),
    );
    _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hub, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('OneDev Móvil'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ServerIndicator(
              status: _serverStatus,
              onTap: _openSettings,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
            tooltip: 'Ajustes de Conexión',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: KeyedSubtree(
        key: _viewKey,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardView(
              service: _service,
              onNavigateToProjects: () => setState(() => _currentIndex = 1),
              onNavigateToIssues: () => setState(() => _currentIndex = 2),
              onNavigateToPullRequests: () => setState(() => _currentIndex = 3),
              onOpenSettings: _openSettings,
            ),
            ProjectsView(service: _service),
            IssuesView(service: _service),
            PullRequestsView(service: _service),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Proyectos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bug_report_outlined),
            selectedIcon: Icon(Icons.bug_report),
            label: 'Issues',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_merge_outlined),
            selectedIcon: Icon(Icons.call_merge),
            label: 'Pull Requests',
          ),
        ],
      ),
    );
  }
}
