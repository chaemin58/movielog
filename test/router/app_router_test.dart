import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/storage/token_storage.dart';
import 'package:movielog/service/rating_api_service.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movie_home_page.dart';
import 'package:movielog/screens/movies_page.dart';
import 'package:movielog/screens/profile.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:movielog/view_models/learning_member_session.dart';
// Test-only platform fake from the installed shared_preferences dependency.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class OfflineMovieService extends TmdbMovieService {
  OfflineMovieService() : super(Dio());

  @override
  Future<TmdbMovieDetailDto> fetchMovieDetail({required int movieId}) async {
    final options = RequestOptions(path: '/movie/$movieId');
    throw DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 404),
      type: DioExceptionType.badResponse,
    );
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    throw DioException(
      requestOptions: RequestOptions(path: '/genre/movie/list'),
    );
  }
}

class EmptyRatingsService extends RatingApiService {
  EmptyRatingsService() : super(Dio(), Dio());
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async => [];
}

class _SuccessfulAuthApi extends AuthApiService {
  _SuccessfulAuthApi(super.dio);

  @override
  Future<LoginResult> login(LoginRequest request) async =>
      const LoginResult(nickname: '테스트', accessToken: 'test-token');
}

class _MemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> saveAccessToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> deleteAccessToken() async {
    token = null;
  }
}

void main() {
  testWidgets('redirects on login and preserves tab and detail navigation', (
    tester,
  ) async {
    final originalPreferences = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(
      () => SharedPreferencesAsyncPlatform.instance = originalPreferences,
    );
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio();
    final auth = AuthViewModel(
      _SuccessfulAuthApi(dio),
      MemberApiService(dio),
      _MemoryTokenStorage(),
    );
    final router = AppRouter.createRouter(auth);
    addTearDown(() {
      router.dispose();
      auth.dispose();
      dio.close();
    });
    await auth.restoreSession();
    router.go('/my');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: auth),
          ChangeNotifierProvider(
            create: (_) => LearningMemberSession()..setMemberId(42),
          ),
          Provider<TmdbMovieService>(create: (_) => OfflineMovieService()),
          Provider<RatingApiService>(create: (_) => EmptyRatingsService()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'Password123!');
    await tester.tap(find.widgetWithText(TextButton, '로그인'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieHomePage), findsOneWidget);

    router.go('/my');
    await tester.pumpAndSettle();
    expect(find.byType(Profile), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.byType(NavigationDestination).at(0));
    await tester.pumpAndSettle();
    expect(find.byType(MovieHomePage), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.byType(MoviesPage), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(find.byType(Profile), findsOneWidget);

    router.push('/my/ratings');
    await tester.pumpAndSettle();
    expect(find.byType(MyRatingsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(Profile), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    router.go('/movies/999999');
    await tester.pumpAndSettle();
    expect(find.text('영화 정보를 불러오지 못했어요.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
