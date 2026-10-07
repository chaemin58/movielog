import 'package:flutter/material.dart';
import 'package:movielog/Widget/movies/movie_error_grid.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/service/fake_movie_service.dart';
import 'package:movielog/service/genre_preference.dart';
import 'package:movielog/widget/common/common_app_bar.dart';
import 'package:movielog/widget/movies/choice_chip_container.dart';
import 'package:movielog/widget/movies/movie_empty_grid.dart';
import 'package:movielog/widget/movies/movie_grid.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  String selectedGenre = '전체';
  List<String> _genres = [];
  late Future<List<Movie>> _moviesFuture;
  final _genrePreference = GenrePreference();

  Future<void> _loadGenres() async {
    final response = await const FakeMovieService().fetchGenres();
    setState(() {
      _genres = ['전체', ...response];
    });
  }

  Future<void> _getSelectedGenre() async {
    final response = await _genrePreference.read();
    setState(() {
      selectedGenre = response;
    });
  }

  @override
  void initState() {
    super.initState();
    _moviesFuture = const FakeMovieService().fetchMovies();
    _loadGenres();
    _getSelectedGenre();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: "영화"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ChoiceChipContainer(
              genres: _genres,
              selectedGenre: selectedGenre,
              onGenreSelected: (genre) {
                setState(() => selectedGenre = genre);
                _genrePreference.save(genre);
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshop) {
                final movieList = snapshop.data ?? [];
                final filteredList = selectedGenre == '전체'
                    ? movieList
                    : movieList.where((m) => m.genre == selectedGenre).toList();
                if (snapshop.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (filteredList.isEmpty) {
                  return const MovieEmptyGrid();
                  // return MovieErrorGrid(
                  //   onRetry: () {
                  //     setState(() {
                  //       _moviesFuture = const FakeMovieService().fetchMovies();
                  //     });
                  //   },
                  // );
                }

                return MovieGrid(movies: filteredList);
              },
            ),
          ],
        ),
      ),
    );
  }
}
