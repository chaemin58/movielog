import 'package:flutter/material.dart';

class Movie {
  final String title;
  final String? nickname;

  Movie({required this.title, this.nickname});
}

List<Movie> movieList = [
  Movie(title: "오디세이", nickname: "오디세우스"),
  Movie(title: "스파이더맨", nickname: "피터 파커"),
  Movie(title: "인사이드 아웃 2", nickname: "라일리"),
];

void main() {
  for (var movie in movieList) {
    print(movie.title + (movie.nickname ?? '회원'));
  }

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Hello MovieLog!'))),
    ),
  );
}
