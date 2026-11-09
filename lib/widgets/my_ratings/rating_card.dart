import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/widgets/common/tmdb_poster_image.dart';
import 'package:movielog/theme/app_colors.dart';

class RatingCard extends StatelessWidget {
  const RatingCard({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
  });
  final RatingWithMovie entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.primary300, width: 2),
      ),
      margin: EdgeInsets.zero,
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
                    entry.movie?.title ?? '영화 정보 없음 · ID ${rating.movieId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '별점',
                        style: TextStyle(
                          color: AppColors.primary600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${rating.score} / 5'),
                    ],
                  ),
                  //comment는 선택사항이기 때문에 분기처리.
                  //comment가 있으면 코멘트를 보여주고 비어있다면 남긴 코멘트가 없습니다. 라고 보여주기
                  if (rating.comment != null)
                    Text(
                      rating.comment!,
                    ) //null이 아니라고 확신하기 때문에 !을 붙임. 지역변수에 담으면 !없이 사용할 수 있다고 한다.
                  else
                    const Text("남긴 코멘트가 없습니다."),
                ],
              ),
            ),
            if (onEdit != null || onDelete != null)
              Column(
                children: [
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary500,
                      backgroundColor: AppColors.primary100,
                      minimumSize: const Size(52, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('수정'),
                  ),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB3261E),
                      backgroundColor: const Color(0xFFFFF1F0),
                      minimumSize: const Size(52, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('삭제'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
