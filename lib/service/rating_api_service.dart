import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._publicClient, this._authClient);
  final Dio _publicClient;
  final Dio _authClient;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicClient.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    {
      final response = await _authClient.post(
        '/v6/members/$memberId/ratings',
        data: request.toJson(),
      );

      if (response.statusCode != 201) {
        throw StateError('예상하지 못한 등록 응답:${response.statusCode}');
      }
      _checkWriteResponse(response);
    }
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authClient.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      // 기존 코멘트는 그대로 보내고, 지웠다면 null을 보냅니다.
      data: {'score': score, 'comment': comment},
    );
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 수정 응답: ${response.statusCode}');
    }
    _checkWriteResponse(response);
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _authClient.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답 :${response.statusCode}');
    }
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

void _checkWriteResponse(Response<dynamic> response) {
  final common = CommonResponse<Object?>.fromJson(
    response.data as Map<String, dynamic>,
    (value) => value,
  );
  if (!common.isSuccess) throw StateError(common.message);
}

//서버 오류 응답에서 메세지를 꺼내서 반환하고, 메세지가 없다면 기본 안내 문구를 반환한다.
String writeErrorMessage(DioException error) {
  //파라미터로 받은 error의 data를 가져오고,
  final data = error.response?.data;
  //문자열을 키로 사용하는 map인지를 확인하고 맞으면 CommonResponse 객체로 변환하거나 null
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;
  return common?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map<String, dynamic> ? data['code'] as String? : null;
  // 403·404는 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해서 맞춥니다.
  return code == 'COMMON403' || code == 'COMMON404';
}
