import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;

import '../data/network/api_service.dart';
import '../repository/auth_repository.dart';
import '../repository/peer_exchange_repository.dart';
import 'auth_view_model.dart';
import 'login_view_model.dart';
import 'peer_exchange_view_model.dart';
import 'user_view_model.dart';

final apiServiceProvider = Provider<ApiService>((_) => ApiService());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiServiceProvider)),
);

final peerExchangeRepositoryProvider = Provider<PeerExchangeRepository>(
  (_) => PeerExchangeRepository(),
);

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(() {
  return AuthViewModel();
});

final peerExchangeViewModelProvider =
    NotifierProvider<PeerExchangeViewModel, PeerExchangeState>(() {
      return PeerExchangeViewModel();
    });

final userViewModelProvider = ChangeNotifierProvider<UserViewModel>(
  (ref) => UserViewModel(ref.watch(authRepositoryProvider)),
);

final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>(
  (ref) => LoginViewModel(ref.watch(authRepositoryProvider)),
);
