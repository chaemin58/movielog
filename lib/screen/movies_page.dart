import 'package:flutter/material.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/service/fake_movie_service.dart';
import 'package:movielog/widget/common/common_app_bar.dart';
import 'package:movielog/widget/movies/choice_chip_container.dart';
import 'package:movielog/widget/movies/movie_empty_grid.dart';
import 'package:movielog/widget/movies/movie_grid.dart';

final genreList = ['전체', ...movies.map((movie) => movie.genre).toSet()];

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  String selectedGenre = '전체';
  late Future<List<Movie>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _moviesFuture = const FakeMovieService().fetchMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: "영화"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ChoiceChipContainer(
              genres: genreList,
              selectedGenre: selectedGenre,
              onGenreSelected: (genre) {
                setState(() => selectedGenre = genre);
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshop) {
                if (snapshop.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final movieList = snapshop.data ?? [];

                if (movieList.isEmpty) {
                  return const MovieEmptyGrid();
                }

                final filteredList = selectedGenre == '전체'
                    ? movieList
                    : movieList.where((m) => m.genre == selectedGenre).toList();

                return MovieGrid(movies: filteredList);
              },
            ),
          ],
        ),
      ),
    );
  }
}
