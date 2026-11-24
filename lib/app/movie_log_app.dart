import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/storage/token_storage.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/service/rating_api_service.dart';
import 'package:movielog/service/sign_up_service.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:provider/provider.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = SecureTokenStorage(const FlutterSecureStorage());

    final publicClient = createMovieLogClient(); //interceptor 없음.
    final authClient = createAuthMovieLogClient();

    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<Dio>(
          create: (_) => createMovieLogClient(),
          dispose: (_, client) => client.close(),
        ),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
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
