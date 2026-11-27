import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/storage/token_storage.dart';
import 'package:movielog/view_models/auth_view_model.dart';

class Storage implements TokenStorage {
  int deletes = 0;
  Completer<String?>? pending;
  Completer<void>? readStarted;
  @override
  Future<String?> readAccessToken() async {
    readStarted?.complete();
    return pending == null ? 'test-token' : pending!.future;
  }
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> deleteAccessToken() async {
    deletes++;
  }
}

void main() {
  for (final code in [
    'AUTH401_2',
    'AUTH401_3',
    'AUTH401_4',
    'AUTH401_1',
    'MEMBER404_1',
    'FORBIDDEN',
  ]) {
    test('session handling for $code', () async {
      final storage = Storage();
      final auth = AuthViewModel(
        AuthApiService(Dio()),
        MemberApiService(Dio()),
        storage,
      )..status = AuthStatus.signedIn;
      addTearDown(auth.dispose);
      final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'));
      dio.interceptors.add(AuthInterceptor(storage, auth));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            expect(o.headers['Authorization'], 'Bearer test-token');
            h.reject(
              DioException(
                requestOptions: o,
                response: Response(
                  requestOptions: o,
                  statusCode: code == 'FORBIDDEN'
                      ? 403
                      : code == 'MEMBER404_1'
                      ? 404
                      : 401,
                  data: {'code': code},
                ),
              ),
              true,
            );
          },
        ),
      );
      await expectLater(dio.get('/v8/favorites'), throwsA(isA<DioException>()));
      final expires = ['AUTH401_2', 'AUTH401_3', 'AUTH401_4'].contains(code);
      expect(auth.status, expires ? AuthStatus.signedOut : AuthStatus.signedIn);
      expect(storage.deletes, expires ? 1 : 0);
    });
  }
  test(
    'never adds MovieLog JWT to TMDB and cancels a token read across logout',
    () async {
      final storage = Storage();
      final auth = AuthViewModel(
        AuthApiService(Dio()),
        MemberApiService(Dio()),
        storage,
      )..status = AuthStatus.signedIn;
      addTearDown(auth.dispose);
      final dio = Dio();
      dio.interceptors.add(AuthInterceptor(storage, auth));
      var sent = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            sent++;
            expect(o.headers.containsKey('Authorization'), false);
            h.resolve(Response(requestOptions: o, data: {}));
          },
        ),
      );
      await dio.get('https://api.themoviedb.org/v8/favorites');
      storage.pending = Completer();
      storage.readStarted = Completer();
      final request = dio.get('https://workbook.devnoco.com/v8/favorites');
      final assertion = expectLater(request, throwsA(isA<DioException>()));
      await storage.readStarted!.future;
      await auth.logout();
      storage.pending!.complete('old-token');
      await assertion;
      expect(sent, 1);
    },
  );
}
