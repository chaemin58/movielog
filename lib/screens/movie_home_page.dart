import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/widgets/common/common_app_bar.dart';
import 'package:movielog/widgets/movie_home/movie_card.dart';
import 'package:movielog/widgets/movie_home/small_movie_card_container.dart';
import 'package:provider/provider.dart';

class MovieHomePage extends StatelessWidget {
  const MovieHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieHomeViewModel>();
    final popularMovies = viewModel.popularMovies;

    //위젯 선언
    Widget body;

    switch (viewModel.status) {
      case MovieHomeLoadStatus.idle:
      case MovieHomeLoadStatus.loading:
        body = const Center(child: CircularProgressIndicator());
        break;

      case MovieHomeLoadStatus.error:
        body = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(viewModel.message ?? '영화를 불러오지 못했어요.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => viewModel.loadPopular(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        );
        break;

      case MovieHomeLoadStatus.empty:
      case MovieHomeLoadStatus.success:
        // success 상태여도 목록이 비어 있으면 안전하게 처리
        if (popularMovies.isEmpty) {
          body = const Center(child: Text('표시할 인기 영화가 없어요.'));
          break;
        }

        body = SingleChildScrollView(
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '오늘은 어떤 \n영화를 볼까요?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: MovieCard(movie: popularMovies[0]),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '인기 영화',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
                    child: PopularMovieCardContainer(movieList: popularMovies),
                  ),
                ],
              ),
            ],
          ),
        );
    }

    return Scaffold(
      appBar: CommonAppBar(title: "MovieLog"),
      body: body,
    );
  }
}
