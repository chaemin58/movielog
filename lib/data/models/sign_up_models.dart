//서버에서 받은 회원가입 응답을 받는다.
// 회원가입 성공 응답은 CommonResponse<SignUpResult>로 파싱하고 result는 한 번만 둔다.

class SignUpResult {
  const SignUpResult({
    required this.memberId,
    required this.email,
    required this.nickname,
  });

  final int memberId;
  final String email;
  final String nickname;

  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    return SignUpResult(
      memberId: (json['memberId'] as num).toInt(),
      email: (json['email'] as String),
      nickname: (json['nickname'] as String),
    );
  }
}
