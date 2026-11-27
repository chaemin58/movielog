import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoriteDetailViewModel>();
    if (vm.isLoading || vm.isSaving) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: !vm.hasLoadedStatus
          ? '즐겨찾기 여부 다시 조회'
          : vm.isFavorite
          ? '즐겨찾기 해제'
          : '즐겨찾기 등록',
      icon: Icon(
        !vm.hasLoadedStatus
            ? Icons.refresh
            : vm.isFavorite
            ? Icons.bookmark
            : Icons.bookmark_border,
      ),
      onPressed: () async {
        if (!vm.hasLoadedStatus) {
          await vm.load();
        } else {
          await vm.toggle();
        }
        if (!context.mounted || !vm.isCurrentSession) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vm.errorMessage ??
                  (vm.isFavorite ? '즐겨찾기에 등록했습니다.' : '즐겨찾기를 해제했습니다.'),
            ),
          ),
        );
      },
    );
  }
}
