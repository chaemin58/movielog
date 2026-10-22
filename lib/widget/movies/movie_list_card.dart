import 'package:flutter/material.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/widget/movies/rating_badge.dart';

class MovieListCard extends StatelessWidget {
  const MovieListCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 170,
                height: 250,
                child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: RatingBadge(rating: movie.rating),
            ),
          ],
        ),
        Text(
          movie.title,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text('${movie.year} • ${movie.genre}'),
      ],
    );
  }
}
