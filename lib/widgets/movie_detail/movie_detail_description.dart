import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/utils/format.dart';
import 'package:movielog/widgets/movie_detail/movie_description_chip.dart';

class MovieDetailDescription extends StatelessWidget {
  const MovieDetailDescription({super.key, required this.movie});

  final TmdbMovieDetailDto movie;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.tryParse(movie.releaseDate ?? '')?.year;
    final genreNames = movie.genres.map((genre) => genre.name).toList();
    final rating = movie.voteAverage / 2;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(movie.title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            [
              if (year != null) '$year',
              if (genreNames.isNotEmpty) genreNames.join(', '),
              if (movie.runtime != null && movie.runtime! > 0)
                '${movie.runtime}분',
            ].join(' · '),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              RatingBarIndicator(
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: AppColors.primary600),
                rating: rating,
                itemSize: 20,
              ),
              Text(
                '${rating.toStringAsFixed(1)} (${formatWithComma(movie.voteCount)})',
              ),
            ],
          ),
          const SizedBox(height: 8),
          MovieDescriptionChip(tags: genreNames),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            "시놉시스",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(movie.overview.isEmpty ? '등록된 줄거리가 없습니다.' : movie.overview),
        ],
      ),
    );
  }
}
