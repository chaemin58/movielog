import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widget/profile/favorite_genre_chip.dart';

class FavoriteGenreChipContainer extends StatelessWidget {
  const FavoriteGenreChipContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "선호하는 장르",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w500,
          ),
        ),
        Wrap(
          runSpacing: 8,
          spacing: 8,
          children: [
            FavoriteGenreChip(genre: "드라마"),
            FavoriteGenreChip(genre: "SF"),
            FavoriteGenreChip(genre: "애니메이션"),
          ],
        ),
      ],
    );
  }
}
