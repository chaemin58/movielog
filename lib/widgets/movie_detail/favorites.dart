import 'package:flutter/material.dart';

class Favorites extends StatelessWidget {
  const Favorites({
    super.key,
    required this.handleSubmitFavorite,
    required this.isChecked,
  });

  final VoidCallback handleSubmitFavorite;
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: handleSubmitFavorite,
      icon: Icon(isChecked ? Icons.bookmark : Icons.bookmark_border),
    );
  }
}
