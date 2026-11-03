import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService, [
    this.memberId = sampleMemberId,
  ]);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDetailDto?> _movieCache = {};
  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  int _version = 0;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_version;
    bool isCurrent() => !_disposed && version == _version;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final raw = await _service.fetchMyRatings(memberId);
      if (!isCurrent()) return;
      final movies = <int, TmdbMovieDetailDto?>{};
      await Future.wait(
        raw.map((r) => r.movieId).toSet().map((id) async {
          if (_movieCache.containsKey(id)) {
            movies[id] = _movieCache[id];
            return;
          }
          try {
            final movie = await _movieService.fetchMovieDetail(movieId: id);
            if (!isCurrent()) return;
            movies[id] = movie;
            _movieCache[id] = movie;
          } on DioException catch (error) {
            if (isCurrent() && error.response?.statusCode == 404) {
              _movieCache[id] = null;
            }
          } catch (_) {
            // Movie metadata is optional: retain the original rating on failure.
          }
        }),
      );
      if (!isCurrent()) return;
      ratings = raw
          .map((r) => RatingWithMovie(rating: r, movie: movies[r.movieId]))
          .toList();
      status = ratings.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (ratings.any((r) => r.movie == null)) {
        message = '일부 영화 정보를 불러오지 못했습니다.';
      }
    } catch (error) {
      if (!isCurrent()) return;
      status = MyRatingsLoadStatus.error;
      message = error is DioException
          ? writeMyRatingsErrorMessage(error)
          : '평점 응답을 읽지 못했습니다. 다시 시도해 주세요.';
    }
    if (isCurrent()) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
