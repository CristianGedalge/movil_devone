import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../services/onedev_service.dart';
import 'dashboard_view.dart';
import 'projects_view.dart';
import 'chat_view.dart';
import 'pull_requests_view.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final OneDevService _service = OneDevService();
  final Key _viewKey = UniqueKey();

  void _showUserProfile() {
    final config = AppConfig.instance;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    config.userDisplayName.isNotEmpty
                        ? config.userDisplayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  config.userDisplayName,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimaryColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${config.username.isNotEmpty ? config.username : "usuario"}',
                  style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Theme Mode Selector
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        context.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tema de la Aplicación',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            Text(
                              config.themeMode == ThemeMode.system
                                  ? 'Automático (según el sistema)'
                                  : (config.themeMode == ThemeMode.dark ? 'Modo Oscuro activado' : 'Modo Claro activado'),
                              style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 16),
                        label: Text('Claro', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 16),
                        label: Text('Oscuro', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 16),
                        label: Text('Auto', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {config.themeMode},
                    onSelectionChanged: (newSelection) async {
                      await config.setThemeMode(newSelection.first);
                      if (bottomSheetContext.mounted) {
                        Navigator.pop(bottomSheetContext);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppTheme.statusError),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: AppTheme.statusError, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    if (!mounted) return;
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Cerrar Sesión?'),
                        content: const Text('Tendrás que ingresar tus credenciales nuevamente para acceder.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusError),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Cerrar Sesión'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      await AppConfig.instance.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = AppConfig.instance.userDisplayName;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                height: 26,
                width: 26,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text('SCMDev'),
          ],
        ),
        actions: [
          // Quick theme toggle button
          IconButton(
            icon: Icon(
              context.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.isDarkMode ? AppTheme.primaryDark : AppTheme.primaryColor,
            ),
            tooltip: context.isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            onPressed: () => AppConfig.instance.toggleTheme(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _showUserProfile,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              onNavigateToChat: () => setState(() => _currentIndex = 2),
              onNavigateToPullRequests: () => setState(() => _currentIndex = 3),
            ),
            ProjectsView(service: _service),
            ChatView(service: _service),
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
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Chat IA',
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
