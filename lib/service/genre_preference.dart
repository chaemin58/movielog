import 'package:shared_preferences/shared_preferences.dart';

//우선 함수를 만들기 위해서 클래스를 정의함.
class GenrePreference {
  //이건뭐지: 생성자. 객체가 태어날 때 딱 한 번 실행되는 초기화 코드.
  //1. {SharedPreferencesAsync? preferences} — named parameter
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  //안에 변수로는 selecedgenrekey가 있고 selected_genre 문자열을 담고있다.
  static const _selectedGenreKey = 'selected_genre';
  final SharedPreferencesAsync
  _preferences; //SharedPreferenceAsync 타입의 공개되지 않는 _preferences라고까지만 이해

  //읽는 함수 정의 리턴 타입은 Future의 String이다. 위의 SharedPreferenceAsync 타입의 _preferences을 호출해서 getString한다. get해온다. selectedGenreKey를 넣어서 저장소 중에서 선택된 장르를 조회하고 만약 저장된게 없다면 null 값처리
  Future<String> read() async {
    return await _preferences.getString(_selectedGenreKey) ?? '전체';
  }

  //저장하는 함수. setString으로 genre를 파라미터로 받아서 저장
  Future<void> save(String genre) async {
    await _preferences.setString(_selectedGenreKey, genre);
  }

  //해제하는함수
  Future<void> clear() async {
    await _preferences.remove(_selectedGenreKey);
  }
}
