import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staffportal/features/profile/models/device_session_models.dart';
import 'package:staffportal/features/profile/models/profile_details.dart';
import 'package:staffportal/features/auth/models/user_model.dart';
import 'package:staffportal/core/providers/app_providers.dart';

final profileDetailsProvider = FutureProvider.autoDispose<ProfileDetails>((
  ref,
) async {
  final user = ref.watch(authViewModelProvider).user;
  if (user == null) {
    throw Exception('Please sign in again.');
  }

  return ref.watch(authRepositoryProvider).fetchProfileDetails(user);
});

final profileActionsProvider = Provider<ProfileActions>(
  (ref) => ProfileActions(ref),
);

final userDeviceSessionsProvider =
    FutureProvider.autoDispose<List<UserDeviceSession>>((ref) {
      return ref.watch(deviceSessionRepositoryProvider).fetchDevices();
    });

final deviceSessionActionsProvider = Provider<DeviceSessionActions>(
  (ref) => DeviceSessionActions(ref),
);

class ProfileActions {
  const ProfileActions(this._ref);

  final Ref _ref;

  ProfileDetails fallbackDetails(UserModel user) {
    return ProfileDetails.fromUser(user);
  }

  Future<void> updateProfile(ProfileDetails details) async {
    final user = _ref.read(authViewModelProvider).user;
    if (user == null) {
      throw Exception('Please sign in again.');
    }

    await _ref.read(authRepositoryProvider).updatePersonalProfile(details);
    await _ref
        .read(authViewModelProvider.notifier)
        .updateUser(details.applyToUser(user));
    _ref.invalidate(profileDetailsProvider);
  }
}

class DeviceSessionActions {
  const DeviceSessionActions(this._ref);

  final Ref _ref;

  Future<void> revoke(UserDeviceSession session) async {
    final repository = _ref.read(deviceSessionRepositoryProvider);
    if ((session.deviceUuid ?? '').trim().isNotEmpty) {
      await repository.deleteDevice(session.deviceUuid!);
    } else {
      await repository.deleteSession(session.id);
    }
    _ref.invalidate(userDeviceSessionsProvider);
  }
}
