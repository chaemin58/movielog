import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

class ShowMoreButton extends StatelessWidget {
  const ShowMoreButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.info_outline, color: Colors.white, size: 16),
      label: const Text('상세보기', style: TextStyle(color: Colors.white)),
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primary600,
        minimumSize: Size(double.infinity, 40), // 가로 꽉 채우기
      ),
    );
  }
}
