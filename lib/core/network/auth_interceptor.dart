import 'package:dio/dio.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/storage/token_storage.dart';
import 'package:movielog/view_models/auth_view_model.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._auth);

  final TokenStorage _storage;
  final AuthViewModel _auth;

  //토큰이 필요한 요청인지를 검사한다.
  bool _isProtected(RequestOptions options) {
    if (options.uri.scheme != 'https' ||
        options.uri.host != 'workbook.devnoco.com') {
      return false;
    }
    final path = options.uri.path;
    final method = options.method.toUpperCase();
    return (path == '/v8/members/me' &&
            (method == 'GET' || method == 'PATCH')) ||
        (path == '/v8/ratings' && method == 'POST') ||
        (RegExp(r'^/v8/ratings/[1-9]\d*$').hasMatch(path) &&
            (method == 'PATCH' || method == 'DELETE')) ||
        (path == '/v8/favorites' && (method == 'GET' || method == 'POST')) ||
        (RegExp(r'^/v8/favorites/[1-9]\d*$').hasMatch(path) &&
            (method == 'GET' || method == 'DELETE'));
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
    // 토큰을 읽는 동안이나 응답을 기다리는 동안 세션이 바뀔 수 있습니다.
    options.extra['sessionVersion'] = _auth.sessionVersion;

    try {
      final token = await _storage.readAccessToken();
      if (options.extra['sessionVersion'] != _auth.sessionVersion) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: '세션이 변경되었습니다.',
          ),
        );
        return;
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
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

  //Dio가 제공하는 onError 오버라이드
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      // 이전 세션의 오류로 새 로그인까지 만료시키지 않습니다.
      final requestVersion = err.requestOptions.extra['sessionVersion'];
      if (!_isProtected(err.requestOptions) ||
          requestVersion != _auth.sessionVersion) {
        return; // finally에서 원래 오류는 계속 전달합니다.
      }

      if (err.response?.statusCode == 401) {
        //사용 중 인증이 유효하지 않는 것만 확인
        final errorCode = apiErrorCode(err);
        if (errorCode == 'AUTH401_2' ||
            errorCode == 'AUTH401_3' ||
            errorCode == 'AUTH401_4') {
          //세션 만료
          await _auth.expireSession();
        }
      }
    } finally {
      handler.next(err);
    }
  }
}
