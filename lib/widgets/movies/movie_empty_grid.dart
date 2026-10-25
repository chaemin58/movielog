import 'package:flutter/material.dart';

class MovieEmptyGrid extends StatelessWidget {
  const MovieEmptyGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined, size: 64),
          SizedBox(height: 16),
          Text('영화가 없어요'),
          SizedBox(height: 8),
          Text('표시할 영화가 아직 없습니다'),
        ],
      ),
    );
  }
}
