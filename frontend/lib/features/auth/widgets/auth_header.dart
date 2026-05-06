import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.secondaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Hero(
            tag: 'app_logo',
            child: Image.asset(
              'assets/images/test.png',
              height: 100,
            ),
          ),
        ),
      ),
    );
  }
}