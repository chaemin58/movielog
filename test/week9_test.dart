import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/service/favorite_api_service.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';

TmdbMoviePageDto page(int number, List<int> ids) => TmdbMoviePageDto(
  page: number,
  results: ids
      .map((id) => TmdbMovieDto.fromJson({'id': id, 'title': '영화 $id'}))
      .toList(),
  totalPages: 3,
  totalResults: 6,
);

class PendingMovies extends TmdbMovieService {
  PendingMovies() : super(Dio());
  final calls =
      <
        ({
          int page,
          String query,
          int? genre,
          Completer<TmdbMoviePageDto> result,
        })
      >[];
  @override
  Future<TmdbMoviePageDto> discoverMovies({required int page, int? genreId}) {
    final result = Completer<TmdbMoviePageDto>();
    calls.add((page: page, query: '', genre: genreId, result: result));
    return result.future;
  }

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required String query,
    required int page,
  }) {
    final result = Completer<TmdbMoviePageDto>();
    calls.add((page: page, query: query, genre: null, result: result));
    return result.future;
  }

  bool failDetail = true;
  @override
  Future<TmdbMovieDetailDto> fetchMovieDetail({required int movieId}) async {
    if (movieId == 2 && failDetail) throw StateError('offline');
    return TmdbMovieDetailDto.fromJson({'id': movieId, 'title': '영화 $movieId'});
  }
}

