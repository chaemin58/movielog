import 'package:shared_preferences/shared_preferences.dart';

class MovieRatingPreference {
  MovieRatingPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  String _key(int movieId) => 'movie_rating_$movieId';

  Future<double?> read(int movieId) {
    return _preferences.getDouble(_key(movieId));
  }

  Future<void> save(int movieId, double rating) {
    if (movieId <= 0 ||
        !rating.isFinite ||
        rating < 0.5 ||
        rating > 5 ||
        rating * 2 != (rating * 2).roundToDouble()) {
      throw ArgumentError('유효한 영화 ID와 0.5 단위의 평점이 필요합니다.');
    }
    return _preferences.setDouble(_key(movieId), rating);
  }
}
