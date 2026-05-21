import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staffportal/core/network/api_service.dart';
import 'package:staffportal/features/auth/data/auth_repository.dart';
import 'package:staffportal/features/requests/models/activity_request_rules.dart';
import 'package:staffportal/features/auth/models/staff_portal_access.dart';
import 'package:staffportal/features/community/data/peer_exchange_repository.dart';
import 'package:staffportal/features/profile/data/device_session_repository.dart';
import 'package:staffportal/features/profile/data/profile_records_repository.dart';
import 'package:staffportal/features/requests/data/staff_requests_repository.dart';
import 'package:staffportal/features/training/data/training_repository.dart';
import 'package:staffportal/features/auth/providers/auth_view_model.dart';
import 'package:staffportal/features/community/providers/peer_exchange_view_model.dart';
import 'package:staffportal/features/requests/providers/staff_request_view_model.dart';
import 'package:staffportal/features/training/providers/training_view_model.dart';
import 'package:staffportal/features/home/providers/user_view_model.dart';

final apiServiceProvider = Provider<ApiService>((_) => ApiService());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiServiceProvider)),
);

final peerExchangeRepositoryProvider = Provider<PeerExchangeRepository>(
  (_) => PeerExchangeRepository(),
);

final staffRequestsRepositoryProvider = Provider<StaffRequestsRepository>(
  (_) => StaffRequestsRepository(),
);

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (_) => TrainingRepository(),
);

final profileRecordsRepositoryProvider = Provider<ProfileRecordsRepository>(
  (_) => ProfileRecordsRepository(),
);

final deviceSessionRepositoryProvider = Provider<DeviceSessionRepository>(
  (_) => DeviceSessionRepository(),
);

final activityRequestRulesProvider = Provider<ActivityRequestRules>(
  (_) => const ActivityRequestRules(),
);

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(() {
  return AuthViewModel();
});

final staffPortalAccessProvider = Provider<StaffPortalAccess>((ref) {
  final authState = ref.watch(authViewModelProvider);
  return StaffPortalAccess.fromUser(
    authState.user,
    preferredMode: authState.activePortalMode,
  );
});

final peerExchangeViewModelProvider =
    NotifierProvider<PeerExchangeViewModel, PeerExchangeState>(() {
      return PeerExchangeViewModel();
    });

final staffRequestsViewModelProvider =
    NotifierProvider<StaffRequestsViewModel, StaffRequestsState>(() {
      return StaffRequestsViewModel();
    });

final trainingViewModelProvider =
    NotifierProvider<TrainingViewModel, TrainingState>(() {
      return TrainingViewModel();
    });

final userViewModelProvider =
    NotifierProvider<UserViewModel, UserDashboardState>(() {
      return UserViewModel();
    });
