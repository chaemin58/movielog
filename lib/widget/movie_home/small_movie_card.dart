import 'package:flutter/material.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/widget/movie_home/rank_badge.dart';

class SmallMovieCard extends StatelessWidget {
  const SmallMovieCard({super.key, required this.movie, required this.rank});
  final Movie movie;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          height: 150,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  movie.posterAsset,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(top: 5, left: 5, child: RankBadge(rank: rank)),
            ],
          ),
        ),

        Text(
          movie.title,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 16),
            Text('${movie.rating}'),
          ],
        ),
      ],
    );
  }
}
