import 'package:flutter/material.dart';
import '../../../core/theme/auth_themes.dart';
import '../widgets/auth_header.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';

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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isLogin ? AuthThemes.login : AuthThemes.register,
      child: Scaffold(
        body: Column(
          children: [
            const AuthHeader(),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },

                child: isLogin
                    ? LoginForm(
                        key: const ValueKey('login'),
                        onToggle: toggle,
                        onLogin: () {
                          print("Login clicado");

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Login realizado")),
                          );
                        },
                      )
                    : RegisterForm(
                        key: const ValueKey('register'),
                        onToggle: toggle,
                        onRegister: () {
                          print("Cadastro clicado");

                          Navigator.pushNamed(context, '/otp');
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}