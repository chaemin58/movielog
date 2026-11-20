import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/service/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this.memberId, {
    AuthViewModel? auth,
  }) : _auth = auth,
       _sessionVersion = auth?.sessionVersion;

  final AuthViewModel? _auth;
  final int? _sessionVersion;
  bool get isSessionActive => !_inactive;
  // 이 목록 화면을 만든 세션이 끝났다면 늦은 응답을 반영하지 않습니다.
  bool get _inactive =>
      _disposed ||
      (_auth != null &&
          (_auth.sessionVersion != _sessionVersion ||
              _auth.status != AuthStatus.signedIn));

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDetailDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  String? refreshWarning;
  bool isWriting = false;

  //load()로 재조회
  Future<void> _refreshAfterWrite() async {
    await load();
    if (_inactive) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      notifyListeners();
    } else {
      refreshWarning = null;
    }
  }

  //평점 수정
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await _writeAndRefresh(
        () => _service.updateRating(
          memberId: memberId,
          ratingId: ratingId,
          score: score,
          comment: comment,
        ),
      );
    } on DioException catch (error) {
      if (_inactive) return;
      message = writeErrorMessage(error);
      notifyListeners();
      if (shouldRefreshAfterRatingError(error)) await load();
      if (_inactive) return;
      rethrow;
    }
    if (_inactive) return;
    await _refreshAfterWrite(); // GET 실패는 저장 실패로 다시 던지지 않습니다.
  }

  //평점 삭제
  Future<void> deleteRating(int ratingId) async {
    try {
      await _writeAndRefresh(
        () => _service.deleteRating(memberId: memberId, ratingId: ratingId),
      );
    } on DioException catch (error) {
      if (_inactive) return;
      message = writeErrorMessage(error);
      notifyListeners();
      if (shouldRefreshAfterRatingError(error)) await load();
      if (_inactive) return;
      rethrow;
    }
    if (_inactive) return;
    await _refreshAfterWrite();
  }

  Future<void> _writeAndRefresh(Future<void> Function() write) async {
    if (_inactive || isWriting) throw StateError('이미 처리 중이거나 종료된 화면입니다.');
    isWriting = true;
    _requestVersion++; // 쓰기 전에 시작한 GET 결과를 무효화합니다.
    notifyListeners();
    try {
      try {
        await write();
      } on DioException catch (error) {
        if (!_inactive && shouldRefreshAfterRatingError(error)) {
          await load(afterWrite: true);
        }
        rethrow; // 쓰기 실패만 Dialog로 전달합니다.
      }
      if (_inactive) return;
      await load(afterWrite: true);
      if (_inactive) return;
      if (status == MyRatingsLoadStatus.error) {
        refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      }
    } finally {
      if (!_inactive) {
        isWriting = false;
        notifyListeners();
      }
    }
  }

  Future<void> load({bool afterWrite = false}) async {
    if (_inactive || (isWriting && !afterWrite)) return;
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
      if (_inactive || version != _requestVersion) return;
      // 나중에 사용할 객체를 넣을 리스트
      final entries = <RatingWithMovie>[];
      for (final rating in rawRatings) {
        if (_inactive || version != _requestVersion) return;

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
          if (_inactive || version != _requestVersion) return;
          _movieCache[rating.movieId] = movie;
        }

        //아까 만든 빈 객체였던 곳에 밀어 넣음.
        entries.add(
          RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
        );
      }
      if (_inactive || version != _requestVersion) return;
      ratings = entries;
      refreshWarning = null;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (entries.any((entry) => entry.movie == null)) {
        message = '일부 영화 정보를 불러오지 못했습니다. 평점 기록은 그대로 표시합니다.';
      }
    } on DioException catch (error) {
      if (_inactive || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } on FormatException {
      if (_inactive || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 데이터 형식을 확인할 수 없습니다.';
    } on TypeError {
      if (_inactive || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 데이터 형식을 확인할 수 없습니다.';
    } catch (_) {
      if (_inactive || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '목록을 불러오지 못했습니다. 조회를 다시 시도해 주세요.';
    }
    if (!_inactive && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
