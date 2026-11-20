import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/service/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

enum RatingSubmitStatus { idle, submitting, success, error }

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service, {
    RatingApiService? ratingService,
    AuthViewModel? auth,
    this.memberId,
  }) : _ratingService = ratingService,
       _auth = auth;
  final AuthViewModel? _auth;

  bool _isCurrentSession(int? version) =>
      !_disposed &&
      (_auth == null ||
          (_auth.sessionVersion == version &&
              _auth.status == AuthStatus.signedIn));
  final TmdbMovieService _service;
  final RatingApiService? _ratingService;
  final int? memberId;
  RatingSubmitStatus submitStatus = RatingSubmitStatus.idle;
  String? submitMessage;
  RatingDto? myRating;

  Future<void> createRating({required int score, String? comment}) async {
    final version = _auth?.sessionVersion;
    if (!_isCurrentSession(version) ||
        submitStatus == RatingSubmitStatus.submitting)
      return;
    final id = memberId;
    if (id == null) {
      submitStatus = RatingSubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해주세요.';
      notifyListeners();
      return;
    }
    final service = _ratingService;
    final currentMovie = movie;
    if (service == null || currentMovie == null) {
      submitStatus = RatingSubmitStatus.error;
      submitMessage = '평점 서비스와 영화 정보를 확인해 주세요.';
      notifyListeners();
      return;
    }
    submitStatus = RatingSubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();

    try {
      final request = CreateRatingRequest(
        movieId: currentMovie.id,
        score: score,
        comment: comment,
      );
      final result = await service.createRating(request); //viewmodel의 상태에 넣어준다.
      // 요청을 보낸 뒤 로그아웃하거나 회원이 바뀌었다면 결과를 버립니다.
      if (!_isCurrentSession(version)) return;
      myRating = result;
      submitStatus = RatingSubmitStatus.success;
    } on DioException catch (error) {
      if (!_isCurrentSession(version)) return;
      submitStatus = RatingSubmitStatus.error;
      submitMessage = writeErrorMessage(error);
    } catch (_) {
      if (!_isCurrentSession(version)) return;
      submitStatus = RatingSubmitStatus.error;
      submitMessage = '등록 결과를 확인하지 못했습니다. 평점 목록을 확인해 주세요.';
    }
    if (_isCurrentSession(version)) notifyListeners();
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
