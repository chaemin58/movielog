import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/service/sign_up_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

enum SubmitStatus { idle, submitting, success, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;

  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createMemberId;
  String? passwordErrorText;
  String? snackbarMessage;

  void onPasswordChanged() {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;
    _clearSubmitError();
    notifyListeners();
  }

  void _clearSubmitError() {
    passwordErrorText = null;
    snackbarMessage = null;
    if (submitStatus == SubmitStatus.error) submitStatus = SubmitStatus.idle;
  }

  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String _currentNickname = '';
  int _requestVersion = 0;
  bool _disposed = false;

  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String _currentEmail = '';
  int _emailRequestVersion = 0;

  bool get canCheckEmail =>
      emailCheckStatus != CheckStatus.checking &&
      submitStatus != SubmitStatus.submitting;

  void onEmailChanged(String value) {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;
    _currentEmail = value.trim();
    _emailRequestVersion++;
    emailCheckStatus = CheckStatus.idle;
    emailErrorText = null;
    _clearSubmitError();
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

  Future<void> submit(CreateMemberRequest request) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;
    if (nicknameCheckStatus != CheckStatus.available ||
        emailCheckStatus != CheckStatus.available ||
        request.nickname.trim() != _currentNickname ||
        request.email.trim() != _currentEmail) {
      return;
    }
    submitStatus = SubmitStatus.submitting;

    createMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (!response.isSuccess || id == null) {
        throw StateError('회원가입 결과를 확인하지 못했습니다.');
      }
      createMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } catch (_) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ

  bool get canCheckNickname =>
      nicknameCheckStatus != CheckStatus.checking &&
      submitStatus != SubmitStatus.submitting;

  // 입력이 바뀌면 이전 값의 중복 확인과 가입 오류를 무효화합니다.
  void onNicknameChanged(String value) {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;
    final trimmed = value.trim(); //우선 공백제거
    _currentNickname = trimmed;
    _requestVersion++;

    nicknameCheckStatus = CheckStatus.idle;
    nicknameErrorText = null;
    _clearSubmitError();
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
