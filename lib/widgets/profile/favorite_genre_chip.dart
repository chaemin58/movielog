import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

class FavoriteGenreChip extends StatelessWidget {
  const FavoriteGenreChip({super.key, required this.genre});

  final String genre;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(genre),
      backgroundColor: AppColors.primary200,
      side: BorderSide.none,
      labelStyle: TextStyle(color: AppColors.primary600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
