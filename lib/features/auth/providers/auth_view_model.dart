import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staffportal/features/auth/models/staff_portal_access.dart';
import 'package:staffportal/features/auth/models/user_model.dart';
import 'package:staffportal/features/auth/models/registration_model.dart';
import 'package:staffportal/features/auth/data/auth_repository.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/providers/app_providers.dart';

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
    if (user == null) {
      state = state.copyWith(activePortalMode: StaffPortalMode.employee);
      return;
    }

    final savedMode = await _authRepository.getSavedActivePortalMode();
    final access = StaffPortalAccess.fromUser(user, preferredMode: savedMode);
    state = state.copyWith(user: user, activePortalMode: access.activeMode);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.login(email, password);
      final access = StaffPortalAccess.fromUser(user);

      // if (user.personalInformationId.trim().isEmpty) {
      //   throw Exception('User Information not found');
      // }
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
        errorMessage: friendlyErrorMessage(e),
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
        errorMessage: friendlyErrorMessage(e),
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
        errorMessage: friendlyErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    clearSession();
  }

  void clearSession() {
    state = state.copyWith(
      user: null,
      errorMessage: null,
      isLoading: false,
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
