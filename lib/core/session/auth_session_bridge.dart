//authviewmodel의 상태 변화를 sessionGuard에 전달
import 'package:flutter/foundation.dart';
import 'package:movielog/core/session/session_guard.dart';

class AuthSessionBridge {
  AuthSessionBridge({
    required this.authSignals,
    required this.sessionVersion,
    required this.verifiedEmail,
  }) {
    authSignals.addListener(_sync); //authSignal과 연결
    _sync(); //연결하자마자 _sync() 함수 실행
  }

  final Listenable authSignals;
  final int Function() sessionVersion; //호출하면 정수를 반환하는 함수를 저장하는 변수
  final String? Function() verifiedEmail;
  final guard = SessionGuard();
  int? _seenVersion;
  String? _seenEmail;
  bool _disposed = false;

  void _sync() {
    if (_disposed) return;
    final version = sessionVersion();
    final email = verifiedEmail();
    if (version == _seenVersion && email == _seenEmail) return; //지금 읽은 값과 이전에 기억한 값이 같다면 세션에 변화가 없기 때문에 그대로 끝난다.  ex. 프로필 사진만 변경해서 알림이 온 경우에는 버전과 이메일은 그대로일 수 있다.

    //값이 달라졌다면 지금 그 값을 읽었으므로 저장한다.
    _seenEmail = email;
    _seenVersion = version;

    guard.invalidate(); //이전 세션을 무효화

    if (email != null) {
      guard.startSession(email); //확인된 이메일이 있으면 그 계정으로 새 세션을 시작한다.
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    authSignals.removeListener(_sync);
    guard.invalidate();
  }
}
