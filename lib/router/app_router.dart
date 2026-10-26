import 'package:go_router/go_router.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/main_screen.dart';
import 'package:movielog/screens/movie_detail_page.dart';
import 'package:movielog/screens/movie_home_page.dart';
import 'package:movielog/screens/movies_page.dart';
import 'package:movielog/screens/profile.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:provider/provider.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/home',
    routes: [
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
          GoRoute(path: '/my', builder: (context, state) => const Profile()),
        ],
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) =>
            MovieDetailPage(movieId: state.pathParameters['movieId']!),
      ),
    ],
  );
}
