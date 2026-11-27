import 'package:flutter/material.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({super.key, required this.viewModel});
  final PagedMoviesViewModel viewModel;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        if (viewModel.loadMoreError != null) Text(viewModel.loadMoreError!),
        if (viewModel.hasMore)
          FilledButton(
            onPressed: viewModel.isLoadingMore ? null : viewModel.loadNextPage,
            child: viewModel.isLoadingMore
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(viewModel.loadMoreError == null ? '더 보기' : '다시 시도'),
          )
        else
          const Text('마지막 페이지입니다.'),
      ],
    ),
  );
}
