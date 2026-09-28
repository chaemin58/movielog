import 'package:flutter/material.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/widget/movie_home/small_movie_card.dart';

class SmallMovieCardContainer extends StatelessWidget {
  const SmallMovieCardContainer({super.key, required this.movieList});

  final List<Movie> movieList;
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: movieList.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final movie = movieList[index];
        return SmallMovieCard(movie: movie, rank: index + 1);
      },
    );
  }
}
