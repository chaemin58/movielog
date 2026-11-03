import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/common/tmdb_poster_image.dart';
import 'package:movielog/widgets/movielog_button.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('내가 등록한 평점'), centerTitle: true),
      body: SafeArea(child: _body(vm)),
    );
  }

  Widget _body(MyRatingsViewModel vm) {
    switch (vm.status) {
      case MyRatingsLoadStatus.idle:
      case MyRatingsLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case MyRatingsLoadStatus.error:
      case MyRatingsLoadStatus.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  vm.status == MyRatingsLoadStatus.empty
                      ? Icons.star_border
                      : Icons.error_outline,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  vm.status == MyRatingsLoadStatus.empty
                      ? '아직 등록한 평점이 없습니다.'
                      : vm.message!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                MovieLogButton(label: '다시 조회', width: 120, onPressed: vm.load),
              ],
            ),
          ),
        );
      case MyRatingsLoadStatus.success:
        return RefreshIndicator(
          onRefresh: vm.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (vm.message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(vm.message!),
                ),
              ...vm.ratings.map((entry) {
                final rating = entry.rating;
                final date = rating.createdAt.toLocal();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TmdbPosterImage(
                            posterPath: entry.movie?.posterPath,
                            width: 72,
                            height: 108,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.movie?.title ??
                                    '영화 정보 없음 (ID: ${rating.movieId})',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '★ ${rating.score} / 5',
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                rating.comment?.trim().isNotEmpty == true
                                    ? rating.comment!
                                    : '작성한 후기가 없습니다.',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
    }
  }
}
