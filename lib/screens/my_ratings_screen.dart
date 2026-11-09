import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/widgets/movie_detail/movie_rating_dialog.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/common/custom_button.dart';
import 'package:movielog/widgets/my_ratings/rating_card.dart';
import 'package:provider/provider.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  Future<void> _edit(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment,
        onSubmit: (score, comment) => vm.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(vm.refreshWarning ?? '평점을 수정했습니다.')));
  }

  Future<void> _delete(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteRatingDialog(
        onConfirm: () => vm.deleteRating(rating.ratingId),
      ),
    );
    if (!context.mounted || deleted != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(vm.refreshWarning ?? '평점을 삭제했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyRatingsViewModel>();
    Widget body;
    switch (viewModel.status) {
      case MyRatingsLoadStatus.idle:
      case MyRatingsLoadStatus.loading:
        body = const Center(child: CircularProgressIndicator());
      case MyRatingsLoadStatus.error:
        body = _notice(
          viewModel.refreshWarning ?? viewModel.message ?? '평점을 불러오지 못했습니다.',
          viewModel.load,
        );
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
              final entry = viewModel.ratings[index - 1];
              return RatingCard(
                entry: entry,
                onEdit: viewModel.isWriting
                    ? null
                    : () => _edit(context, entry.rating),
                onDelete: viewModel.isWriting
                    ? null
                    : () => _delete(context, entry.rating),
              );
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

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});
  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;
  String? _errorText;

  Future<void> _confirm() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorText = writeErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isDeleting,
    child: AlertDialog(
      title: const Text('평점을 삭제할까요?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('삭제한 평점은 복구할 수 없습니다.'),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        CustomButton(
          content: const Text('취소'),
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
        ),
        CustomButton(
          content: const Text('삭제'),
          isLoading: _isDeleting,
          onPressed: _isDeleting ? null : _confirm,
        ),
      ],
    ),
  );
}
