import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.content,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
  });
  final Widget content;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;
    return SizedBox(
      width: width,
      height: 44,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : content,
        style: TextButton.styleFrom(
          backgroundColor: isPrimary
              ? AppColors.primary600
              : Colors.transparent,
          disabledBackgroundColor: AppColors.neutral800,
          foregroundColor: isPrimary ? Colors.white : AppColors.primary600,
          side: isPrimary ? null : BorderSide(color: AppColors.primary600),
        ),
      ),
    );
  }
}
