import 'package:flutter/material.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/widgets/common/tmdb_poster_image.dart';
import 'package:movielog/widgets/movies/rating_badge.dart';

class MovieListCard extends StatelessWidget {
  const MovieListCard({super.key, required this.movie, this.genre = ''});

  final TmdbMovieDto movie;
  final String genre;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.tryParse(movie.releaseDate ?? '')?.year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: 170,
                height: 250,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: RatingBadge(rating: movie.voteAverage / 2),
            ),
          ],
        ),
        Text(
          movie.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          [if (year != null) '$year', if (genre.isNotEmpty) genre].join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
