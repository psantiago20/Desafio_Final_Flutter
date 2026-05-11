import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_error_widget.dart';
import '../widgets/auth_header_widget.dart';
import '../../../core/theme/app_theme.dart';

class UnifiedAuthScreen extends ConsumerStatefulWidget {
  final bool isLogin;

  const UnifiedAuthScreen({
    super.key,
    this.isLogin = true,
  });

  @override
  ConsumerState<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends ConsumerState<UnifiedAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  // Formatters
  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );
  
  // State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _userRole = 'doctor'; // 'doctor' or 'patient'

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authProvider.notifier);
    bool success = false;

    if (widget.isLogin) {
      success = await authNotifier.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );
    } else {
      success = await authNotifier.register(
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        phone: _phoneFormatter.getUnmaskedText(),
        fullName: _nameCtrl.text.trim(),
        role: _userRole,
      );
    }

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user?.role == 'admin') {
        context.go('/management-v1');
      } else if (user?.role == 'doctor') {
        context.go('/dashboard');
      } else {
        context.go('/client');
      }
    }
  }

  void _togglePassword() => setState(() => _obscurePassword = !_obscurePassword);
  void _toggleConfirmPassword() => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Header
                AuthHeaderWidget(
                  title: widget.isLogin ? 'Bem-vindo de volta' : 'Criar conta',
                  subtitle: widget.isLogin
                      ? 'Acesse sua conta OmniConnect'
                      : 'Cadastre-se para começar',
                ),

                const SizedBox(height: 32),

                // Error Message
                if (auth.error != null)
                  AuthErrorWidget(
                    error: auth.error!,
                    onDismiss: () => ref.read(authProvider.notifier).clearError(),
                  ),

                // Registration Fields
                if (!widget.isLogin) ...[
                  AuthField(
                    controller: _nameCtrl,
                    label: 'Nome completo',
                    hint: 'João da Silva',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => v?.isEmpty ?? true ? 'Informe seu nome' : null,
                  ),
                  const SizedBox(height: 16),

                  AuthField(
                    controller: _emailCtrl,
                    label: 'E-mail',
                    hint: 'exemplo@email.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Informe o e-mail';
                      if (!v!.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  AuthField(
                    controller: _phoneCtrl,
                    label: 'WhatsApp',
                    hint: '(83) 99999-9999',
                    prefixIcon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneFormatter],
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Informe o WhatsApp';
                      if (!_phoneFormatter.isFill()) return 'Número incompleto';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de conta',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleOption('Médico', 'doctor'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleOption('Paciente', 'patient'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Common Fields
                AuthField(
                  controller: _usernameCtrl,
                  label: 'Nome de usuário',
                  hint: 'joao.silva',
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Informe o usuário';
                    if (v!.length < 3) return 'Mínimo 3 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AuthField(
                  controller: _passwordCtrl,
                  label: 'Senha',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textHint,
                    ),
                    onPressed: _togglePassword,
                  ),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Informe a senha';
                    if (v!.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),

                if (!widget.isLogin) ...[
                  const SizedBox(height: 16),
                  AuthField(
                    controller: _confirmCtrl,
                    label: 'Confirmar senha',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textHint,
                      ),
                      onPressed: _toggleConfirmPassword,
                    ),
                    validator: (v) {
                      if (v != _passwordCtrl.text) return 'Senhas não coincidem';
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // Submit Button
                AuthButton(
                  text: widget.isLogin ? 'Entrar' : 'Criar conta',
                  onPressed: _handleSubmit,
                  isLoading: auth.isLoading,
                ),

                const SizedBox(height: 24),

                // Toggle Auth Mode
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (widget.isLogin) {
                        context.go('/register');
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Text.rich(
                      TextSpan(
                        text: widget.isLogin ? 'Não tem conta? ' : 'Já tem conta? ',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: widget.isLogin ? 'Cadastre-se' : 'Entrar',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String label, String value) {
    final isSelected = _userRole == value;
    
    return GestureDetector(
      onTap: () => setState(() => _userRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
