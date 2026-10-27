import 'package:flutter/material.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/widgets/common/tmdb_poster_image.dart';
import 'package:movielog/widgets/movie_home/rank_badge.dart';

class SmallMovieCard extends StatelessWidget {
  const SmallMovieCard({super.key, required this.movie, required this.rank});
  final TmdbMovieDto movie;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
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
                  child: TmdbPosterImage(
                    posterPath: movie.posterPath,
                    width: 100,
                    height: 150,
                  ),
                ),
                Positioned(top: 5, left: 5, child: RankBadge(rank: rank)),
              ],
            ),
          ),

          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 16),
              Text('${movie.voteAverage}'),
            ],
          ),
        ],
      ),
    );
  }
}
