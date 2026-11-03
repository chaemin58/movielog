import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movielog/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //env 파일이 로드되기를 기다린다.
  await dotenv.load(fileName: '.local.env');
  runApp(const MovieLogApp());
}

//tmdb의 at를 기다린다.
final accessToken = dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
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
