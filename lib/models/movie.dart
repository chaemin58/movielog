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
    description: "바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다. 과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데... 별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.",
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
