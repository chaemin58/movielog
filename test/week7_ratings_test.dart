import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/widgets/movie_detail/movie_rating_dialog.dart';

class Movies extends TmdbMovieService {
  Movies() : super(Dio());
  @override
  Future<TmdbMovieDetailDto> fetchMovieDetail({required int movieId}) async =>
      TmdbMovieDetailDto.fromJson({'id': movieId, 'title': '영화'});
}

class Ratings extends RatingApiService {
  Ratings() : super(Dio());
  int writes = 0;
  int reads = 0;
  bool failRead = true;
  Completer<void>? pending;
  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    writes++;
    await pending?.future;
  }

  @override
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    writes++;
    await pending?.future;
  }

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    reads++;
    if (failRead) {
      throw DioException(requestOptions: RequestOptions(path: '/ratings'));
    }
    return [];
  }
}

void main() {
  test(
    'successful write with failed GET retries GET only and ends empty',
    () async {
      final service = Ratings();
      final vm = MyRatingsViewModel(service, Movies(), 42);
      addTearDown(vm.dispose);
      await vm.updateRating(ratingId: 7, score: 4, comment: null);
      expect(service.writes, 1);
      expect(vm.refreshWarning, contains('저장은 완료'));
      expect(vm.isWriting, false);
      service.failRead = false;
      await vm.load();
      expect(service.writes, 1);
      expect(service.reads, 2);
      expect(vm.refreshWarning, isNull);
      expect(vm.status, MyRatingsLoadStatus.empty);
    },
  );

  test(
    'duplicate writes blocked and disposal ignores late write results',
    () async {
      final service = Ratings()..pending = Completer<void>();
      final vm = MyRatingsViewModel(service, Movies(), 42);
      final first = vm.deleteRating(7);
      await expectLater(vm.deleteRating(7), throwsStateError);
      vm.dispose();
      service.pending!.complete();
      await first;
      expect(service.writes, 1);
      expect(service.reads, 0);
    },
  );

  test(
    'v6 paths, wrapper writes, null comment and empty DELETE body',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: options.method == 'DELETE'
                    ? 204
                    : options.method == 'POST'
                    ? 201
                    : 200,
                data: options.method == 'GET'
                    ? []
                    : options.method == 'DELETE'
                    ? null
                    : {
                        'isSuccess': true,
                        'code': 'OK',
                        'message': '완료',
                        'result': null,
                      },
              ),
            );
          },
        ),
      );
      final service = RatingApiService(dio);
      final detail = MovieDetailViewModel(
        Movies(),
        ratingService: service,
        memberId: 42,
      );
      addTearDown(detail.dispose);
      await detail.load(123);
      await detail.createRating(score: 5, comment: '좋아요');
      expect(detail.submitStatus, RatingSubmitStatus.success);
      expect(requests.first.path, '/v6/members/42/ratings');
      expect(requests.first.data['movieId'], 123);
      await service.updateRating(
        memberId: 42,
        ratingId: 7,
        score: 3,
        comment: '유지',
      );
      expect(requests.last.data['comment'], '유지');
      await service.updateRating(memberId: 42, ratingId: 7, score: 3);
      expect(requests.last.data, {'score': 3, 'comment': null});
      await service.deleteRating(memberId: 42, ratingId: 7);
      expect(requests.last.path, '/v6/members/42/ratings/7');
      expect(await service.fetchMyRatings(42), isEmpty);
    },
  );

  for (final status in [400, 403, 404, 409]) {
    test('server error $status is preserved', () {
      final options = RequestOptions(path: '/ratings');
      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: status,
          data: {'message': '오류 $status'},
        ),
      );
      expect(writeErrorMessage(error), '오류 $status');
      expect(
        shouldRefreshAfterRatingError(error),
        status == 403 || status == 404,
      );
    });
  }

  testWidgets(
    'dialog blocks exit during write and retains input after failure',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RatingDialog(
                    initialScore: 3,
                    initialComment: '기존 코멘트',
                    onSubmit: (score, comment) {
                      calls++;
                      return pending.future;
                    },
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '변경한 코멘트');
      await tester.tap(find.text('확인'));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(RatingDialog), findsOneWidget);
      expect(calls, 1);
      pending.completeError(StateError('저장 실패'));
      await tester.pumpAndSettle();
      expect(find.text('저장 실패'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '변경한 코멘트',
      );
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(RatingDialog), findsNothing);
    },
  );
}
