//토큰을 읽는 코드와 값 누락 검사를 한 곳에 모아서 여러 파일에서 키 문자열을 반복하지 않게 한다.
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class TmdbConfig {
  static String get accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
}
