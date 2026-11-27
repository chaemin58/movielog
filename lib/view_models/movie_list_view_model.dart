import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/service/genre_preference.dart';

import 'paged_movies_view_model.dart';
import 'load_phase.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends PagedMoviesViewModel {
  MovieListViewModel(super.service, {GenrePreference? genrePreference})
    : _genrePreference = genrePreference ?? GenrePreference();
  final GenrePreference _genrePreference;
  List<TmdbGenreDto> genres = [];
  int? selectedGenreId;
  int _genreGeneration = 0;
  bool _initialized = false;
  MovieListLoadStatus get status => switch (phase) {
    LoadPhase.idle => MovieListLoadStatus.idle,
    LoadPhase.loading => MovieListLoadStatus.loading,
    LoadPhase.ready => MovieListLoadStatus.success,
    LoadPhase.empty => MovieListLoadStatus.empty,
    LoadPhase.error => MovieListLoadStatus.error,
  };
  set status(MovieListLoadStatus value) => phase = switch (value) {
    MovieListLoadStatus.idle => LoadPhase.idle,
    MovieListLoadStatus.loading => LoadPhase.loading,
    MovieListLoadStatus.success => LoadPhase.ready,
    MovieListLoadStatus.empty => LoadPhase.empty,
    MovieListLoadStatus.error => LoadPhase.error,
  };

  @override
  Future<void> loadInitial({int? genreId, String query = ''}) async {
    final generation = ++_genreGeneration;
    if (!_initialized) {
      phase = LoadPhase.loading;
      notifyIfAlive();
      try {
        final fetched = await service.fetchGenres();
        final saved = await _genrePreference.read();
        if (isDisposed || generation != _genreGeneration) return;
        genres = fetched;
        selectedGenreId = genres
            .where((genre) => genre.name == saved)
            .firstOrNull
            ?.id;
        _initialized = true;
      } catch (_) {
        if (isDisposed || generation != _genreGeneration) return;
        phase = LoadPhase.error;
        message = '장르를 불러오지 못했어요. 다시 시도해 주세요.';
        notifyIfAlive();
        return;
      }
    }
    await super.loadInitial(genreId: selectedGenreId);
  }

  Future<void> selectGenre(int? genreId) async {
    _genreGeneration++;
    selectedGenreId = genreId;
    final request = super.loadInitial(genreId: genreId);
    final name = genres.where((genre) => genre.id == genreId).firstOrNull?.name;
    try {
      await _genrePreference.save(name ?? '전체');
    } catch (_) {
      // Local preference failure must not block the movie request.
    }
    await request;
  }
}
