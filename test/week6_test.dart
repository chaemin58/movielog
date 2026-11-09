import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/service/sign_up_service.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/register_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/common/custom_button.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class PendingChecks extends SignUpService {
  PendingChecks() : super(Dio());
  final nicknames = <Completer<bool>>[];
  final emails = <Completer<bool>>[];
  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async => CommonResponse(
    isSuccess: true,
    code: 'COMMON201',
    message: '완료',
    result: SignUpResult(
      memberId: 42,
      email: request.email,
      nickname: request.nickname,
    ),
  );
  @override
  Future<bool> checkNickname(String nickname) {
    final pending = Completer<bool>();
    nicknames.add(pending);
    return pending.future;
  }

  @override
  Future<bool> checkEmail(String email) {
    final pending = Completer<bool>();
    emails.add(pending);
    return pending.future;
  }
}

class PendingRatings extends RatingApiService {
  PendingRatings() : super(Dio());
  final requests = <Completer<List<RatingDto>>>[];
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) {
    expect(memberId, 1);
    final pending = Completer<List<RatingDto>>();
    requests.add(pending);
    return pending.future;
  }
}

class FakeMovies extends TmdbMovieService {
  FakeMovies() : super(Dio());
  final ids = <int>[];
  @override
  Future<TmdbMovieDetailDto?> findMovieById(int movieId) async {
    ids.add(movieId);
    if (movieId == 404) {
      throw DioException(requestOptions: RequestOptions(path: '/movie/404'));
    }
    return TmdbMovieDetailDto.fromJson({'id': movieId, 'title': '테스트 영화'});
  }
}

