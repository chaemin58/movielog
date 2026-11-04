import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:provider/provider.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>(
          create: (_) => createMovieLogClient(),
          dispose: (_, client) => client.close(),
        ),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider<MemberCheckService>(
          create: (context) => MemberCheckService(context.read<Dio>()),
        ),
        Provider<RatingApiService>(
          create: (context) => RatingApiService(context.read<Dio>()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
