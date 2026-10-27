import 'package:flutter/material.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/widgets/common/common_app_bar.dart';
import 'package:movielog/widgets/common/custom_button.dart';
import 'package:movielog/widgets/common/tmdb_poster_image.dart';
import 'package:movielog/widgets/movie_detail/movie_detail_description.dart';
import 'package:movielog/widgets/movies/movie_error_grid.dart';
import 'package:provider/provider.dart';

class MovieDetailPage extends StatelessWidget {
  const MovieDetailPage({super.key, required this.movieId});

  final String movieId;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(movieId);
    if (id == null || id <= 0) {
      return Scaffold(
        appBar: CommonAppBar(title: 'Cinema Archive'),
        body: const Center(child: Text('잘못된 영화 ID입니다.')),
      );
    }

    return Consumer<MovieDetailViewModel>(
      builder: (context, viewModel, child) {
        final movie = viewModel.movie;
        return Scaffold(
          appBar: CommonAppBar(title: 'Cinema Archive'),
          body: switch (viewModel.status) {
            MovieDetailLoadStatus.idle || MovieDetailLoadStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            MovieDetailLoadStatus.error => Center(
              child: MovieErrorGrid(
                message: viewModel.message,
                onRetry: () => context.read<MovieDetailViewModel>().load(id),
              ),
            ),
            MovieDetailLoadStatus.success =>
              movie == null
                  ? const Center(child: Text('영화를 찾을 수 없어요'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TmdbPosterImage(
                            posterPath: movie.posterPath,
                            width: MediaQuery.sizeOf(context).width,
                            height: 585,
                          ),
                          MovieDetailDescription(movie: movie),
                        ],
                      ),
                    ),
          },
          bottomNavigationBar: viewModel.status == MovieDetailLoadStatus.success
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          content: const Text('즐겨찾기'),
                          onPressed: () {},
                          variant: AppButtonVariant.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          content: const Text('후기 남기기'),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
