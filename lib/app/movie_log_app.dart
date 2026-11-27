import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/storage/token_storage.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/service/favorite_api_service.dart';
import 'package:movielog/service/rating_api_service.dart';
import 'package:movielog/service/sign_up_service.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:provider/provider.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({super.key});

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  final tokenStorage = SecureTokenStorage(const FlutterSecureStorage());
  late final Dio publicClient = createMovieLogClient();
  late final Dio authClient = createAuthMovieLogClient();
  late final Dio tmdbClient = createTmdbClient();

  @override
  void dispose() {
    publicClient.close();
    authClient.close();
    tmdbClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FavoriteApiService>(
          create: (_) => FavoriteApiService(authClient),
        ),
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<Dio>.value(value: publicClient),
        Provider<TmdbMovieService>(create: (_) => TmdbMovieService(tmdbClient)),
        //공개
        Provider<AuthApiService>(create: (_) => AuthApiService(publicClient)),
        //보호
        Provider<RatingApiService>(
          create: (_) => RatingApiService(publicClient, authClient),
        ),
        Provider<MemberCheckService>(
          create: (_) => MemberCheckService(publicClient),
        ),
        Provider<MemberApiService>(create: (_) => MemberApiService(authClient)),
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => LearningMemberSession(),
        ),

        Provider<SignUpService>(
          create: (context) => SignUpService(context.read<Dio>()),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          lazy: false,
          create: (context) {
            final auth = AuthViewModel(
              context.read<AuthApiService>(),
              context.read<MemberApiService>(),
              context.read<TokenStorage>(),
            );
            authClient.interceptors.add(AuthInterceptor(tokenStorage, auth));
            return auth;
          },
        ),
        Provider<AuthSessionBridge>(
          create: (context) {
            final auth = context.read<AuthViewModel>();
            return AuthSessionBridge(
              authSignals: auth,
              sessionVersion: () => auth.sessionVersion,
              verifiedEmail: () => auth.status == AuthStatus.signedIn
                  ? auth.member?.email
                  : null,
            );
          },
          dispose: (_, bridge) => bridge.dispose(),
        ),
        Provider<SessionGuard>(
          create: (context) => context.read<AuthSessionBridge>().guard,
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authViewModel.restoreSession();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
