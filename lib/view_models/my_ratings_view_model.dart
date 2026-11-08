import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

//하드코딩
const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDetailDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_requestVersion;
    //일단 로드되면 먼저 로딩 상태로 만듦.
    status = MyRatingsLoadStatus.loading;
    message = null;
    //로딩 상태가 되었으니 알려야 한다.
    notifyListeners();

    try {
      //서버에서 가져오기
      final rawRatings = await _service.fetchMyRatings(memberId);
      //뭔가 안맞으면 얼리 리턴
      if (_disposed || version != _requestVersion) return;
      // 나중에 사용할 객체를 넣을 리스트
      final entries = <RatingWithMovie>[];
      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;

        //이미 불러왔던 정보를 캐싱을 해놓는다는 개념
        if (!_movieCache.containsKey(rating.movieId)) {
          TmdbMovieDetailDto? movie;
          try {
            //평점 데이터 안에 있는 movieId로 영화 정보를 가져온다.
            movie = await _movieService.findMovieById(rating.movieId);
          } on DioException {
            movie = null;
          } on FormatException {
            movie = null;
          } on TypeError {
            movie = null;
          } //!!!! 영화 조회 중 문제가 발생하면 그냥 movie를 null로 만들어서 영화 정보 없이 평점 기록은 보여주려는 처리
          if (_disposed || version != _requestVersion) return;
          _movieCache[rating.movieId] = movie;
        }

        //아까 만든 빈 객체였던 곳에 밀어 넣음.
        entries.add(
          RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
        );
      }
      if (_disposed || version != _requestVersion) return;
      ratings = entries;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (entries.any((entry) => entry.movie == null)) {
        message = '일부 영화 정보를 불러오지 못했습니다. 평점 기록은 그대로 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } on FormatException {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 데이터 형식을 확인할 수 없습니다.';
    } on TypeError {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 데이터 형식을 확인할 수 없습니다.';
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
