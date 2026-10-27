import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieDescriptionChip extends StatelessWidget {
  const MovieDescriptionChip({super.key, required this.tags});
  final List<String> tags;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: tags
          .map(
            (tag) => Chip(
              label: Text(tag),
              backgroundColor: AppColors.neutral600,
              side: BorderSide.none,
              labelStyle: TextStyle(color: AppColors.neutral900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          )
          .toList(),
    );
  }
}
