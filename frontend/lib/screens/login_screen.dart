import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    _isRegisterMode
        ? await auth.register(
            _usernameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          )
        : await auth.login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
  }

  Future<void> _resendVerification() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      return;
    }
    await context.read<AuthProvider>().resendVerification(username);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 520,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: ListView(
            children: [
              const _BrandHero(),
              const SizedBox(height: 30),
              MatteCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Column(
                        key: ValueKey(_isRegisterMode),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRegisterMode
                                ? 'Crea tu cuenta'
                                : 'Qué bueno verte',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isRegisterMode
                                ? 'Empieza a convertir frases en memoria duradera.'
                                : 'Continúa donde dejaste tu práctica.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _isRegisterMode
                          ? Padding(
                              key: const ValueKey('email'),
                              padding: const EdgeInsets.only(top: 14),
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('no-email')),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onSubmitted: (_) => auth.isLoading ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: auth.errorMessage != null
                          ? StatusBanner(
                              key: ValueKey(auth.errorMessage),
                              message: auth.errorMessage!,
                              tone: StatusTone.error,
                            )
                          : auth.noticeMessage != null
                          ? StatusBanner(
                              key: ValueKey(auth.noticeMessage),
                              message: auth.noticeMessage!,
                              tone: StatusTone.success,
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (auth.errorMessage != null || auth.noticeMessage != null)
                      const SizedBox(height: 16),
                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: auth.isLoading
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isRegisterMode ? 'Crear cuenta' : 'Entrar',
                                key: const ValueKey('label'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => setState(
                              () => _isRegisterMode = !_isRegisterMode,
                            ),
                      child: Text(
                        _isRegisterMode
                            ? 'Ya tengo cuenta'
                            : 'Crear una cuenta nueva',
                      ),
                    ),
                    if (!_isRegisterMode)
                      TextButton(
                        onPressed: auth.isLoading ? null : _resendVerification,
                        child: const Text('Reenviar correo de verificación'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        children: [
          const AppIconContainer(
            icon: Icons.graphic_eq_rounded,
            size: 72,
            color: AppColors.teal,
          ),
          const SizedBox(height: 18),
          Text(
            'Native Etheria',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Escucha. Habla. Recuerda.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.teal, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
