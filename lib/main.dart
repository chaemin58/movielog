import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movielog/app/movie_log_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //env 파일이 로드되기를 기다린다.
  await dotenv.load(fileName: '.local.env');
  runApp(const MovieLogApp());
}
