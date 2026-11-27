import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/widgets/movies/movie_grid.dart';
import 'package:movielog/widgets/movies/movie_page_footer.dart';
import 'package:movielog/widgets/movies/movie_error_grid.dart';

class MovieSearchScreen extends StatelessWidget {
  const MovieSearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagedMoviesViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('영화 검색'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: '검색어',
                hintText: '영화 제목을 입력하고 검색을 눌러 주세요',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (query) => vm.loadInitial(query: query),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: switch (vm.phase) {
                LoadPhase.idle => const Text('검색어를 입력해 주세요.'),
                LoadPhase.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                LoadPhase.empty => const Text('검색 결과가 없습니다.'),
                LoadPhase.error => MovieErrorGrid(
                  message: vm.message,
                  onRetry: vm.retry,
                ),
                LoadPhase.ready => Column(
                  children: [
                    MovieGrid(movies: vm.movies),
                    MoviePageFooter(viewModel: vm),
                  ],
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
