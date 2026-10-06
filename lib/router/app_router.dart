import 'package:go_router/go_router.dart';
import 'package:movielog/widget/common/main_screen.dart';
import 'package:movielog/widget/movie_detail/movie_detail_page.dart';
import 'package:movielog/widget/movie_home/movie_home_page.dart';
import 'package:movielog/widget/movies/movies_page.dart';
import 'package:movielog/widget/profile/profile.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const MovieHomePage(),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) => const MoviesPage(),
          ),
          GoRoute(path: '/my', builder: (context, state) => const Profile()),
        ],
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = state.pathParameters['movieId']!;
          return MovieDetailPage(movieId: movieId);
        },
      ),
    ],
  );
}
