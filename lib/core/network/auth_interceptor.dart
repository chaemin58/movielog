import 'package:dio/dio.dart';
import 'package:movielog/data/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  //토큰이 필요한 요청인지를 검사한다.
  bool _isProtected(RequestOptions options) {
    final path = options.uri.path;
    return options.uri.host == 'workbook.devnoco.com' &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('v7/ratings'));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isProtected(options)) {
      //인증이 필요없는 요청이라면 그대로 진행.
      handler.next(options);
      return;
    }

    options.headers.remove('Authorization');

    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty)
        options.headers['Authorization'] = 'Bearer $token';
      //토큰 확인과 헤더 설정이 끝났으니 이 요청을 다음 단계로 넘겨라
      handler.next(options);
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }
}
