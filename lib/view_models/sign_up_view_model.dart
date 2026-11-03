import 'package:flutter/foundation.dart';
import 'package:movielog/data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

// Each field owns its value and request version so concurrent checks are independent.
class _CheckField {
  String value = '';
  String? duplicatedValue;
  String? error;
  int version = 0;
  CheckStatus status = CheckStatus.idle;
}

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final MemberCheckService _service;
  final _nickname = _CheckField();
  final _email = _CheckField();
  bool _disposed = false;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  CheckStatus get emailCheckStatus => _email.status;
  String? get nicknameErrorText => _nickname.error;
  String? get emailErrorText => _email.error;
  static String? validateNickname(String? value) {
    if ((value ?? '').trim().length < 2) return '닉네임은 두 글자 이상 입력해 주세요.';
    return null;
  }

  static String? validateEmail(String? value) {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim())) {
      return '올바른 이메일을 입력해 주세요.';
    }
    return null;
  }

  bool _canCheck(_CheckField field) =>
      !_disposed &&
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated;
  bool get canCheckNickname =>
      _canCheck(_nickname) && validateNickname(_nickname.value) == null;
  bool get canCheckEmail =>
      _canCheck(_email) && validateEmail(_email.value) == null;
  bool get checksPassed =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  void onNicknameChanged(String value) => _changed(_nickname, value, '닉네임');
  void onEmailChanged(String value) => _changed(_email, value, '이메일');
  void _changed(_CheckField field, String value, String label) {
    if (_disposed) return;
    field.value = value.trim();
    field.version++;
    final duplicated = field.value == field.duplicatedValue;
    field.status = duplicated ? CheckStatus.duplicated : CheckStatus.idle;
    field.error = duplicated ? '이미 사용 중인 $label입니다.' : null;
    notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    if (canCheckNickname) {
      await _check(_nickname, value, '닉네임', _service.checkNickname);
    }
  }

  Future<void> checkEmail(String value) async {
    if (canCheckEmail) await _check(_email, value, '이메일', _service.checkEmail);
  }

  Future<void> _check(
    _CheckField field,
    String value,
    String label,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    if (_disposed || requested != field.value) return;
    final version = ++field.version;
    field.status = CheckStatus.checking;
    field.error = null;
    notifyListeners();
    bool isCurrent() => !_disposed && version == field.version;
    try {
      final available = await request(requested);
      if (!isCurrent()) return;
      field.status = available ? CheckStatus.available : CheckStatus.duplicated;
      field.error = available ? null : '이미 사용 중인 $label입니다.';
      if (!available) field.duplicatedValue = requested;
    } catch (_) {
      if (!isCurrent()) return;
      field.status = CheckStatus.error;
      field.error = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (isCurrent()) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