RatingDto rating(int id, int movieId, {String? comment}) => RatingDto.fromJson({
  'ratingId': id,
  'movieId': movieId,
  'score': 5,
  'comment': comment,
  'createdAt': '2026-09-06T12:14:03.000Z',
});

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_WEEK6')) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/week6-preview');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    const fontPath = String.fromEnvironment('KOREAN_TEST_FONT');
    const iconPath = String.fromEnvironment('ICON_TEST_FONT');
    if (fontPath.isNotEmpty) {
      final font = FontLoader('Manrope')
        ..addFont(
          File(fontPath)
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      await font.load();
      final fallback = FontLoader('Roboto')
        ..addFont(
          File(fontPath)
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      await fallback.load();
    }
    if (iconPath.isNotEmpty) {
      final font = FontLoader('MaterialIcons')
        ..addFont(
          File(iconPath)
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      await font.load();
    }
  });
  testWidgets(
    'common button supports content, full, fixed widths and loading',
    (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('내용 너비 (null)'),
                      CustomButton(onPressed: () {}, content: const Text('확인')),
                      const SizedBox(height: 16),
                      const Text('전체 너비 (double.infinity)'),
                      CustomButton(
                        width: double.infinity,
                        onPressed: () {},
                        content: const Text('가입하기'),
                      ),
                      const SizedBox(height: 16),
                      const Text('고정 너비 (120)'),
                      CustomButton(
                        width: 120,
                        onPressed: () {},
                        content: const Text('다시 불러오기'),
                      ),
                      const SizedBox(height: 16),
                      const Text('통신 중'),
                      CustomButton(
                        width: 120,
                        isLoading: true,
                        onPressed: () {},
                        content: const Text('확인'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getSize(find.byType(CustomButton).at(0)).width,
        lessThan(120),
      );
      expect(tester.getSize(find.byType(CustomButton).at(1)).width, 320);
      expect(tester.getSize(find.byType(CustomButton).at(2)).width, 120);
      expect(
        tester.widget<TextButton>(find.byType(TextButton).last).onPressed,
        isNull,
      );
      await capture(tester, key, 'button-widths');
    },
  );
  test(
    'nickname and email requests stay independent and discard old responses',
    () async {
      final service = PendingChecks();
      final vm = SignUpViewModel(service);
      addTearDown(vm.dispose);
      vm.onNicknameChanged('철수');
      vm.onEmailChanged('one@example.com');
      final nickname = vm.checkNickname('철수');
      final email = vm.checkEmail('one@example.com');
      vm.onNicknameChanged('영희');
      service.nicknames.single.complete(true);
      service.emails.single.complete(false);
      await Future.wait([nickname, email]);
      expect(vm.nicknameCheckStatus, CheckStatus.idle);
      expect(vm.emailCheckStatus, CheckStatus.duplicated);
      vm.onEmailChanged('two@example.com');
      expect(vm.canCheckEmail, isTrue);
      vm.onEmailChanged('one@example.com');
      expect(vm.canCheckEmail, isTrue);
      expect(vm.emailCheckStatus, CheckStatus.idle);
      expect(service.emails.length, 1);
      final next = vm.checkNickname('영희');
      service.nicknames.last.complete(false);
      await next;
      vm.onNicknameChanged('다른이름');
      vm.onNicknameChanged('영희');
      expect(vm.nicknameCheckStatus, CheckStatus.idle);
    },
  );

  test('network failure differs from duplication and disposal ignores a late response', () async {
    final service = PendingChecks();
    final vm = SignUpViewModel(service);
    vm.onEmailChanged('one@example.com');
    final request = vm.checkEmail('one@example.com');
    service.emails.last.completeError(
      DioException(requestOptions: RequestOptions(path: '/email')),
    );
    await request;
    expect(vm.emailCheckStatus, CheckStatus.error);
    expect(vm.emailErrorText, contains('실패'));
    final retry = vm.checkEmail('one@example.com');
    vm.dispose();
    service.emails.last.complete(true);
    await retry;
  });

  test('ratings keep records on TMDB failure, cache repeated IDs, and ignore stale loads', () async {
    final service = PendingRatings();
    final movies = FakeMovies();
    final vm = MyRatingsViewModel(service, movies, 1);
    addTearDown(vm.dispose);
    final first = vm.load();
    service.requests.last.complete([
      rating(1, 10),
      rating(2, 10),
      rating(3, 404),
    ]);
    await first;
    expect(vm.status, MyRatingsLoadStatus.success);
    expect(vm.ratings.length, 3);
    expect(vm.ratings.last.movie, isNull);
    expect(movies.ids, [10, 404]);
    final old = vm.load();
    final latest = vm.load();
    service.requests.last.complete([]);
    await latest;
    service.requests[1].complete([rating(4, 20)]);
    await old;
    expect(vm.status, MyRatingsLoadStatus.empty);
    expect(vm.ratings, isEmpty);
    final error = vm.load();
    final options = RequestOptions(path: '/ratings');
    service.requests.last.completeError(
      DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 404),
      ),
    );
    await error;
    expect(vm.status, MyRatingsLoadStatus.error);
    expect(vm.message, '존재하지 않는 회원입니다.');
  });

  testWidgets(
    'signup validates both checks, invalidates edits, then opens home',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = PendingChecks();
      final key = GlobalKey();
      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/register',
            builder: (_, _) => ChangeNotifierProvider(
              create: (_) => SignUpViewModel(service),
              child: const RegisterScreen(),
            ),
          ),
          GoRoute(
            path: '/movies',
            builder: (_, _) => const Scaffold(body: Text('홈 도착')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ChangeNotifierProvider(
            create: (_) => LearningMemberSession(),
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, key, 'signup-idle');
      await tester.enterText(find.byType(TextFormField).at(0), '테스트닉네임');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@example.com',
      );
      await tester.tap(find.text('중복 확인').first);
      await tester.tap(find.text('중복 확인').last);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      await capture(tester, key, 'signup-loading');
      service.nicknames.last.complete(false);
      service.emails.last.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('이미 사용중인 닉네임입니다.'), findsOneWidget);
      expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
      await capture(tester, key, 'signup-duplicated');
      await tester.enterText(find.byType(TextFormField).at(0), '새닉네임');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'new@example.com',
      );
      await tester.pump();
      await tester.tap(find.text('중복 확인').first);
      await tester.tap(find.text('중복 확인').last);
      service.nicknames.last.complete(true);
      service.emails.last.complete(true);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Password123!');
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await capture(tester, key, 'signup-available');
      expect(
        tester.widget<CustomButton>(find.byType(CustomButton).last).onPressed,
        isNotNull,
      );
      await tester.tap(find.text('가입하기'));
      await tester.pumpAndSettle();
      expect(find.text('홈 도착'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ratings displays loading, empty, error, success without bottom navigation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = PendingRatings();
      final vm = MyRatingsViewModel(service, FakeMovies(), 1);
      addTearDown(vm.dispose);
      final key = GlobalKey();
      final initial = vm.load();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ChangeNotifierProvider.value(
            value: vm,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const MyRatingsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await capture(tester, key, 'ratings-loading');
      service.requests.last.complete([]);
      await initial;
      await tester.pumpAndSettle();
      expect(find.text('등록된 평점이 없습니다.'), findsOneWidget);
      await capture(tester, key, 'ratings-empty');
      final retry = vm.load();
      service.requests.last.completeError(
        DioException(requestOptions: RequestOptions(path: '/ratings')),
      );
      await retry;
      await tester.pumpAndSettle();
      expect(find.textContaining('평점을 불러오지 못했습니다.'), findsOneWidget);
      await capture(tester, key, 'ratings-error');
      final success = vm.load();
      service.requests.last.complete([
        rating(1, 10, comment: '좋은 영화예요'),
        rating(2, 404),
      ]);
      await success;
      await tester.pumpAndSettle();
      expect(find.text('테스트 영화'), findsOneWidget);
      expect(find.text('영화 정보 없음 · ID 404'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await capture(tester, key, 'ratings-success');
      expect(tester.takeException(), isNull);
    },
  );
}
