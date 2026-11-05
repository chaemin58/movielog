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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary600,
          ),
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
