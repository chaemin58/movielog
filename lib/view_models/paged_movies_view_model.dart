import 'package:flutter/foundation.dart';
import 'package:movielog/core/utils/safe_notify.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

import 'load_phase.dart';

class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel(this.service, {this.isSearch = false});
  final TmdbMovieService service;
  final bool isSearch;
  List<TmdbMovieDto> movies = [];
  LoadPhase phase = LoadPhase.idle;
  String? message;
  String? loadMoreError;
  bool isLoadingMore = false;
  int nextPage = 1;
  int totalPages = 0;
  int _generation = 0;
  ({int? genreId, String query}) condition = (genreId: null, query: '');
  bool get hasMore => nextPage <= totalPages;

  Future<void> loadInitial({int? genreId, String query = ''}) async {
    if (isDisposed) return;
    final generation = ++_generation;
    condition = (genreId: genreId, query: query.trim());
    movies = [];
    nextPage = 1;
    totalPages = 0;
    isLoadingMore = false;
    loadMoreError = null;
    message = null;
    phase = isSearch && condition.query.isEmpty
        ? LoadPhase.idle
        : LoadPhase.loading;
    notifyIfAlive();
    if (phase == LoadPhase.idle) return;
    await _fetch(generation, 1);
  }

  Future<void> retry() =>
      loadInitial(genreId: condition.genreId, query: condition.query);

  Future<void> loadNextPage() async {
    if (isDisposed || phase != LoadPhase.ready || isLoadingMore || !hasMore) {
      return;
    }
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();
    await _fetch(_generation, nextPage);
  }

  Future<void> _fetch(int generation, int page) async {
    bool current() => !isDisposed && generation == _generation;
    try {
      final result = isSearch
          ? await service.searchMovies(query: condition.query, page: page)
          : await service.discoverMovies(
              page: page,
              genreId: condition.genreId,
            );
      if (!current()) return;
      final byId = {for (final movie in movies) movie.id: movie};
      for (final movie in result.results) {
        byId.putIfAbsent(movie.id, () => movie);
      }
      movies = byId.values.toList();
      totalPages = result.totalPages.clamp(0, 500);
      nextPage = page + 1;
      if (result.results.isEmpty) totalPages = page;
      phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (_) {
      if (!current()) return;
      if (page == 1) {
        phase = LoadPhase.error;
        message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
      } else {
        loadMoreError = '다음 페이지를 불러오지 못했어요.';
      }
    } finally {
      if (current()) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }
}
