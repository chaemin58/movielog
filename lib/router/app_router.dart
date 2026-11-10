import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:movielog/screens/button_comparison_screen.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/screens/profile.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/service/sign_up_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/main_screen.dart';
import 'package:movielog/screens/movie_detail_page.dart';
import 'package:movielog/screens/movie_home_page.dart';
import 'package:movielog/screens/movies_page.dart';
import 'package:movielog/screens/register_screen.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
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

  static final router = GoRouter(
    initialLocation: '/home',
    overridePlatformDefaultLocation: true,
    navigatorKey: rootNavigatorKey,
    routes: [
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
          final movieId = state.pathParameters['movieId']!;
          final id = int.tryParse(movieId);
          if (id == null || id <= 0) {
            return MovieDetailPage(movieId: movieId);
          }
          return ChangeNotifierProvider<MovieDetailViewModel>(
            key: state.pageKey,
            create: (context) => MovieDetailViewModel(
              context.read<TmdbMovieService>(),
              ratingService: context.read<RatingApiService>(),
              memberId: context.read<LearningMemberSession>().memberId,
            )..load(id),
            child: MovieDetailPage(movieId: movieId),
          );
        },
      ),
    ],
  );
}
