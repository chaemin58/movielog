import 'package:flutter/material.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/widget/common/common_app_bar.dart';
import 'package:movielog/widget/common/custom_button.dart';
import 'package:movielog/widget/movie_detail/movie_detail_description.dart';

class MovieDetailPage extends StatelessWidget {
  const MovieDetailPage({super.key, required this.movieId});

  final String movieId;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(movieId);
    final movie = findMovieById(id);

    if (movie == null)
      return const Scaffold(body: Center(child: Text('영화를 찾을 수 없어요')));
    return (Scaffold(
      appBar: CommonAppBar(title: 'Cinema Archive'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(movie.posterAsset, height: 585, fit: BoxFit.cover),
            MovieDetailDescription(movie: movie),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                content: Text("즐겨찾기"),
                onPressed: () {},
                variant: AppButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(content: Text('후기 남기기'), onPressed: () {}),
            ),
          ],
        ),
      ),
    ));
  }
}
