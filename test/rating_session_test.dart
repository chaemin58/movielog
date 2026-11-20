import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/storage/token_storage.dart';
import 'package:movielog/service/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

class MemoryStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> deleteAccessToken() async {}
}

class PendingRatings extends RatingApiService {
  PendingRatings() : super(Dio(), Dio());
  final created = Completer<RatingDto>();
  final listed = Completer<List<RatingDto>>();
  final deleted = Completer<void>();
  int reads = 0;
  @override
  Future<RatingDto> createRating(CreateRatingRequest request) => created.future;
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) {
    reads++;
    return listed.future;
  }

  @override
  Future<void> deleteRating({required int memberId, required int ratingId}) =>
      deleted.future;
}

void main() {
  late AuthViewModel auth;
  late PendingRatings service;
  final rating = RatingDto(
    ratingId: 7,
    movieId: 123,
    score: 4,
    comment: '서버 결과',
    createdAt: DateTime(2026),
  );

  setUp(() {
    auth = AuthViewModel(
      AuthApiService(Dio()),
      MemberApiService(Dio()),
      MemoryStorage(),
    )..status = AuthStatus.signedIn;
    service = PendingRatings();
    addTearDown(auth.dispose);
  });

  for (final changeSession in [false, true]) {
    test(
      'create without learning member ID: session changed = $changeSession',
      () async {
        final vm = MovieDetailViewModel(
          TmdbMovieService(Dio()),
          ratingService: service,
          auth: auth,
        )..movie = TmdbMovieDetailDto.fromJson({'id': 123, 'title': '영화'});
        addTearDown(vm.dispose);
        expect(vm.canCreateRating, isTrue);
        final pending = vm.createRating(score: 4);
        if (changeSession) {
          await auth.logout();
          auth.status = AuthStatus.signedIn;
        }
        var notifications = 0;
        vm.addListener(() => notifications++);
        service.created.complete(rating);
        await pending;
        expect(vm.myRating, changeSession ? isNull : same(rating));
        expect(notifications, changeSession ? 0 : 1);
      },
    );
  }

  test('late list response is ignored after logout', () async {
    final vm = MyRatingsViewModel(
      service,
      TmdbMovieService(Dio()),
      1,
      auth: auth,
    );
    addTearDown(vm.dispose);
    final pending = vm.load();
    await auth.logout();
    var notifications = 0;
    vm.addListener(() => notifications++);
    service.listed.complete([rating]);
    await pending;
    expect(vm.ratings, isEmpty);
    expect(notifications, 0);
  });

  test('late delete success does not refresh the next session', () async {
    final vm = MyRatingsViewModel(
      service,
      TmdbMovieService(Dio()),
      1,
      auth: auth,
    );
    addTearDown(vm.dispose);
    final pending = vm.deleteRating(7);
    await auth.logout();
    auth.status = AuthStatus.signedIn;
    var notifications = 0;
    vm.addListener(() => notifications++);
    service.deleted.complete();
    await pending;
    expect(service.reads, 0);
    expect(notifications, 0);
  });
}
