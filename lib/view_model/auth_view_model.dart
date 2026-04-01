import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/staff_portal_access.dart';
import '../model/user_model.dart';
import '../model/registration_model.dart';
import '../repository/auth_repository.dart';
import 'providers.dart';

const _sentinel = Object();

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;
  final StaffPortalMode activePortalMode;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.activePortalMode = StaffPortalMode.employee,
  });

  AuthState copyWith({
    bool? isLoading,
    Object? user = _sentinel,
    Object? errorMessage = _sentinel,
    StaffPortalMode? activePortalMode,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user == _sentinel ? this.user : user as UserModel?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      activePortalMode: activePortalMode ?? this.activePortalMode,
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  late AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    Future<void>.microtask(_restoreSavedSession);
    return const AuthState();
  }

  Future<void> _restoreSavedSession() async {
    final user = await _authRepository.getSavedUser();
    final savedMode = await _authRepository.getSavedActivePortalMode();
    if (user == null) {
      state = state.copyWith(activePortalMode: StaffPortalMode.employee);
      return;
    }

    final access = StaffPortalAccess.fromUser(user, preferredMode: savedMode);
    state = state.copyWith(user: user, activePortalMode: access.activeMode);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.login(email, password);
      final access = StaffPortalAccess.fromUser(
        user,
        preferredMode: state.activePortalMode,
      );
      await _authRepository.persistActivePortalMode(access.activeMode);
      state = state.copyWith(
        isLoading: false,
        user: user,
        activePortalMode: access.activeMode,
      );
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
    state = state.copyWith(
      user: null,
      activePortalMode: StaffPortalMode.employee,
    );
  }

  Future<void> updateUser(UserModel user) async {
    await _authRepository.persistUser(user);
    final access = StaffPortalAccess.fromUser(
      user,
      preferredMode: state.activePortalMode,
    );
    await _authRepository.persistActivePortalMode(access.activeMode);
    state = state.copyWith(user: user, activePortalMode: access.activeMode);
  }

  Future<void> setActivePortalMode(StaffPortalMode mode) async {
    final access = StaffPortalAccess.fromUser(state.user, preferredMode: mode);
    await _authRepository.persistActivePortalMode(access.activeMode);
    state = state.copyWith(activePortalMode: access.activeMode);
  }

  Future<bool> checkLoginStatus() async {
    return await _authRepository.isLoggedIn();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
