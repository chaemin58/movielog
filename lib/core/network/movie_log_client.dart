import 'package:dio/dio.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/data/storage/token_storage.dart';

Dio createMovieLogClient() {
  return Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}

BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

//보호용 Client 추가
Dio createAuthMovieLogClinet(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  return dio;
}
