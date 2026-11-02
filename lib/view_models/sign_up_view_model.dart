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

  bool get canCheckNickname =>
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  void onNicknameChanged(String value) {
    final trimmed = value.trim(); //우선 공백제거
    _currentNickname = trimmed;
    _requestVersion++;

    //이전 닉네임이 비어있거나 가져온 닉네임이 이전 닉네임이면
    if (_duplicateNickname != null && trimmed == _duplicateNickname) {
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    //요청할 값이 비어있거나 입력값과 요청값이 일치하지 않거나 얼리리턴처리
    if (requested.isEmpty ||
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
    super.dispose();
  }
}
