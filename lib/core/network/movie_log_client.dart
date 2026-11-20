import 'package:dio/dio.dart';

BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

Dio createMovieLogClient() {
  return Dio(_movieLogOptions());
}

Dio createAuthMovieLogClient() {
  return createMovieLogClient();
}
