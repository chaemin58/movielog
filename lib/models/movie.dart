class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.type,
    required this.year,
    required this.runtimeMinutes,
    required this.posterAsset,
    required this.description,
    required this.rating,
    required this.ratingCount,
    required this.tags,
  });

  final int id;
  final String title;
  final String genre;
  final String type;
  final int year;
  final int runtimeMinutes;
  final String posterAsset;
  final String description;
  final double rating;
  final int ratingCount;
  final List<String> tags;
}

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '로맨스',
    type: '드라마',
    year: 2024,
    runtimeMinutes: 120,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    description: '별 헤는 밤, 서로 다른 상처를 지닌 두 사람이 우연히 마주친다. 짧은 하룻밤이지만 서로에게 남긴 위로는 오래도록 마음에 남는다.',
    rating: 4.5,
    ratingCount: 1245,
    tags: ['로맨스', '드라마', '감동적인'],
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    type: '영화',
    year: 2024,
    runtimeMinutes: 108,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    description: '인류 마지막 탐사선이 우주의 끝에서 발견한 것은 예상치 못한 진실이었다.',
    rating: 4.1,
    ratingCount: 532,
    tags: ['SF', '액션', '스릴있는'],
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
