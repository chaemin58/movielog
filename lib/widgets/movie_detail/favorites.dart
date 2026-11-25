import 'package:flutter/material.dart';


class Favorites extends StatelessWidget {
  const Favorites({super.key, required this.handleSubmitFavorite});

  final VoidCallback handleSubmitFavorite;

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: handleSubmitFavorite, icon: const Icon(Icons.bookmark_border));
  }
}