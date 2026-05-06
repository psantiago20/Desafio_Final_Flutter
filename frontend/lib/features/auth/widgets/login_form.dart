import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class LoginForm extends StatelessWidget {
  final VoidCallback onToggle;
  final VoidCallback onLogin;

  const LoginForm({
    super.key,
    required this.onToggle,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 120),

          const SizedBox(height: 30),

          _input("Email"),
          const SizedBox(height: 15),
          _input("Senha", obscure: true),

          const SizedBox(height: 25),

          _button("Entrar", onLogin),

          const SizedBox(height: 15),

          TextButton(
            onPressed: onToggle,
            child: const Text("Não tem conta? Cadastre-se"),
          ),
        ],
      ),
    );
  }

  Widget _input(String hint, {bool obscure = false}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue),
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue, 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}