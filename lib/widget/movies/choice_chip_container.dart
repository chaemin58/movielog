import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

class ChoiceChipContainer extends StatelessWidget {
  const ChoiceChipContainer({
    super.key,
    required this.genres,
    required this.selectedGenre,
    required this.onGenreSelected,
  });

  final List<String> genres;
  final String selectedGenre;
  final ValueChanged<String> onGenreSelected;
  @override
  Widget build(BuildContext context){
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((genre) {
        final isSelected = selectedGenre == genre;
        return ChoiceChip(
          label: Text(genre),
          selected: isSelected,
          onSelected: (_) => onGenreSelected(genre),
          selectedColor: AppColors.primary600,
          backgroundColor: AppColors.primary200,
          showCheckmark: false,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

}
