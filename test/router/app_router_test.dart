import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movie_home_page.dart';
import 'package:movielog/screens/movies_page.dart';
import 'package:movielog/screens/profile.dart';
import 'package:provider/provider.dart';
// Test-only platform fake from the installed shared_preferences dependency.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class OfflineMovieService extends TmdbMovieService {
  OfflineMovieService() : super(Dio());

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    throw DioException(
      requestOptions: RequestOptions(path: '/genre/movie/list'),
    );
  }
}

void main() {
  testWidgets('keeps navigation on all tabs and leaves it off detail pages', (
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
    AppRouter.router.go('/my');

    await tester.pumpWidget(
      Provider<TmdbMovieService>(
        create: (_) => OfflineMovieService(),
        child: MaterialApp.router(routerConfig: AppRouter.router),
      ),
    );
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

    AppRouter.router.go('/movies/999999');
    await tester.pumpAndSettle();
    expect(find.text('영화를 찾을 수 없어요'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
