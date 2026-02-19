import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/session_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((_) {
  return const FlutterSecureStorage();
});

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref.watch(secureStorageProvider));
});

class AuthState {
  const AuthState({
    required this.initialized,
    required this.isAuthenticated,
  });

  final bool initialized;
  final bool isAuthenticated;

  AuthState copyWith({bool? initialized, bool? isAuthenticated}) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._sessionService)
      : super(const AuthState(initialized: false, isAuthenticated: false));

  final SessionService _sessionService;

  Future<void> bootstrap() async {
    final hasSession = await _sessionService.hasSession();
    state = state.copyWith(initialized: true, isAuthenticated: hasSession);
  }

  Future<void> loginWithOtp(
      {required String accessToken, required String refreshToken}) async {
    await _sessionService.saveSession(
        accessToken: accessToken, refreshToken: refreshToken);
    state = state.copyWith(isAuthenticated: true, initialized: true);
  }

  Future<void> logout() async {
    await _sessionService.clearSession();
    state = state.copyWith(isAuthenticated: false, initialized: true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(sessionServiceProvider));
  Future<void>.microtask(controller.bootstrap);
  return controller;
});
