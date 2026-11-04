import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/widgets/common/tmdb_poster_image.dart';
import 'package:movielog/theme/app_colors.dart';

class RatingCard extends StatelessWidget {
  const RatingCard({required this.entry});
  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final date = rating.createdAt.toLocal();
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TmdbPosterImage(
                posterPath: entry.movie?.posterPath,
                width: 72,
                height: 108,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.movie?.title ?? '영화 정보 없음 · ID ${rating.movieId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 20,
                        color: AppColors.primary500,
                      ),
                      const SizedBox(width: 4),
                      Text('${rating.score} / 5'),
                    ],
                  ),
                  if (rating.comment != null &&
                      rating.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(rating.comment!),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
