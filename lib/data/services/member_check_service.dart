import 'package:dio/dio.dart';
import 'package:movielog/data/models/check_result.dart';

class MemberCheckService {
  MemberCheckService(this._dio);
  final Dio _dio;

  //서버에 닉네입을 보내 중복 여부를 확인하고 사용가능하면 true, 아니면 false
  Future<bool> checkNickname(String nickname) async {
    //입력값을 url에 넣을 수 있도록 준비한다.
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');

    //response.data에서 서버 응답 데이터를 꺼냄.
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('v5/members/email/$encoded');

    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }
}
