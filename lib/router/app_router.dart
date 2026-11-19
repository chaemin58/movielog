import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:movielog/screens/button_comparison_screen.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/profile.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/splash_screen.dart';
import 'package:movielog/service/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/service/sign_up_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/main_screen.dart';
import 'package:movielog/screens/movie_detail_loader.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/screens/movie_home_page.dart';
import 'package:movielog/screens/movies_page.dart';
import 'package:movielog/screens/register_screen.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:provider/provider.dart';

class AppRouter {
  AppRouter._();
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static ChangeNotifierProvider<SignUpViewModel> _registerScreen() =>
      ChangeNotifierProvider<SignUpViewModel>(
        create: (context) => SignUpViewModel(context.read<SignUpService>()),
        child: const RegisterScreen(),
      );

  static GoRouter createRouter(AuthViewModel authViewModel) => GoRouter(
    initialLocation: '/start',
    overridePlatformDefaultLocation: true,
    navigatorKey: rootNavigatorKey,
    refreshListenable: authViewModel,
    redirect: (context, state) =>
        authRedirect(authViewModel.status, state.uri.path),
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) {
          final auth = context.watch<AuthViewModel>();
          return SplashScreen(
            message: auth.message,
            onRetry: auth.status == AuthStatus.retryRequired
                ? auth.restoreSession
                : null,
          );
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => _registerScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScreen(
          currentIndex: indexFromLocation(state.uri.path),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieHomeViewModel>(
                  create: (context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const MovieHomePage(),
                ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieListViewModel>(
                  create: (context) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(),
                  child: const MoviesPage(),
                ),
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const Profile(),
            routes: [
              GoRoute(
                path: 'buttons',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const ButtonComparisonScreen(),
              ),
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final id = context.read<LearningMemberSession>().memberId;
                  if (id == null) {
                    return Scaffold(
                      appBar: AppBar(
                        centerTitle: true,
                        title: const Text("내가 등록한 평점"),
                      ),
                      body: const Center(child: Text('학습용 회원가입이 필요합니다.')),
                    );
                  }
                  return ChangeNotifierProvider<MyRatingsViewModel>(
                    create: (context) => MyRatingsViewModel(
                      context.read<RatingApiService>(),
                      context.read<TmdbMovieService>(),
                      id,
                    )..load(),
                    child: const MyRatingsScreen(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (id == null || id < 1) {
            return const Scaffold(
              body: Center(child: Text('영화  ID가 올바르지 않습니다.')),
            );
          }
          final extra = state.extra;
          return MovieDetailLoader(
            movieId: id,
            initialMovie: extra is TmdbMovieDto && extra.id == id
                ? extra
                : null,
          );
        },
      ),
    ],
  );
}

String? authRedirect(AuthStatus status, String path) {
  final isStart = path == '/start';
  final isAuthPage = path == '/login' || path == '/register';

  return switch (status) {
    AuthStatus.initializing ||
    AuthStatus.retryRequired => isStart ? null : '/start',
    AuthStatus.signedOut ||
    AuthStatus.authenticating => isAuthPage ? null : '/login',
    AuthStatus.signedIn =>
      isStart || isAuthPage || path == '/' ? '/home' : null,
  };
}
