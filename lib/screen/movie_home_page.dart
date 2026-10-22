import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/widget/common/common_app_bar.dart';
import 'package:movielog/widget/movie_home/movie_card.dart';
import 'package:movielog/widget/movie_home/small_movie_card_container.dart';

class MovieHomePage extends StatelessWidget {
  const MovieHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: "MovieLog"),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '오늘은 어떤 \n영화를 볼까요?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: MovieCard(movie: movies[0]),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('인기 영화', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => context.push('/movies'),
                    child: Text('전체보기 >'),
                  ),
                ],
              ),
            ),

            //여기에 영화 주르륵
            SizedBox(
              height: 220,
              child: SmallMovieCardContainer(movieList: movies),
            ),
          ],
        ),
      ),
    );
  }
}
