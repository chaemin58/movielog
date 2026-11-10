//회원가입할 때 서버에 보낼 정보를 담는 클래스
//toJson은 Dart 객체를 요청 body로 바꾸는 방향이다.
class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  final String email;
  final String password;
  final String nickname;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password, //비밀번호에는 사용자가 입력한 문자가 의미있으므로 무조건 값을 바꾸지 않음
    'nickname': nickname.trim(),
  };
}
