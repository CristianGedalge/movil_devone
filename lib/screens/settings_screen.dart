import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../models/server_status.dart';
import '../services/onedev_service.dart';

class SettingsScreen extends StatefulWidget {
  final OneDevService service;
  final VoidCallback onConfigChanged;

  const SettingsScreen({
    super.key,
    required this.service,
    required this.onConfigChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  late TextEditingController _tokenController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late AuthType _authType;

  bool _isTesting = false;
  ServerStatus? _testResult;

  @override
  void initState() {
    super.initState();
    final config = AppConfig.instance;
    _urlController = TextEditingController(text: config.baseUrl);
    _tokenController = TextEditingController(text: config.token);
    _usernameController = TextEditingController(text: config.username);
    _passwordController = TextEditingController(text: config.password);
    _authType = config.authType;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    // Save temporarily to memory to test with entered values
    final currentUrl = _urlController.text.trim();
    await AppConfig.instance.updateConfig(
      newBaseUrl: currentUrl,
      newAuthType: _authType,
      newToken: _tokenController.text.trim(),
      newUsername: _usernameController.text.trim(),
      newPassword: _passwordController.text,
    );

    final status = await widget.service.checkServerStatus();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = status;
      });

      if (status.isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Conexión exitosa con OneDev v${status.version}!'),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    await AppConfig.instance.updateConfig(
      newBaseUrl: _urlController.text.trim(),
      newAuthType: _authType,
      newToken: _tokenController.text.trim(),
      newUsername: _usernameController.text.trim(),
      newPassword: _passwordController.text,
    );

    widget.onConfigChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada correctamente.'),
          backgroundColor: AppTheme.statusSuccess,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Conexión'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildExplanationCard(),
            const SizedBox(height: 16),

            // Base URL Section
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dirección del Servidor OneDev',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL de la API OneDev',
                        hintText: 'http://10.0.2.2:6610/~api',
                        prefixIcon: Icon(Icons.link, color: AppTheme.primaryColor),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Ingresa la URL del servidor';
                        }
                        if (!val.startsWith('http://') && !val.startsWith('https://')) {
                          return 'Debe iniciar con http:// o https://';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Presets rápidos de entorno:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.phone_android, size: 16),
                          label: const Text('Emulador Android (10.0.2.2)'),
                          onPressed: () {
                            setState(() {
                              _urlController.text = AppConfig.defaultEmulatorUrl;
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.computer, size: 16),
                          label: const Text('Localhost PC (127.0.0.1)'),
                          onPressed: () {
                            setState(() {
                              _urlController.text = AppConfig.defaultLocalhostUrl;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Authentication Section
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Autenticación (Opcional)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Si tu OneDev tiene proyectos públicos, puedes usar modo "Ninguna".',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AuthType>(
                      initialValue: _authType,
                      decoration: const InputDecoration(labelText: 'Tipo de Autenticación'),
                      items: const [
                        DropdownMenuItem(
                          value: AuthType.none,
                          child: Text('Ninguna (Acceso anónimo / público)'),
                        ),
                        DropdownMenuItem(
                          value: AuthType.bearer,
                          child: Text('Bearer Token (Personal Access Token)'),
                        ),
                        DropdownMenuItem(
                          value: AuthType.basic,
                          child: Text('Basic Auth (Usuario y Contraseña)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _authType = val);
                      },
                    ),
                    if (_authType == AuthType.bearer) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Access Token',
                          hintText: 'Pega aquí tu token de OneDev',
                          prefixIcon: Icon(Icons.key, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                    if (_authType == AuthType.basic) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Result Banner
            if (_testResult != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _testResult!.isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _testResult!.isOnline ? AppTheme.statusSuccess : AppTheme.statusError,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _testResult!.isOnline ? Icons.check_circle : Icons.error,
                          color: _testResult!.isOnline ? AppTheme.statusSuccess : AppTheme.statusError,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _testResult!.isOnline
                              ? 'Conexión Exitosa (OneDev v${_testResult!.version})'
                              : 'Conexión Fallida',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _testResult!.isOnline ? AppTheme.statusSuccess : AppTheme.statusError,
                          ),
                        ),
                      ],
                    ),
                    if (_testResult!.isOnline && _testResult!.pingDuration != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tiempo de respuesta: ${_testResult!.pingDuration!.inMilliseconds} ms',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                    if (!_testResult!.isOnline && _testResult!.errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _testResult!.errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.statusError),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check),
                    label: const Text('Probar Conexión'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryLight, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'En desarrollo móvil Android, "localhost" se refiere al teléfono. Para conectarte al OneDev de tu PC usa 10.0.2.2 en emulador o la IP local (192.168.x.x) en celular físico.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
