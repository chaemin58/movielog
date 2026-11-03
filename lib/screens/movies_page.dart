import 'package:flutter/material.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/common/common_app_bar.dart';
import 'package:movielog/widgets/movies/choice_chip_container.dart';
import 'package:movielog/widgets/movies/movie_empty_grid.dart';
import 'package:movielog/widgets/movies/movie_error_grid.dart';
import 'package:movielog/widgets/movies/movie_grid.dart';
import 'package:provider/provider.dart';

class MoviesPage extends StatelessWidget {
  const MoviesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '영화'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) {
                final selectedGenre = viewModel.genres
                    .where((genre) => genre.id == viewModel.selectedGenreId)
                    .firstOrNull;

                return ChoiceChipContainer(
                  isLoading: viewModel.status == MovieListLoadStatus.loading,
                  genres: [
                    '전체',
                    ...viewModel.genres.map((genre) => genre.name),
                  ],
                  selectedGenre: selectedGenre?.name ?? '전체',
                  onGenreSelected: (name) {
                    final genre = viewModel.genres
                        .where((genre) => genre.name == name)
                        .firstOrNull;
                    context.read<MovieListViewModel>().selectGenre(genre?.id);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.status) {
                  MovieListLoadStatus.idle || MovieListLoadStatus.loading =>
                    const Center(child: CircularProgressIndicator()),
                  MovieListLoadStatus.error => MovieErrorGrid(
                    message: viewModel.message,
                    onRetry: () =>
                        context.read<MovieListViewModel>().loadInitial(),
                  ),
                  MovieListLoadStatus.empty => const MovieEmptyGrid(),
                  MovieListLoadStatus.success => MovieGrid(
                    movies: viewModel.movies,
                    genreNames: {
                      for (final genre in viewModel.genres)
                        genre.id: genre.name,
                    },
                  ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}
