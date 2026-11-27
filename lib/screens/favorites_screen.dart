import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/widgets/movies/movie_error_grid.dart';
import 'package:movielog/widgets/movies/movie_list_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('내 즐겨찾기'), centerTitle: true),
      body: switch (vm.phase) {
        LoadPhase.idle ||
        LoadPhase.loading => const Center(child: CircularProgressIndicator()),
        LoadPhase.empty => const Center(child: Text('즐겨찾기한 영화가 없습니다.')),
        LoadPhase.error => Center(
          child: MovieErrorGrid(
            message: '즐겨찾기를 불러오지 못했습니다.',
            onRetry: vm.refresh,
          ),
        ),
        LoadPhase.ready => RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: vm.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = vm.items[index];
              Future<void> open() async {
                await context.push('/movies/${item.favorite.movieId}');
                if (context.mounted) await vm.refresh();
              }

              if (item.movie != null) {
                return MovieListCard(
                  key: ValueKey(item.favorite.movieId),
                  movie: item.movie!,
                  onTap: open,
                );
              }
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.image_not_supported_outlined),
                      title: Text('영화 #${item.favorite.movieId}'),
                      subtitle: const Text('영화 정보를 불러오지 못했습니다.'),
                      onTap: open,
                    ),
                    TextButton(
                      onPressed: vm.retrying.contains(item.favorite.movieId)
                          ? null
                          : () => vm.retryMovie(item),
                      child: Text(
                        vm.retrying.contains(item.favorite.movieId)
                            ? '조회 중…'
                            : '영화 정보 다시 조회',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      },
    );
  }
}
