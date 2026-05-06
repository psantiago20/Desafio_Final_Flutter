import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/widgets/auth_header.dart';
import 'package:frontend/features/auth/widgets/login_form.dart';
import 'package:frontend/features/auth/widgets/register_form.dart';
import 'package:frontend/features/auth/pages/otp_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  void toggle() {
    setState(() => isLogin = !isLogin);
  }

  void goToOtp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OtpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith (
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

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLogin
                  ? LoginForm(
                      key: const ValueKey('login'),
                      onToggle: toggle,
                      onLogin: () {
                        // ação login
                      },
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