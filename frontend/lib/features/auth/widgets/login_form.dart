import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onToggle;
  final void Function(String, String) onLogin;


  const LoginForm({
    super.key,
    required this.onToggle,
    required this.onLogin,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),

          _input(
            "Usuário",
            controller: usernameController,
            hint: "seu_usuario",
          ),

          const SizedBox(height: 15),

          _input(
            "Senha",
            controller: passwordController,
            hint: "••••••••",
            obscure: !showPassword,
            suffix: IconButton(
              icon: Icon(
                showPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() => showPassword = !showPassword);
              },
            ),
          ),

          const SizedBox(height: 25),

          _button("Entrar", () {
            widget.onLogin(usernameController.text.trim(), passwordController.text);
          }),


          const SizedBox(height: 15),

          TextButton(
            onPressed: widget.onToggle,
            child: const Text("Não tem conta? Cadastrar"),
          ),
        ],
      ),
    );
  }

  Widget _input(
    String label, {
    required TextEditingController controller,
    bool obscure = false,
    String? hint,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.primaryBlue),
            ),
          ),
        ),
      ],
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