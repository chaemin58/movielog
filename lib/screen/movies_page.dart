import 'package:flutter/material.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/widget/common/common_app_bar.dart';
import 'package:movielog/widget/movies/choice_chip_container.dart';
import 'package:movielog/widget/movies/movie_list_card.dart';

final genreList = ['전체', ...movies.map((movie) => movie.genre).toSet()];

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  String selectedGenre = '전체';
  @override
  Widget build(BuildContext context) {
    final filterdMovieList = selectedGenre == '전체'
        ? movies
        : movies.where((movie) => movie.genre == selectedGenre).toList();
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filterdMovieList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 170 / 290,
              ),
              itemBuilder: (context, index) {
                final movie = filterdMovieList[index];
                return MovieListCard(movie: movie);
              },
            ),
          ],
        ),
      ),
    );
  }
}
