class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });

  factory FavoriteResponseDto.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('FavoriteResponseDto must be a JSON object.');
    }
    return FavoriteResponseDto(
      favoriteId: (json['favoriteId']),
      movieId: json['movieId'],
      createdAt: json['createdAt'],
    );
  }
  final int favoriteId;
  final int movieId;
  final DateTime createdAt;
}
