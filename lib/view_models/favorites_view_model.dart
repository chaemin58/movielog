import 'package:movielog/core/network/favorite_error_message.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/core/utils/safe_notify.dart';
import 'package:movielog/data/models/favorite_list_item.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/service/favorite_api_service.dart';

import 'load_phase.dart';

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel(this.api, this.movies, this.guard, this.accountId)
    : _session = guard.generation;
  final FavoriteApiService api;
  final TmdbMovieService movies;
  final SessionGuard guard;
  final String accountId;
  final int _session;
  int _generation = 0;
  List<FavoriteListItem> items = [];
  final Set<int> retrying = {};
  LoadPhase phase = LoadPhase.idle;
  String? errorMessage;
  bool _current(int generation) =>
      !isDisposed &&
      generation == _generation &&
      guard.isCurrent(_session, accountId);

  Future<FavoriteListItem> _enrich(FavoriteResponseDto favorite) async {
    try {
      final movie = await movies.fetchMovieDetail(movieId: favorite.movieId);
      return FavoriteListItem(
        favorite,
        TmdbMovieDto(
          id: movie.id,
          title: movie.title,
          overview: movie.overview,
          posterPath: movie.posterPath,
          backdropPath: null,
          releaseDate: movie.releaseDate,
          genreIds: movie.genres.map((genre) => genre.id).toList(),
          voteAverage: movie.voteAverage,
          popularity: 0,
        ),
      );
    } catch (_) {
      return FavoriteListItem(favorite, null);
    }
  }

  Future<void> refresh() async {
    if (!_current(_generation)) return;
    final generation = ++_generation;
    items = [];
    retrying.clear();
    errorMessage = null;
    phase = LoadPhase.loading;
    notifyIfAlive();
    try {
      final favorites = await api.fetchMyFavorites();
      if (!_current(generation)) return;
      final enriched = await mapBounded(favorites, (favorite) async {
        if (!_current(generation)) return FavoriteListItem(favorite, null);
        return _enrich(favorite);
      });
      if (!_current(generation)) return;
      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (error) {
      if (!_current(generation)) return;
      errorMessage = favoriteErrorMessage(error);
      phase = LoadPhase.error;
    }
    if (_current(generation)) notifyIfAlive();
  }

  Future<void> retryMovie(FavoriteListItem item) async {
    final generation = _generation;
    if (!_current(generation) || !retrying.add(item.favorite.movieId)) return;
    notifyIfAlive();
    final result = await _enrich(item.favorite);
    if (!_current(generation)) return;
    items = items
        .map(
          (old) => old.favorite.movieId == item.favorite.movieId ? result : old,
        )
        .toList();
    retrying.remove(item.favorite.movieId);
    notifyIfAlive();
  }
}
