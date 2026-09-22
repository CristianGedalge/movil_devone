import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/onedev_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final OneDevService? service;

  const LoginScreen({super.key, this.service});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final OneDevService _service;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? OneDevService();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _service.loginWithCredentials(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundDark,
            body: SafeArea(
              child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: context.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.25 : 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 60,
                            width: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SCMDev Móvil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inicia sesión con tu cuenta para acceder a tus proyectos y repositorios',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error Message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.statusError, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.statusError,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario o correo',
                        hintText: 'ej. admin o dev@correo.com',
                        prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Ingresa tu usuario o correo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: context.textSecondaryColor,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  },
),
    );
  }
}
