import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

enum RatingSubmitStatus { idle, submitting, success, error }

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, {this.ratingService, this.memberId});
  final TmdbMovieService _service;
  final RatingApiService? ratingService;
  final int? memberId;
  RatingSubmitStatus submitStatus = RatingSubmitStatus.idle;
  String? submitMessage;

  Future<void> createRating({required int score, String? comment}) async {
    if (_disposed || submitStatus == RatingSubmitStatus.submitting) return;
    final id = memberId;
    final currentMovie = movie;
    final service = ratingService;
    if (id == null || currentMovie == null || service == null) {
      submitStatus = RatingSubmitStatus.error;
      submitMessage = '먼저 회원가입과 영화 조회를 완료해 주세요.';
      notifyListeners();
      return;
    }
    submitStatus = RatingSubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      await service.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: currentMovie.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = RatingSubmitStatus.success;
    } catch (error) {
      if (_disposed) return;
      submitStatus = RatingSubmitStatus.error;
      submitMessage = writeErrorMessage(error);
    }
    if (!_disposed) notifyListeners();
  }

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
