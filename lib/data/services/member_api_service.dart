import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';

class MemberInfo {
  const MemberInfo({required this.nickname});

  final String nickname;
}

class MemberApiService {
  MemberApiService(this._dio);

  final Dio _dio;

  Future<MemberInfo> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/v7/members/me');
    final data = response.data;
    if (data == null) throw const FormatException('내 정보 응답이 비어 있습니다.');

    final result = CommonResponse<MemberInfo>.fromJson(data, (value) {
      if (value is! Map<String, dynamic> || value['nickname'] is! String) {
        throw const FormatException('내 정보 응답 형식이 올바르지 않습니다.');
      }
      return MemberInfo(nickname: value['nickname'] as String);
    });
    final member = result.result;
    if (!result.isSuccess || member == null) {
      throw StateError('내 정보를 확인하지 못했습니다.');
    }
    return member;
  }
}
