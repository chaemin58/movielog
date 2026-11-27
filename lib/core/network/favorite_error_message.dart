import 'package:dio/dio.dart';

import 'api_error.dart';

// Do not expose response bodies, tokens or transport exception strings.
String favoriteErrorMessage(Object error) {
  if (error is DioException) {
    final code = apiErrorCode(error);
    if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
      return '로그인 인증을 확인하지 못했습니다. 다시 로그인해 주세요. ($code)';
    }
    if (code == 'MEMBER404_1') return '회원 정보를 찾을 수 없습니다. 다시 로그인해 주세요.';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return '서버에 연결하지 못했습니다. 인터넷 연결을 확인해 주세요.';
    }
    final status = error.response?.statusCode;
    if (status != null) return '즐겨찾기 요청에 실패했습니다. (HTTP $status)';
    return '인증 저장소 또는 네트워크 요청을 확인하지 못했습니다. 앱을 다시 실행해 주세요.';
  }
  if (error is FormatException || error is TypeError) {
    return '즐겨찾기 응답 형식이 올바르지 않습니다.';
  }
  return '즐겨찾기를 불러오지 못했습니다. 다시 시도해 주세요.';
}
