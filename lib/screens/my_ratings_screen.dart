import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/common/custom_button.dart';
import 'package:movielog/widgets/my_ratings/rating_card.dart';
import 'package:provider/provider.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyRatingsViewModel>();
    Widget body;
    switch (viewModel.status) {
      case MyRatingsLoadStatus.idle:
      case MyRatingsLoadStatus.loading:
        body = const Center(child: CircularProgressIndicator());
      case MyRatingsLoadStatus.error:
        body = _notice(viewModel.message ?? '평점을 불러오지 못했습니다.', viewModel.load);
      case MyRatingsLoadStatus.empty:
        body = _notice('등록된 평점이 없습니다.', viewModel.load);
      case MyRatingsLoadStatus.success:
        body = RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.ratings.length + 1,
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '평점 ${viewModel.ratings.length}개',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (viewModel.message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        viewModel.message!,
                        style: const TextStyle(color: AppColors.neutral800),
                      ),
                    ],
                  ],
                );
              }
              return RatingCard(entry: viewModel.ratings[index - 1]);
            },
          ),
        );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          '내가 등록한 평점',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: body)],
        ),
      ),
    );
  }

  Widget _notice(String message, VoidCallback onRetry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.rate_review_outlined,
            size: 40,
            color: AppColors.neutral800,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          CustomButton(
            width: 120,
            onPressed: onRetry,
            content: const Text('다시 불러오기'),
          ),
        ],
      ),
    ),
  );
}

// class _RatingCard extends StatelessWidget {
//   const _RatingCard({required this.entry});
//   final RatingWithMovie entry;

//   @override
//   Widget build(BuildContext context) {
//     final rating = entry.rating;
//     final date = rating.createdAt.toLocal();
//     final dateLabel =
//         '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
//     return Card(
//       margin: EdgeInsets.zero,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: TmdbPosterImage(
//                 posterPath: entry.movie?.posterPath,
//                 width: 72,
//                 height: 108,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     entry.movie?.title ?? '영화 정보 없음 · ID ${rating.movieId}',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.star,
//                         size: 20,
//                         color: AppColors.primary500,
//                       ),
//                       const SizedBox(width: 4),
//                       Text('${rating.score} / 5'),
//                     ],
//                   ),
//                   if (rating.comment != null &&
//                       rating.comment!.trim().isNotEmpty) ...[
//                     const SizedBox(height: 8),
//                     Text(rating.comment!),
//                   ],
//                   const SizedBox(height: 8),
//                   Text(
//                     dateLabel,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: AppColors.neutral800,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
