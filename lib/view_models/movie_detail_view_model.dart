import 'package:flutter/material.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service);
  final TmdbMovieService _service;

  TmdbMovieDetailDto? movie;
  MovieDetailLoadStatus status = MovieDetailLoadStatus.idle;
  String? message;

  bool _disposed = false;

  Future<void> load(int movieId) async {
    if (_disposed) return;

    //먼저 로딩 상태로 만들어줌
    status = MovieDetailLoadStatus.loading;
    message = null;

    //로딩 상태가 되엇다고 구독한 애들한테 알림
    notifyListeners();

    //실제 요청
    try {
      final response = await _service.fetchMovieDetail(movieId: movieId);
      if (_disposed) return;

      movie = response;
      status = MovieDetailLoadStatus.success;
      notifyListeners();
    } catch (error) {
      if (_disposed) return;

      status = MovieDetailLoadStatus.error;
      message = '영화 정보를 불러오지 못했어요.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
