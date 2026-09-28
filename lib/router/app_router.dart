import 'package:go_router/go_router.dart';
import 'package:movielog/main.dart';
import 'package:movielog/widget/movie_detail/movie_detail_page.dart';
import 'package:movielog/widget/movie_home/movie_home_page.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const MovieHomePage(),
      ),
      // GoRoute(path: '/register', builder: (context, state)=> const RegisterScreen()),
      GoRoute(
        path: '/movies',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = state.pathParameters['movieId']!;
          return MovieDetailPage(movieId: movieId);
        },
      ),
      GoRoute(path: '/my', builder: (context, state) => const StartScreen()),
    ],
  );
}