Dio favoriteDio({
  List<int> ids = const [1, 2],
  String? mutationError,
  bool check = false,
  List<RequestOptions>? requests,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) {
        requests?.add(o);
        if (o.method == 'POST' && mutationError != null) {
          h.reject(
            DioException(
              requestOptions: o,
              response: Response(
                requestOptions: o,
                statusCode: 409,
                data: {'code': mutationError},
              ),
            ),
          );
          return;
        }
        final result = o.method == 'DELETE'
            ? null
            : o.path == '/v8/favorites' && o.method == 'GET'
            ? ids
                  .map(
                    (id) => {
                      'favoriteId': id + 10,
                      'movieId': id,
                      'createdAt': '2026-11-27T00:00:00Z',
                    },
                  )
                  .toList()
            : o.method == 'POST'
            ? {
                'favoriteId': 11,
                'movieId': 1,
                'createdAt': '2026-11-27T00:00:00Z',
              }
            : {'isFavorite': check};
        h.resolve(
          Response(
            requestOptions: o,
            statusCode: o.method == 'POST' ? 201 : 200,
            data: {
              'isSuccess': true,
              'code': 'COMMON200',
              'message': 'ok',
              'result': result,
            },
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  test(
    'pagination preserves cards, retries same page, deduplicates and stops',
    () async {
      final api = PendingMovies();
      final vm = PagedMoviesViewModel(api);
      addTearDown(vm.dispose);
      final first = vm.loadInitial();
      api.calls.last.result.complete(page(1, [1, 2]));
      await first;
      final next = vm.loadNextPage();
      await vm.loadNextPage();
      expect(api.calls.length, 2);
      expect(vm.movies.length, 2);
      api.calls.last.result.completeError(StateError('offline'));
      await next;
      expect(vm.nextPage, 2);
      expect(vm.loadMoreError, isNotNull);
      final retry = vm.loadNextPage();
      expect(api.calls.last.page, 2);
      api.calls.last.result.complete(page(2, [2, 3]));
      await retry;
      expect(vm.movies.map((m) => m.id), [1, 2, 3]);
      final last = vm.loadNextPage();
      api.calls.last.result.complete(page(3, [4]));
      await last;
      expect(vm.hasMore, false);
    },
  );
  test('new genre ignores old load-more errors and finally', () async {
    final api = PendingMovies();
    final vm = PagedMoviesViewModel(api);
    addTearDown(vm.dispose);
    final first = vm.loadInitial(genreId: 1);
    api.calls.last.result.complete(page(1, [1]));
    await first;
    final old = vm.loadNextPage();
    final oldResult = api.calls.last.result;
    final fresh = vm.loadInitial(genreId: 2);
    expect(vm.movies, isEmpty);
    oldResult.completeError(StateError('late'));
    await old;
    expect(vm.phase, LoadPhase.loading);
    expect(vm.loadMoreError, isNull);
    api.calls.last.result.complete(page(1, [9]));
    await fresh;
    expect(vm.movies.single.id, 9);
  });
  test(
    'search trims, rejects empty, ignores stale results and disposed requests',
    () async {
      final api = PendingMovies();
      final vm = PagedMoviesViewModel(api, isSearch: true);
      await vm.loadInitial(query: '   ');
      expect(api.calls, isEmpty);
      final old = vm.loadInitial(query: ' old ');
      final result = api.calls.last.result;
      expect(api.calls.last.query, 'old');
      final fresh = vm.loadInitial(query: 'new');
      api.calls.last.result.complete(page(1, [7]));
      await fresh;
      result.complete(page(1, [1]));
      await old;
      expect(vm.movies.single.id, 7);
      final pending = vm.loadNextPage();
      vm.dispose();
      api.calls.last.result.complete(page(2, [8]));
      await pending;
      expect(vm.movies.single.id, 7);
    },
  );
  test(
    'favorite contract uses movieId, parses dates and accepts null DELETE',
    () async {
      final requests = <RequestOptions>[];
      final api = FavoriteApiService(favoriteDio(requests: requests));
      expect(
        (await api.fetchMyFavorites()).first.createdAt,
        DateTime.utc(2026, 11, 27),
      );
      expect((await api.addFavorite(movieId: 1)).movieId, 1);
      expect((await api.checkFavorite(movieId: 1)).movieId, 1);
      await api.deleteFavorite(movieId: 1);
      expect(requests.last.path, '/v8/favorites/1');
      expect(requests.last.data, isNull);
    },
  );
  test(
    'favorite conflict synchronizes with GET without repeating POST',
    () async {
      final requests = <RequestOptions>[];
      final guard = SessionGuard()..startSession('a');
      final vm = FavoriteDetailViewModel(
        movieId: 1,
        favoriteApi: FavoriteApiService(
          favoriteDio(
            mutationError: 'FAVORITE409_1',
            check: true,
            requests: requests,
          ),
        ),
        sessionGuard: guard,
        accountId: 'a',
      );
      addTearDown(vm.dispose);
      vm.hasLoadedStatus = true;
      await vm.toggle();
      expect(vm.isFavorite, true);
      expect(vm.errorMessage, isNull);
      expect(requests.map((r) => r.method), ['POST', 'GET']);
      guard.startSession('a');
      await vm.toggle();
      expect(requests.length, 2);
    },
  );
  test('favorites preserve partial failures, retry one card, refresh removal and reject old session', () async {
    final ids = [1, 2];
    final guard = SessionGuard()..startSession('a');
    final movies = PendingMovies();
    final vm = FavoritesViewModel(
      FavoriteApiService(favoriteDio(ids: ids)),
      movies,
      guard,
      'a',
    );
    addTearDown(vm.dispose);
    await vm.refresh();
    expect(vm.phase, LoadPhase.ready);
    expect(vm.items.last.movie, isNull);
    movies.failDetail = false;
    await vm.retryMovie(vm.items.last);
    expect(vm.items.last.movie!.id, 2);
    ids.remove(1);
    await vm.refresh();
    expect(vm.items.single.movie!.id, 2);
    ids.clear();
    await vm.refresh();
    expect(vm.phase, LoadPhase.empty);
    guard.startSession('b');
    await vm.refresh();
    expect(vm.items, isEmpty);
  });
  test('bounded enrichment never exceeds five concurrent requests and preserves order', () async {
    var active = 0;
    var maximum = 0;
    final result = await mapBounded(List.generate(100, (i) => i), (
      int i,
    ) async {
      active++;
      if (active > maximum) maximum = active;
      await Future<void>.delayed(Duration.zero);
      active--;
      return i;
    });
    expect(maximum, 5);
    expect(result, List.generate(100, (i) => i));
  });
}
