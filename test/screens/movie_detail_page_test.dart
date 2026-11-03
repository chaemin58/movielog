import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_detail_page.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> detailJson() => {
  'id': 123,
  'title': '상세 API 영화',
  'overview': 'API로 받은 줄거리입니다.',
  'poster_path': null,
  'release_date': '2026-10-27',
  'runtime': 115,
  'genres': [
    {'id': 28, 'name': '액션'},
  ],
  'vote_average': 8.2,
  'vote_count': 1234,
};

class PendingDetailService extends TmdbMovieService {
  PendingDetailService() : super(Dio());

  Completer<TmdbMovieDetailDto> response = Completer();
  final requestedIds = <int>[];

  @override
  Future<TmdbMovieDetailDto> fetchMovieDetail({required int movieId}) {
    requestedIds.add(movieId);
    return response.future;
  }
}

void main() {
  test(
    'service requests the movie ID in Korean and parses detail fields',
    () async {
      final dio = Dio();
      RequestOptions? request;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response(requestOptions: options, data: detailJson()),
            );
          },
        ),
      );

      final movie = await TmdbMovieService(dio).fetchMovieDetail(movieId: 123);
      expect(request!.path, '/movie/123');
      expect(request!.queryParameters['language'], 'ko-KR');
      expect(movie.genres.single.name, '액션');
      expect(movie.runtime, 115);
      expect(movie.voteCount, 1234);
      expect(movie.posterPath, isNull);
    },
  );

  Future<void> mount(WidgetTester tester, PendingDetailService service) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<MovieDetailViewModel>(
        create: (_) => MovieDetailViewModel(service)..load(123),
        child: const MaterialApp(home: MovieDetailPage(movieId: '123')),
      ),
    );
  }

  testWidgets(
    'shows loading followed by API detail and missing-poster placeholder',
    (tester) async {
      final service = PendingDetailService();
      await mount(tester, service);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(service.requestedIds, [123]);

      service.response.complete(TmdbMovieDetailDto.fromJson(detailJson()));
      await tester.pumpAndSettle();
      expect(find.text('상세 API 영화'), findsOneWidget);
      expect(find.text('2026 · 액션 · 115분'), findsOneWidget);
      expect(find.text('4.1 (1,234)'), findsOneWidget);
      expect(find.text('API로 받은 줄거리입니다.'), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows failure and retries the same movie ID', (tester) async {
    final service = PendingDetailService();
    await mount(tester, service);
    service.response.completeError(
      DioException(requestOptions: RequestOptions(path: '/movie/123')),
    );
    await tester.pumpAndSettle();
    expect(find.text('영화 정보를 불러오지 못했어요.'), findsOneWidget);

    service.response = Completer();
    await tester.tap(find.text('다시 시도하기'));
    await tester.pump();
    expect(service.requestedIds, [123, 123]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    service.response.complete(TmdbMovieDetailDto.fromJson(detailJson()));
    await tester.pumpAndSettle();
    expect(find.text('상세 API 영화'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects an invalid ID before reading a view model', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieDetailPage(movieId: 'invalid')),
    );
    expect(find.text('잘못된 영화 ID입니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('does not notify after leaving while a request is pending', () async {
    final service = PendingDetailService();
    final viewModel = MovieDetailViewModel(service);
    var notifications = 0;
    viewModel.addListener(() => notifications++);
    final request = viewModel.load(123);
    expect(notifications, 1);
    viewModel.dispose();
    service.response.complete(TmdbMovieDetailDto.fromJson(detailJson()));
    await request;
    expect(notifications, 1);
  });
}
