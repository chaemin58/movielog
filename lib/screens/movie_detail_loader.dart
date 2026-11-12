import 'package:flutter/material.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_detail_page.dart';
import 'package:movielog/service/rating_api_service.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:provider/provider.dart';

//영화 상세 화면을 보여주기 전에 필요한 영화 데이터를 준비하는 위젯
//상세 화면에 진입할 때 전달받은 영화 데이터가 있는지 확인하고 있다면 그 데이터를 사용하고 없다면 movieId로 서버에서 조회한다.
class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });
  final int movieId;
  final TmdbMovieDto? initialMovie;
  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late final Future<TmdbMovieDetailDto> _movieFuture;
  @override
  void initState() {
    super.initState();
    // 목록 DTO에는 상세 정보가 없으므로 상세 API로 조회합니다.
    _movieFuture = context.read<TmdbMovieService>().fetchMovieDetail(
      movieId: widget.movieId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbMovieDetailDto>(
      future: _movieFuture, // build마다 새 Future를 만들지 않습니다.
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('영화 정보를 불러오지 못했어요.')));
        }
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) =>
              MovieDetailViewModel(
                  context.read<TmdbMovieService>(),
                  ratingService: context.read<RatingApiService>(),
                  memberId: context.read<LearningMemberSession>().memberId,
                )
                ..movie = snapshot.data!
                ..status = MovieDetailLoadStatus.success,
          child: MovieDetailPage(movieId: widget.movieId.toString()),
        );
      },
    );
  }
}
