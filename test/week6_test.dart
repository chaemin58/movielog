import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/screens/register_screen.dart';
import 'package:provider/provider.dart';

class CheckService extends MemberCheckService {
  CheckService() : super(Dio());
  final nickname = <Completer<bool>>[];
  final email = <Completer<bool>>[];
  @override
  Future<bool> checkNickname(String value) {
    final result = Completer<bool>();
    nickname.add(result);
    return result.future;
  }

  @override
  Future<bool> checkEmail(String value) {
    final result = Completer<bool>();
    email.add(result);
    return result.future;
  }
}

class RatingsService extends RatingApiService {
  RatingsService() : super(Dio());
  List<RatingDto> result = [];
  DioException? error;
  int? requestedId;
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    requestedId = memberId;
    if (error != null) throw error!;
    return result;
  }
}

class MissingMovieService extends TmdbMovieService {
  MissingMovieService() : super(Dio());
  int calls = 0;
  @override
  Future<TmdbMovieDetailDto> fetchMovieDetail({required int movieId}) async {
    calls++;
    throw DioException(requestOptions: RequestOptions(path: '/movie/$movieId'));
  }
}

void main() {
  testWidgets(
    'signup shows server errors, restores duplicates and clears availability',
    (tester) async {
      final service = CheckService();
      final vm = SignUpViewModel(service);
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );
      final nickname = find.byType(TextFormField).at(0);
      await tester.enterText(nickname, '중복닉네임');
      await tester.pump();
      await tester.tap(find.text('중복 확인').first);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      service.nickname.single.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      await tester.enterText(nickname, '새닉네임');
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
      await tester.enterText(nickname, '중복닉네임');
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(service.nickname.length, 1);
      await tester.enterText(nickname, '새닉네임');
      await tester.pump();
      await tester.tap(find.text('중복 확인').first);
      await tester.pump();
      service.nickname.last.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
      await tester.enterText(nickname, '변경닉네임');
      await tester.pumpAndSettle();
      expect(find.text('사용 가능한 닉네임입니다.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final isEmail in [false, true]) {
    test(
      '${isEmail ? 'email' : 'nickname'} invalidates old responses and restores duplicates',
      () async {
        final service = CheckService();
        final vm = SignUpViewModel(service);
        addTearDown(vm.dispose);
        final change = isEmail ? vm.onEmailChanged : vm.onNicknameChanged;
        final check = isEmail ? vm.checkEmail : vm.checkNickname;
        final requests = isEmail ? service.email : service.nickname;
        CheckStatus status() =>
            isEmail ? vm.emailCheckStatus : vm.nicknameCheckStatus;
        const first = 'first@example.com';
        const second = 'second@example.com';
        change(first);
        final old = check(first);
        expect(status(), CheckStatus.checking);
        change(second);
        requests[0].complete(true);
        await old;
        expect(status(), CheckStatus.idle);
        final current = check(second);
        requests[1].complete(false);
        await current;
        expect(status(), CheckStatus.duplicated);
        change(first);
        expect(status(), CheckStatus.idle);
        change(' $second ');
        expect(status(), CheckStatus.duplicated);
        await check(second);
        expect(requests.length, 2);
      },
    );
  }
  test('checks are independent; errors retry and disposal ignores pending response', () async {
    final service = CheckService();
    final vm = SignUpViewModel(service);
    vm.onNicknameChanged('닉네임');
    vm.onEmailChanged('a@example.com');
    final nickname = vm.checkNickname('닉네임');
    final email = vm.checkEmail('a@example.com');
    service.nickname.single.complete(true);
    await nickname;
    expect(vm.nicknameCheckStatus, CheckStatus.available);
    expect(vm.emailCheckStatus, CheckStatus.checking);
    service.email.single.completeError(
      DioException(requestOptions: RequestOptions()),
    );
    await email;
    expect(vm.emailCheckStatus, CheckStatus.error);
    expect(vm.canCheckEmail, true);
    final retry = vm.checkEmail('a@example.com');
    vm.dispose();
    service.email.last.complete(true);
    await retry;
  });
  test('ratings parse nullable comments; empty, success, metadata fallback and HTTP errors', () async {
    final service = RatingsService();
    final movies = MissingMovieService();
    final vm = MyRatingsViewModel(service, movies);
    addTearDown(vm.dispose);
    final first = vm.load();
    expect(vm.status, MyRatingsLoadStatus.loading);
    await first;
    expect(service.requestedId, 1);
    expect(vm.status, MyRatingsLoadStatus.empty);
    final rating = RatingDto.fromJson({
      'ratingId': 12,
      'movieId': 550,
      'score': 5,
      'comment': null,
      'createdAt': '2026-09-06T12:14:03.000Z',
    });
    service.result = [rating, rating];
    await vm.load();
    expect(vm.status, MyRatingsLoadStatus.success);
    expect(vm.ratings.length, 2);
    expect(vm.ratings.first.movie, isNull);
    expect(movies.calls, 1);
    await vm.load();
    expect(movies.calls, 2);
    for (final code in [400, 404, 500]) {
      final options = RequestOptions();
      service.error = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: code),
      );
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.error);
      expect(vm.message, writeMyRatingsErrorMessage(service.error!));
    }
  });
  testWidgets('button widths, loading indicator and disabled taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: Column(
              children: [
                MovieLogButton(label: '내용', onPressed: () => taps++),
                MovieLogButton(
                  label: '전체',
                  width: double.infinity,
                  onPressed: () => taps++,
                ),
                MovieLogButton(
                  label: '고정',
                  width: 120,
                  onPressed: () => taps++,
                ),
                MovieLogButton(
                  label: '로딩',
                  isLoading: true,
                  onPressed: () => taps++,
                ),
                const MovieLogButton(label: '비활성', onPressed: null),
              ],
            ),
          ),
        ),
      ),
    );
    final buttons = find.byType(MovieLogButton);
    expect(tester.getSize(buttons.at(0)).width, lessThan(320));
    expect(tester.getSize(buttons.at(1)).width, 320);
    expect(tester.getSize(buttons.at(2)).width, 120);
    expect(find.text('로딩'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(buttons.at(3));
    await tester.tap(buttons.at(4));
    expect(taps, 0);
    await tester.tap(buttons.at(0));
    expect(taps, 1);
  });
}
