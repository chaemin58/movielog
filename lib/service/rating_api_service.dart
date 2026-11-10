import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
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
      final response = await _dio.post(
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
    final response = await _dio.patch(
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
    final response = await _dio.delete(
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

String writeErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    final message = data is Map ? data['message'] : null;
    if (message is String && message.trim().isNotEmpty) return message;
    return switch (error.response?.statusCode) {
      400 => '입력한 별점과 코멘트를 확인해 주세요.',
      403 => '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      404 => '회원 또는 평점을 찾을 수 없습니다.',
      409 => '이미 이 영화에 평점을 남기셨습니다.',
      _ => '요청에 실패했습니다. 연결 상태를 확인해 주세요.',
    };
  }
  if (error is StateError) return error.message.toString();
  return '응답을 확인하지 못했습니다. 다시 요청하기 전에 목록을 확인해 주세요.';
}

bool shouldRefreshAfterRatingError(Object error) =>
    error is DioException &&
    (error.response?.statusCode == 403 || error.response?.statusCode == 404);
