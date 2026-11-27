import 'package:movielog/core/network/favorite_error_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/safe_notify.dart';
import 'package:movielog/service/favorite_api_service.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
  }) : _session = sessionGuard.generation;

  final int _session;
  bool get isCurrentSession =>
      !isDisposed && sessionGuard.isCurrent(_session, accountId);

  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;
  final String accountId;

  bool _needsSync = false;
  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  ({int generation, bool ok}) _snapshot() {
    final generation = _session;
    return (
      generation: generation,
      ok: sessionGuard.isCurrent(generation, accountId) && !isDisposed,
    );
  }

  Future<void> load() async {
    if (isSaving || isLoading) return;
    final snap = _snapshot();
    if (!snap.ok) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }
      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
      _needsSync = false;
    } catch (error) {
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }

      errorMessage = favoriteErrorMessage(error);
    } finally {
      if (sessionGuard.isCurrent(snap.generation, accountId) && !isDisposed) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  Future<void> toggle() async {
    if (isSaving || isLoading || !hasLoadedStatus) return;
    if (_needsSync) {
      await load();
      return;
    }
    final snap = _snapshot();
    if (!snap.ok) return;
    final before = isFavorite;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (before) {
        await favoriteApi.deleteFavorite(movieId: movieId);
        if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
          return;
        }
        isFavorite = false;
      } else {
        await favoriteApi.addFavorite(movieId: movieId);
        if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
          return;
        }
        isFavorite = true;
      }
    } on DioException catch (error) {
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }
      // 이미 등록(409)이거나 이미 해제(404)이면 서버의 현재 여부로 화면을 맞춥니다.
      _needsSync = true;
      final code = apiErrorCode(error);
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        try {
          final synced = await favoriteApi.checkFavorite(movieId: movieId);
          if (!sessionGuard.isCurrent(snap.generation, accountId) ||
              isDisposed) {
            return;
          }
          _needsSync = false;
          isFavorite = synced.isFavorite;
          errorMessage = null;
        } catch (_) {
          if (!sessionGuard.isCurrent(snap.generation, accountId) ||
              isDisposed) {
            return;
          }
          isFavorite = before;
          errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
        }
      } else {
        isFavorite = before;
        errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
      }
    } catch (_) {
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }
      _needsSync = true;
      isFavorite = before;
      errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
    } finally {
      if (sessionGuard.isCurrent(snap.generation, accountId) && !isDisposed) {
        isSaving = false;
        notifyIfAlive();
      }
    }
  }
}
