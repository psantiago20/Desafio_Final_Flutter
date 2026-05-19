import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _specialtiesKey = GlobalKey();
  final GlobalKey _techKey = GlobalKey();
  final GlobalKey _teamKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  void _showLoginModal() {
    ref.read(authProvider.notifier).clearError();
    showDialog(
      context: context,
      builder: (context) => LoginModal(onShowRegister: _showRegisterModal),
    );
  }


  void _showRegisterModal() {
    ref.read(authProvider.notifier).clearError();
    showDialog(
      context: context,
      builder: (context) => const RegisterModal(),
    );
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF003D9B);
    const Color secondaryColor = Color(0xFF006C4D);
    const Color backgroundColor = Color(0xFFF7F9FB);
    const Color onSurfaceVariantColor = Color(0xFF434654);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Conteúdo principal (Scrollable)
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 70), // Espaço para o AppBar fixo

                // 1. Hero Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 900;
                          return Flex(
                            direction: isMobile ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: isMobile ? 0 : 1,
                                child: Column(
                                  crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF86F8C8),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified, size: 16, color: secondaryColor),
                                          SizedBox(width: 8),
                                          Text(
                                            'EXCELÊNCIA EM SAÚDE DIGITAL',
                                            style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      'Sua saúde em um santuário de cuidado',
                                      textAlign: isMobile ? TextAlign.center : TextAlign.start,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800,
                                        color: primaryColor,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Experiência clínica de alto nível onde a tecnologia de ponta encontra o toque humano, criando um ambiente de cura acolhedor e eficiente.',
                                      textAlign: isMobile ? TextAlign.center : TextAlign.start,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: onSurfaceVariantColor,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    Wrap(
                                      alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: [
                                        ElevatedButton(
                                          onPressed: _showLoginModal,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 4,
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('Agendar Consulta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              SizedBox(width: 8),
                                              Icon(Icons.calendar_month, size: 20),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => _scrollTo(_specialtiesKey),
                                          style: TextButton.styleFrom(
                                            backgroundColor: const Color(0xFFECEEF0),
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                            foregroundColor: primaryColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: const Text('Conhecer Especialidades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!isMobile) const SizedBox(width: 48),
                              if (isMobile) const SizedBox(height: 48),
                              Expanded(
                                flex: isMobile ? 0 : 1,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(48),
                                  child: Image.network(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuC2LnXeNAl3zV5WStq2H_BIYOkeyEL59BY7nILJsG7h_tSpddL0IXK_k1QH1ZZT9wh0jgjaVMJ-yoJDeDsSpKV7k4OfxW4z_nUmywc7GggyADW5tXPKJNuHKZf9cH8ZPYbnDoI85AcFatxCl2igKXaIjah563_FD-_NyUfYVVMd3mMAJIydDdvC_YXIHae0AZ5py4Yb9v6cyK6ZTqmI6iSC6zfwHWzLBSUqVHF3WUuifU7ksqKoHFFbePbyty36oz4eJWwmHybvMz4',
                                    fit: BoxFit.cover,
                                    height: isMobile ? 350 : 500,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // 2. Especialidades
                Container(
                  key: _specialtiesKey,
                  width: double.infinity,
                  color: const Color(0xFFF2F4F6),
                  padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nossas Especialidades',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Cuidado especializado em cada batimento, pensamento e fase da vida.',
                                  style: TextStyle(fontSize: 18, color: onSurfaceVariantColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Wrap(
                                spacing: 24,
                                runSpacing: 24,
                                children: [
                                  _buildSpecialtyCard(
                                    icon: Icons.medical_services,
                                    title: 'Clínica Geral',
                                    description: 'Atendimento humanizado e foco em prevenção para cuidar da sua saúde de forma integral.',
                                    color: const Color(0xFFDAE2FF),
                                    iconColor: primaryColor,
                                    width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  ),
                                  _buildSpecialtyCard(
                                    icon: Icons.favorite,
                                    title: 'Cardiologia',
                                    description: 'Especialista em arritmias e saúde do coração com monitoramento avançado.',
                                    color: const Color(0xFF86F8C8),
                                    iconColor: secondaryColor,
                                    width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  ),
                                  _buildSpecialtyCard(
                                    icon: Icons.psychology,
                                    title: 'Neurologia',
                                    description: 'Diagnóstico preciso e tratamentos inovadores para o sistema nervoso.',
                                    color: const Color(0xFFFFDBCF),
                                    iconColor: const Color(0xFF7B2600),
                                    width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Tecnologia
                Container(
                  key: _techKey,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 900;
                          return Flex(
                            direction: isMobile ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: isMobile ? 0 : 7,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Image.network(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuD8lh7R6HqLpvmHj_q6uucd-96-0tDyUTW4rY4pR2X1mr_-bUrE5ijMEoGCr6MYvaRxVh6Io6c_2ZQssuS6SJ9DUhL8WHiuGU5U6V0PzVt8rV6DUtzaQ_tm-A33J34FJYRbUL_1JJzCabVoeAmA7W-9dnSK3fq9o7oEN1nflzATOo5o8O6vhV-tQKQnz8OIjN8R8_Bg-uzYqcDgOxauZYrmg6lQ-hLaH_vqYVRcft1zuK1ozsZE5u-m6cuXO1-a8TMghODSCKCy8F0',
                                    fit: BoxFit.cover,
                                    height: isMobile ? 300 : 400,
                                  ),
                                ),
                              ),
                              if (!isMobile) const SizedBox(width: 64),
                              if (isMobile) const SizedBox(height: 48),
                              Expanded(
                                flex: isMobile ? 0 : 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tecnologia a seu favor',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        color: primaryColor,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    _buildTechItem(
                                      icon: Icons.smart_toy,
                                      title: 'Agendamento por IA',
                                      description: 'Nossa inteligência artificial otimiza horários para garantir o menor tempo de espera possível.',
                                    ),
                                    const SizedBox(height: 24),
                                    _buildTechItem(
                                      icon: Icons.chat,
                                      title: 'Integração WhatsApp',
                                      description: 'Receba lembretes, resultados de exames e suporte diretamente no seu aplicativo de mensagens.',
                                    ),
                                    const SizedBox(height: 24),
                                    _buildTechItem(
                                      icon: Icons.description,
                                      title: 'Prontuário Digital',
                                      description: 'Acesse seu histórico médico completo em um ambiente seguro e criptografado a qualquer momento.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // 4. Corpo Clínico
                Container(
                  key: _teamKey,
                  width: double.infinity,
                  color: backgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        children: [
                          const Text(
                            'Corpo Clínico',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Conheça os especialistas dedicados a transformar sua jornada de saúde em um caminho de bem-estar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: onSurfaceVariantColor),
                          ),
                          const SizedBox(height: 64),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Wrap(
                                spacing: 32,
                                runSpacing: 48,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildDoctorCard(
                                    name: 'Dra. Marina Costa',
                                    specialty: 'Clínica Geral',
                                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC1JRANblusvtWJnvqk2a-oxeZxoI1Ohlyu_bruRcs1IJAKEWDhOArvyEtFx56WPttX5omEnFXnkGOPo5BxuEcCSV2_zAOrbjNufj3_ahqRhyY3pZEi-SL-ckxtL3HwhXPHK0zmDYUfrN7JFSmXTnrgqk9RASPuGA7D5EvRIYjmNMvh6a9s8oLD4XhBa1ABC2GJSXK5qVaMyODUoXI7d3Wl644SMkWR6EYbObmrJ1jD90B_FQEKGcCnUNQcG4Lyv_jr3clu0OScgnk',
                                  ),
                                  _buildDoctorCard(
                                    name: 'Dr. Thorne Blackwood',
                                    specialty: 'Cardiologia',
                                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBMX8qlX31tB6vkWfy_Zz-DK7twmO-VbFYtoyB5j8UDVKZ8D88EimlpADyfRtIAgT2O3fMAQKXJNaxlYXtyu9xzGF44bhGsrQPK54IjC5DDKun9ckp6-apH2R4twR__qvRKQL5EnICUTT-j8D_4TV2qjebNQTzUmdBaAHUCc805lh7ECpR2Y8fyWpXG6HQhA7fj-3EaVFo3c-bA5Q8YRjViPHJQw3cWNts03GDr77XPBIKhV1DwBmzTCWA2QvN84dviwb16MHYOFdg',
                                  ),
                                  _buildDoctorCard(
                                    name: 'Dra. Ana Costa',
                                    specialty: 'Dermatologia',
                                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDJNWJ2VP_xJDcVkFMOekQjvp-D1xxXM2Ds6IAya9vYVVf2jetQPtBi-jR1HDkpyH50uz8iYs-J40PI68tbX6qI0tZ5b2bUuSyu8-LhZEWF4NP8d4ntIp1ZueiGD-WfUh1uBWbGSbbS0CU3K78p7ps_fbr_ZMPyEUzoQO_uykbdwCuCm2UGE4eZ0DbeMl3_ksuozL14F3n_5lpSco4COB8QBLw6EYgnPxxafwQHBrPBP-BLD5gyQneKyJmWhjCfFZVacFlKwZG04GA',
                                  ),
                                  _buildDoctorCard(
                                    name: 'Dr. Ricardo Mello',
                                    specialty: 'Neurologia',
                                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA08Tr3se70cvoH2Sb7_bYgNOxHXx8V5RvxxrIuEZ1JfYt1lwhMlfPl_844KuHvmIFOaQE044kLPVlXfb3e4KJzvOoyse-vFsQrnXohpJa-c5zBl0lb-1NhSlmXBiHgTcV25u8dxpcdsiDnb0dsr7YWFL1L9l5Upjkr0-rs-DVrOiHOJgRzTj1MCs9BT5PYD356icnSDkt2HB8b56Hb2g9_S34ckQh0Oq_3jukVLpSXD_5FmQODTNRmvZeCHUAKTirTol6tR1VTEtM',
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 120), // Espaço extra final
              ],
            ),
          ),

          // Custom AppBar (Glass Effect) - Floating on top of the ScrollView
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0052CC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.health_and_safety, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Sua Consulta',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0052CC),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (MediaQuery.of(context).size.width < 900) {
                              return IconButton(
                                icon: const Icon(Icons.menu, color: onSurfaceVariantColor),
                                onPressed: () {},
                              );
                            }
                            return Row(
                              children: [
                                _buildNavItem('Painel', isActive: true, onTap: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut)),
                                _buildNavItem('Especialidades', onTap: () => _scrollTo(_specialtiesKey)),
                                // ↕ Ordem trocada: Tecnologia agora vem antes de Corpo Clínico
                                _buildNavItem('Tecnologia', onTap: () => _scrollTo(_techKey)),
                                _buildNavItem('Corpo Clínico', onTap: () => _scrollTo(_teamKey)),
                                _buildNavItem('Entrar', onTap: _showLoginModal),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? const Color(0xFF0052CC) : const Color(0xFF434654),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF191C1E))),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 15, color: Color(0xFF434654), height: 1.5)),
          const SizedBox(height: 32),
          Row(
            children: [
              Text('Saiba mais', style: TextStyle(fontWeight: FontWeight.bold, color: iconColor)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16, color: iconColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem({required IconData icon, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF003D9B).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check, color: Color(0xFF003D9B), size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF191C1E))),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 15, color: Color(0xFF434654), height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard({required String name, required String specialty, required String imageUrl}) {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 24),
        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF191C1E))),
        const SizedBox(height: 4),
        Text(
          specialty.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF003D9B),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class LoginModal extends ConsumerStatefulWidget {
  final VoidCallback? onShowRegister;
  const LoginModal({super.key, this.onShowRegister});

  @override
  ConsumerState<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends ConsumerState<LoginModal> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (ok && mounted) {
      Navigator.pop(context); // Fecha o modal
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxWidth: 450, maxHeight: isMobile ? double.infinity : 650),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho do Modal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003D9B), Color(0xFF0052CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bem-vindo de volta',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acesse sua conta para gerenciar consultas',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Formulário
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'USUÁRIO',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8E9199),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: InputDecoration(
                            hintText: 'Digite seu usuário',
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: const Color(0xFFF7F9FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Informe o usuário' : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'SENHA',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8E9199),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Digite sua senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F9FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Informe a senha' : null,
                          // Enter via teclado virtual (mobile) e teclado físico
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        
                        if (auth.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFCDD2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFC62828),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 40),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003D9B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: auth.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Entrar no Sistema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (widget.onShowRegister != null) {
                                widget.onShowRegister!();
                              }
                            },
                            child: const Text('Não tem conta? Cadastre-se aqui'),
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
    );
  }
}
class RegisterModal extends ConsumerStatefulWidget {
  const RegisterModal({super.key});

  @override
  ConsumerState<RegisterModal> createState() => _RegisterModalState();
}

class _RegisterModalState extends ConsumerState<RegisterModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  
  // Doctor specific
  final _crmCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  String _userRole = 'patient'; // 'patient' or 'doctor'
  bool _obscurePassword = true;
  bool _showSuccess = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final success = await ref.read(authProvider.notifier).register(
      email: _emailCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneFormatter.getUnmaskedText(),
      role: _userRole,
      fullName: _nameCtrl.text.trim(),
      crm: _userRole == 'doctor' ? _crmCtrl.text.trim() : null,
      specialty: _userRole == 'doctor' ? _specialtyCtrl.text.trim() : null,
    );

    if (success && mounted) {
      setState(() => _showSuccess = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
          _showLoginModal();
        }
      });
    }
  }

  void _showLoginModal() {
    showDialog(
      context: context,
      builder: (context) => LoginModal(onShowRegister: _showRegisterModal),
    );
  }

  void _showRegisterModal() {
    showDialog(
      context: context,
      builder: (context) => const RegisterModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    const Color primaryColor = Color(0xFF003D9B);

    if (_showSuccess) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF006C4D), size: 80),
              const SizedBox(height: 24),
              Text(
                'Conta criada!',
                style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 12),
              const Text('Sua conta foi criada com sucesso. Redirecionando...', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003D9B), Color(0xFF0052CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Criar nova conta',
                      style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecione o tipo de conta e preencha os dados',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),

              // Role Selection
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 32, 40, 8),
                child: Row(
                  children: [
                    _buildRoleCard(
                      'Paciente',
                      Icons.person_outline,
                      _userRole == 'patient',
                      () => setState(() => _userRole = 'patient'),
                    ),
                    const SizedBox(width: 16),
                    _buildRoleCard(
                      'Médico',
                      Icons.medical_services_outlined,
                      _userRole == 'doctor',
                      () => setState(() => _userRole = 'doctor'),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('NOME COMPLETO'),
                        _buildTextField(_nameCtrl, 'Como devemos te chamar?', Icons.badge_outlined),
                        const SizedBox(height: 24),

                        _buildFieldLabel('E-MAIL'),
                        _buildTextField(_emailCtrl, 'exemplo@email.com', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 24),

                        _buildFieldLabel('WHATSAPP (DDD + NÚMERO)'),
                        _buildTextField(
                          _phoneCtrl, 
                          '(XX) 99999-9999', 
                          Icons.phone_android_outlined, 
                          keyboardType: TextInputType.phone,
                          formatters: [_phoneFormatter],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Informe o WhatsApp';
                            if (!_phoneFormatter.isFill()) return 'Número incompleto';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        if (_userRole == 'doctor') ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('CRM'),
                                    _buildTextField(_crmCtrl, '000000-SP', Icons.assignment_ind_outlined),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('ESPECIALIDADE'),
                                    _buildTextField(_specialtyCtrl, 'Ex: Cardiologia', Icons.medical_information_outlined),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        _buildFieldLabel('NOME DE USUÁRIO'),
                        _buildTextField(_usernameCtrl, 'Escolha um identificador único', Icons.alternate_email),
                        const SizedBox(height: 24),

                        _buildFieldLabel('SENHA'),
                        _buildTextField(
                          _passwordCtrl, 
                          'No mínimo 6 caracteres', 
                          Icons.lock_outline,
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 24),

                        _buildFieldLabel('CONFIRMAR SENHA'),
                        _buildTextField(
                          _confirmPasswordCtrl, 
                          'Repita a senha escolhida', 
                          Icons.lock_reset,
                          isPassword: true,
                          obscure: _obscurePassword,
                          validator: (v) => v != _passwordCtrl.text ? 'As senhas não coincidem' : null,
                        ),

                        if (auth.error != null) ...[
                          const SizedBox(height: 24),
                          _buildErrorBox(auth.error!),
                        ],

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(_userRole == 'doctor' ? 'Criar conta de médico' : 'Criar minha conta', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showLoginModal();
                            },
                            child: const Text('Já tem uma conta? Entre aqui'),
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
    );
  }

  Widget _buildRoleCard(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    const Color primaryColor = Color(0xFF003D9B);
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.05) : const Color(0xFFF7F9FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFE0E3E5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? primaryColor : const Color(0xFF8E9199), size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? primaryColor : const Color(0xFF434654),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF8E9199),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, 
    IconData icon, {
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword && onToggleVisibility != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF7F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator ?? (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: const Color(0xFFC62828),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}