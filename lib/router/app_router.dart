import 'package:movielog/screens/favorites_screen.dart';
import 'package:movielog/screens/movie_search_screen.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/screens/button_comparison_screen.dart';
import 'package:movielog/screens/edit_profile.screen.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/my_profile_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/splash_screen.dart';
import 'package:movielog/service/favorite_api_service.dart';
import 'package:movielog/service/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
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
import 'package:movielog/widgets/common/common_app_bar.dart';
import 'package:movielog/widgets/common/custom_button.dart';
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
            builder: (context, state) => const MyProfileScreen(),
            routes: [
              GoRoute(
                path: 'profile/edit',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final auth = context.watch<AuthViewModel>();
                  if (auth.member == null) {
                    return Scaffold(
                      appBar: CommonAppBar(title: '프로필 수정'),
                      body: Center(
                        child: auth.memberStatus == MemberLoadStatus.error
                            ? CustomButton(
                                content: Text('다시 시도'),
                                onPressed: () => auth.loadMember(force: true),
                              )
                            : const CircularProgressIndicator(),
                      ),
                    );
                  }
                  return ChangeNotifierProvider<EditProfileViewModel>(
                    create: (context) => EditProfileViewModel(
                      context.read<MemberApiService>(),
                      auth,
                    ),
                    child: const EditProfileScreen(),
                  );
                },
              ),
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
                      auth: context.read<AuthViewModel>(),
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
        path: '/my/favorites',
        builder: (context, state) {
          final auth = context.watch<AuthViewModel>();
          final guard = context.read<SessionGuard>();
          final member = auth.member;
          if (member == null || guard.accountId != member.email) {
            return Scaffold(
              appBar: AppBar(title: const Text('내 즐겨찾기'), centerTitle: true),
              body: Center(
                child: auth.memberStatus == MemberLoadStatus.error
                    ? TextButton(
                        onPressed: () => auth.loadMember(force: true),
                        child: const Text('내 정보 다시 조회'),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          }
          return ChangeNotifierProvider(
            key: ValueKey('${member.email}:${guard.generation}'),
            create: (_) => FavoritesViewModel(
              context.read<FavoriteApiService>(),
              context.read<TmdbMovieService>(),
              guard,
              member.email,
            )..refresh(),
            child: const FavoritesScreen(),
          );
        },
      ),
      GoRoute(
        path: '/movies/search',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => PagedMoviesViewModel(
            context.read<TmdbMovieService>(),
            isSearch: true,
          ),
          child: const MovieSearchScreen(),
        ),
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
          final auth = context.watch<AuthViewModel>();
          final member = auth.member;
          final guard = context.read<SessionGuard>();

          //내 정보가 준비되고 현재 세션과 일치할 때까지 로딩함.
          if (member == null || guard.accountId != member.email) {
            return Scaffold(
              appBar: AppBar(title: const Text('영화 상세')),
              body: Center(
                child: auth.memberStatus == MemberLoadStatus.error
                    ? TextButton(
                        onPressed: () => auth.loadMember(force: true),
                        child: const Text('내 정보 다시 조회'),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          }
          if (movieId == null || movieId < 1) {
            return const Scaffold(
              body: Center(child: Text('영화  ID가 올바르지 않습니다.')),
            );
          }
          return ChangeNotifierProvider(
            key: ValueKey('${member.email}:${guard.generation}:$movieId'),
            create: (_) => FavoriteDetailViewModel(
              movieId: movieId,
              favoriteApi: context.read<FavoriteApiService>(),
              sessionGuard: guard,
              accountId: member.email,
            )..load(),
            child: MovieDetailLoader(
              movieId: movieId,
              initialMovie: state.extra is TmdbMovieDto
                  ? state.extra as TmdbMovieDto
                  : null,
            ),
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
