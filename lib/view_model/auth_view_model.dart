import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../model/registration_model.dart';
import '../repository/auth_repository.dart';
import 'providers.dart';

const _sentinel = Object();

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.user, this.errorMessage});

  AuthState copyWith({
    bool? isLoading,
    Object? user = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user == _sentinel ? this.user : user as UserModel?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  late AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    Future<void>.microtask(_restoreSavedUser);
    return const AuthState();
  }

  Future<void> _restoreSavedUser() async {
    final user = await _authRepository.getSavedUser();
    if (user == null) return;
    state = state.copyWith(user: user);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.login(email, password);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPersonalInfo(
    String payroll,
    String dateOfBirth,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authRepository.getPersonalInfo(
        payroll,
        dateOfBirth,
      );
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> register(RegistrationModel registrationModel) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authRepository.register(registrationModel);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = state.copyWith(user: null);
  }

  Future<void> updateUser(UserModel user) async {
    await _authRepository.persistUser(user);
    state = state.copyWith(user: user);
  }

  Future<bool> checkLoginStatus() async {
    return await _authRepository.isLoggedIn();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
