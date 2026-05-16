import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/widgets/auth_header.dart';
import 'package:frontend/features/auth/widgets/login_form.dart';
import 'package:frontend/features/auth/widgets/register_form.dart';
import 'package:frontend/features/auth/screens/otp_page.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool isLogin = true;

  void toggle() {
    setState(() => isLogin = !isLogin);
  }

  void goToOtp() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OtpPage()));
  }

  Future<void> _handleLogin(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }
    final ok = await ref.read(authProvider.notifier).login(username, password);
    if (ok && mounted) {
      // O GoRouter fará o redirecionamento automaticamente baseado no papel do usuário.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogin ? "Entrar" : "Criar conta",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLogin
                      ? "Acesse sua conta"
                      : "Preencha os dados para começar",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.alertRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.alertRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.alertRed,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        auth.error!,
                        style: const TextStyle(
                          color: AppTheme.alertRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isLogin
                  ? LoginForm(
                      key: const ValueKey('login'),
                      onToggle: toggle,
                      onLogin: _handleLogin,
                    )
                  : RegisterForm(
                      key: const ValueKey('register'),
                      onToggle: toggle,
                      onRegister: goToOtp,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
