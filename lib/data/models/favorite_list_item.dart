import 'favorite_response_dto.dart';
import 'tmdb_movie_dto.dart';

class FavoriteListItem {
  const FavoriteListItem(this.favorite, this.movie);
  final FavoriteResponseDto favorite;
  final TmdbMovieDto? movie;
}
