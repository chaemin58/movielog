import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/favorite_check_dto.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';

class FavoriteApiService {
  FavoriteApiService(this._dio);
  final Dio _dio;

  //즐겨찾기 등록하는 함수
  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    final response = await _dio.post(
      '/v8/favorites',
      data: {'movieId': movieId},
    );

    //서버에서 받은 JSON 응답을 Dart 객체로 변환하는 코드
    final body = CommonResponse<FavoriteResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      FavoriteResponseDto.fromJson,
    );

    return body.result!;
  }

  //내 즐겨찾기 조회
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _dio.get('/v8/favorites/');
    final body = CommonResponse<List<FavoriteResponseDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (value) =>
          (value as List<dynamic>).map(FavoriteResponseDto.fromJson).toList(),
    );
    return body.result!;
  }

  //즐겨찾기 삭제
  Future<void> delelteMyFavorite({required int movieId}) async {
    await _dio.delete('/v8/favorites/', data: {'movieId': movieId});
  }

  //즐겨찾기 여부 조회
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    final response = await _dio.get('/v8/favorites/${movieId}');

    final body = CommonResponse<FavoriteCheckDto>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => FavoriteCheckDto.fromJson(value, movieId: movieId),
    );
    return body.result!;
  }
}
