import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/widget/common/custom_button.dart';
import 'package:movielog/widget/common/tag_badge.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 534,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(movie.posterAsset, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  TagBadge(label: "추천신작"),
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.genre} · ${movie.type} · ${movie.runtimeMinutes}분',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    content: Text('상세보기'),
                    onPressed: () => context.push('/movies/${movie.id}'),
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
