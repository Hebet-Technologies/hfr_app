import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;

import '../data/network/api_service.dart';
import '../repository/auth_repository.dart';
import '../repository/peer_exchange_repository.dart';
import '../repository/staff_requests_repository.dart';
import '../repository/training_repository.dart';
import 'auth_view_model.dart';
import 'login_view_model.dart';
import 'peer_exchange_view_model.dart';
import 'staff_request_view_model.dart';
import 'training_view_model.dart';
import 'user_view_model.dart';

final apiServiceProvider = Provider<ApiService>((_) => ApiService());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiServiceProvider)),
);

final peerExchangeRepositoryProvider = Provider<PeerExchangeRepository>(
  (_) => PeerExchangeRepository(),
);

final staffRequestsRepositoryProvider = Provider<StaffRequestsRepository>(
  (ref) => StaffRequestsRepository(ref.watch(authRepositoryProvider)),
);

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => TrainingRepository(ref.watch(authRepositoryProvider)),
);

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(() {
  return AuthViewModel();
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

final userViewModelProvider = ChangeNotifierProvider<UserViewModel>(
  (ref) => UserViewModel(ref.watch(authRepositoryProvider)),
);

final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>(
  (ref) => LoginViewModel(ref.watch(authRepositoryProvider)),
);
