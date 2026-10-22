import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/utils/format.dart';
import 'package:movielog/widget/movie_detail/movie_description_chip.dart';

class MovieDetailDescription extends StatelessWidget {
  const MovieDetailDescription({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(movie.title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            '${movie.year}  · ${movie.genre} · ${movie.type} · ${movie.runtimeMinutes}분',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              RatingBarIndicator(
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: AppColors.primary600),
                rating: movie.rating,
                itemSize: 20,
              ),
              Text('${movie.rating} (${formatWithComma(movie.ratingCount)})'),
            ],
          ),
          const SizedBox(height: 8),
          MovieDescriptionChip(movie: movie),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            "시놉시스",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(movie.description),
        ],
      ),
    );
  }
}
