import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final MemberCheckService _service;

  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String? _duplicateNickname;
  String _currentNickname = '';
  int _requestVersion = 0;
  bool _disposed = false;

  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String? _duplicatedEmail;
  String _currentEmail = '';
  int _emailRequestVersion = 0;

  bool get canCheckEmail =>
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  void onEmailChanged(String value) {
    _currentEmail = value.trim();
    _emailRequestVersion++;
    if (_duplicatedEmail != null && _currentEmail == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    if (_disposed ||
        requested.isEmpty ||
        requested != _currentEmail ||
        !canCheckEmail) {
      return;
    }
    final version = ++_emailRequestVersion;
    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();
    try {
      final available = await _service.checkEmail(requested);
      if (_disposed ||
          version != _emailRequestVersion ||
          requested != _currentEmail) {
        return;
      }
      emailCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';
      if (!available) _duplicatedEmail = requested;
    } on DioException {
      if (_disposed ||
          version != _emailRequestVersion ||
          requested != _currentEmail) {
        return;
      }
      emailCheckStatus = CheckStatus.error;
      emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _emailRequestVersion) notifyListeners();
  }

  //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ

  bool get canCheckNickname =>
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  //전에 중복이라고 했던 그 닉네임인가?
  //확인하는 이유는 '철수'라고 썼다가 지우고, 다시 철수라고 쓰면 버튼 누름없이 즉각적으로 보여주기 위해서.
  void onNicknameChanged(String value) {
    final trimmed = value.trim(); //우선 공백제거
    _currentNickname = trimmed;
    _requestVersion++;

    // 마지막으로 중복 확인된 닉네임을 다시 입력하면 결과를 복원
    //이전에 입력했던 중복 닉네임이 있고 trimmed된 것이 이전에 입력했던 닉네임과 같으면 에러 상태를 복원한다.
    if (_duplicateNickname != null && trimmed == _duplicateNickname) {
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  //진짜로 서버에 닉네임 중복을 확인하는 함수
  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    //요청할 값이 비어있거나 입력값과 요청값이 일치하지 않거나 얼리리턴처리
    if (_disposed ||
        requested.isEmpty ||
        requested != _currentNickname ||
        !canCheckNickname) {
      return;
    }

    final version = ++_requestVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();

    try {
      //사용할 수 있는지 확인한다.
      final available = await _service.checkNickname(requested);
      //종료되었거나 || 올바른 시도가 아니거나 || 입력값과 요청값이 다르면 얼리리턴
      if (_disposed ||
          version != _requestVersion ||
          _currentNickname != requested) {
        return;
      }
      nicknameCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated; //닉네임의 상태 업데이트

      nicknameErrorText = available ? null : '이미 사용중인 닉네임입니다.';
      if (!available) _duplicateNickname = requested;
    } on DioException {
      if (_disposed ||
          version != _requestVersion ||
          _currentNickname != requested) {
        return;
      }

      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}

//지금은 비슷한 함수를 두 번 사용했지만 공통 로직을 재사용할 수 있도록 할 수 있다.
// 예를 들어 중복 확인 로직을 담당하는 DuplicateCheckController라는 클래스를 만들 수 있고
// 이 같은 킄래스로 객ㅊ에를 두 개 만드는 것
