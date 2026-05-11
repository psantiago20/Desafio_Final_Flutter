import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? backRoute;
  final Widget? logo;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.backRoute,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (backRoute != null) ...[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        if (logo != null) ...[
          Center(child: logo!),
          const SizedBox(height: 32),
        ],
        
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
