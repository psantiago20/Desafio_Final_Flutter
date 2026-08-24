import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../providers/auth_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _obscurePassword = true;
  String _userType = 'patient'; // 'patient' or 'doctor'

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _birthCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          phone: _phoneFormatter.getUnmaskedText(),
          fullName: _nameCtrl.text.trim(),
          role: _userType,
        );
    if (ok && mounted) {
      // GoRouter will redirect automatically based on user role
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Criar sua\nconta.',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 34,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preencha os dados para começar',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),

                // Nome completo
                _buildField(
                  controller: _nameCtrl,
                  label: 'Nome completo',
                  hint: 'João da Silva',
                  icon: Icons.badge_outlined,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 14),

                // Nome de usuário
                _buildField(
                  controller: _usernameCtrl,
                  label: 'Nome de usuário',
                  hint: 'joaosilva123',
                  icon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o usuário';
                    if (v.length < 3) return 'Mínimo 3 caracteres';
                    if (v.contains(' ')) return 'Sem espaços';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Data de nascimento
                TextFormField(
                  controller: _birthCtrl,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: 'Data de nascimento',
                    hintText: 'Ex: 10/05/2000',
                    prefixIcon: const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textHint),
                    suffixIcon: const Icon(Icons.calendar_month_outlined,
                        color: AppColors.textHint),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe a data' : null,
                ),
                const SizedBox(height: 20),

                // Tipo de usuário
                Text(
                  'Tipo de conta',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTypeOption('Paciente', 'patient'),
                    const SizedBox(width: 10),
                    _buildTypeOption('Médico', 'doctor'),
                  ],
                ),
                const SizedBox(height: 20),

                // Telefone
                _buildField(
                  controller: _phoneCtrl,
                  label: 'WhatsApp (DDD + Número)',
                  hint: '(83) 99999-9999',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  formatters: [_phoneFormatter],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o WhatsApp';
                    if (!_phoneFormatter.isFill()) return 'Número incompleto';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // E-mail
                _buildField(
                  controller: _emailCtrl,
                  label: 'E-mail',
                  hint: 'exemplo@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o e-mail';
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Senha
                _buildField(
                  controller: _passwordCtrl,
                  label: 'Senha',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirmar senha
                _buildField(
                  controller: _confirmCtrl,
                  label: 'Confirmar senha',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) {
                    if (v != _passwordCtrl.text) return 'Senhas não coincidem';
                    return null;
                  },
                ),

                // Erro
                if (auth.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cancelled.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.cancelled.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.cancelled, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            auth.error!,
                            style: GoogleFonts.dmSans(
                                color: AppColors.cancelled, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Criar conta'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text.rich(
                      TextSpan(
                        text: 'Já tem conta? ',
                        style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Entrar',
                            style: GoogleFonts.dmSans(
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

  Widget _buildTypeOption(String label, String value) {
    final isSelected = _userType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _userType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.textHint) : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textHint,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }
}
