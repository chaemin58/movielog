import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.content,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
  });
  final Widget content;
  final VoidCallback onPressed;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;
    return TextButton(
      onPressed: onPressed,
      child: content,
      style: TextButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primary600 : Colors.transparent,
        foregroundColor: isPrimary ? Colors.white : AppColors.primary600,
        side: isPrimary ? null : BorderSide(color: AppColors.primary600),
        minimumSize: const Size(double.infinity, 40),
      ),
    );
  }
}
