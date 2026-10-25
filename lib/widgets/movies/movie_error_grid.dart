import 'package:flutter/material.dart';

class MovieErrorGrid extends StatelessWidget {
  const MovieErrorGrid({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.movie_outlined, size: 64),
        SizedBox(height: 16),
        Text('에러가 발생했습니다.'),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          label: Text('다시 시도하기'),
          icon: Icon(Icons.refresh),
        ),
      ],
    );
  }
}
