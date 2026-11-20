import 'package:dio/dio.dart';

//공통 오류 처리
//서버가 약속한 형식의 에러 코드가 있으면 꺼내고 아니면 null 리턴
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}
