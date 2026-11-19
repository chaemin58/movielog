import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/storage/token_storage.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);
  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;

  String? message;
  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;
  bool _disposed = false;
  Future<void>? _tokenWrite;

  MemberLoadStatus memberStatus = MemberLoadStatus.idle;

  Future<void> loadMember({bool force = false}) async {
    if (status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return;

    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    notifyListeners();

    try {
      final me = await _memberApi.fetchMe();
      if (version != _sessionVersion) return;
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (version != _sessionVersion) return;
      final code = apiErrorCode(error);
      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _clearCurrentSession(); //세션 만료 시 비워줌
        return;
      }
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요';
    }

    notifyListeners();
  }

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restoreSession() async {
    if (_disposed ||
        storageCleanupInProgress ||
        (status != AuthStatus.initializing &&
            status != AuthStatus.retryRequired) ||
        memberStatus == MemberLoadStatus.loading) {
      return;
    }
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    memberStatus = MemberLoadStatus.loading;
    message = null;
    _notify();

    try {
      final token = await _storage.readAccessToken();
      if (!_isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
        memberStatus = MemberLoadStatus.idle;
        return;
      }

      final restoredMember = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return;
      member = restoredMember;
      memberStatus = MemberLoadStatus.success;
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (error.response?.statusCode == 401) {
        await _clearCurrentSession();
        return;
      }
      _requireSessionRetry();
    } catch (_) {
      if (!_isCurrent(version)) return;
      _requireSessionRetry();
    } finally {
      if (_isCurrent(version)) _notify();
    }
  }

  void _requireSessionRetry() {
    status = AuthStatus.retryRequired;
    memberStatus = MemberLoadStatus.error;
    message = '로그인 상태를 확인하지 못했습니다. 다시 시도해 주세요.';
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    final version = ++_sessionVersion;
    _notify();
    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!_isCurrent(version)) return;
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!_isCurrent(version)) return;
      // 신규 로그인 최종 흐름: 토큰 저장 → signedIn → MainScreen.loadMember().
      // 앱 재시작은 restoreSession()의 GET me 검증 후에만 signedIn입니다.
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 정보를 안전하게 저장하지 못했어요.';
    }
    _notify();
  }

  Future<void> _clearCurrentSession({bool expired = true}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion;
    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    _notify();
    try {
      // 진행 중이던 토큰 저장을 기다린 뒤 삭제합니다. 정리 중 새 로그인은 막습니다.
      try {
        await _tokenWrite;
      } catch (_) {
        /* 저장 실패여도 삭제는 시도 */
      }
      await _storage.deleteAccessToken();
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify();
    }
  }

  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return null;
    member = updated; //업데이트 된 걸로 갈아끼워주기
    notifyListeners(); //다시 그리라고 알려주기
  }

  //다른 viewmodel이 401을 받았을 때 _clearCurrentSession을 호출할 수 없기 때문에... 세션 정리를 하는 공개 진입점
  Future<void> expireSession() => _clearCurrentSession(expired: true);

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
