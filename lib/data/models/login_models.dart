//로그인 요청을 보낼 때 사용할 모델
class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

//로그인 결과를 받을 때 사용할 모델
class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});
  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
    );
  }
}
