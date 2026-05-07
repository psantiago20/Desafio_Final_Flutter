import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onToggle;
  final VoidCallback onRegister;

  const RegisterForm({
    super.key,
    required this.onToggle,
    required this.onRegister,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final birthController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;

  String userType = 'paciente';

  final phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      birthController.text =
          "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            const SizedBox(height: 40),

            _input(
              "Nome",
              controller: nameController,
              hint: "João da Silva",
              validator: (v) =>
                  v!.isEmpty ? "Informe seu nome" : null,
            ),

            const SizedBox(height: 15),

            _dateField(),

            const SizedBox(height: 20),

            Row(
              children: [
                _option("Paciente", "paciente"),
                const SizedBox(width: 10),
                _option("Médico", "medico"),
              ],
            ),

            const SizedBox(height: 20),

            _input(
              "Telefone",
              controller: phoneController,
              hint: "(83) 99999-9999",
              keyboard: TextInputType.phone,
              inputFormatters: [phoneMask],
              validator: (v) {
                if (v!.isEmpty) return "Informe o telefone";
                if (v.length < 15) return "Telefone incompleto";
                return null;
              },
            ),

            const SizedBox(height: 15),

            _input(
              "Email",
              controller: emailController,
              hint: "exemplo@email.com",
              keyboard: TextInputType.emailAddress,
              validator: (v) {
                if (v!.isEmpty) return "Informe o email";
                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) {
                  return "Email inválido";
                }
                return null;
              },
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
              validator: (v) {
                if (v!.length < 6) {
                  return "Mínimo 6 caracteres";
                }
                return null;
              },
            ),

            const SizedBox(height: 15),

            _input(
              "Confirmar senha",
              controller: confirmPasswordController,
              hint: "••••••••",
              obscure: !showConfirmPassword,
              suffix: IconButton(
                icon: Icon(
                  showConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() =>
                      showConfirmPassword = !showConfirmPassword);
                },
              ),
              validator: (v) {
                if (v != passwordController.text) {
                  return "Senhas não coincidem";
                }
                return null;
              },
            ),

            const SizedBox(height: 25),

            _button("Cadastrar", () {
              if (_formKey.currentState!.validate()) {
                widget.onRegister();
              }
            }),

            const SizedBox(height: 15),

            TextButton(
              onPressed: widget.onToggle,
              child: const Text("Já tem conta? Entrar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Data de nascimento",
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: birthController,
          readOnly: true,
          onTap: () => _selectDate(context),
          validator: (v) =>
              v!.isEmpty ? "Informe a data" : null,
          decoration: _decoration("Ex: 10/05/2000").copyWith(
            suffixIcon: const Icon(Icons.calendar_today),
          ),
        ),
      ],
    );
  }

  Widget _input(
    String label, {
    required TextEditingController controller,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: _decoration(hint).copyWith(
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryBlue),
      ),
    );
  }

  Widget _option(String label, String value) {
    final isSelected = userType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => userType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryBlue),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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