import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staffportal/core/routing/routes.dart';
import 'package:staffportal/core/routing/routes_name.dart';

import 'package:staffportal/core/providers/app_providers.dart';
import 'package:staffportal/core/services/app_navigation_service.dart';
import 'package:staffportal/core/services/push_notification_service.dart';
import 'package:staffportal/core/services/realtime_service.dart';
import 'package:staffportal/core/services/session_expiry_service.dart';
import 'package:staffportal/features/auth/providers/auth_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
  unawaited(PushNotificationService.instance.initialize());
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  ProviderSubscription<AuthState>? _authSubscription;
  StreamSubscription<void>? _sessionExpirySubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthState>(authViewModelProvider, (
      previous,
      next,
    ) async {
      final previousToken = previous?.user?.token;
      final nextUser = next.user;

      if (nextUser == null) {
        if (previousToken != null) {
          await RealtimeService.instance.disconnect();
          await PushNotificationService.instance.clearSessionBinding();
        }
        return;
      }

      if (previousToken == nextUser.token) {
        return;
      }

      await PushNotificationService.instance.handleAuthenticatedSession(
        nextUser,
      );
      await RealtimeService.instance.connect(nextUser);
    }, fireImmediately: true);
    _sessionExpirySubscription = SessionExpiryService.expired.listen((_) {
      ref.read(authViewModelProvider.notifier).clearSession();
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _sessionExpirySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF101828),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF101828)),
          actionsIconTheme: IconThemeData(color: Color(0xFF101828)),
        ),
      ),
      initialRoute: RoutesName.splash,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
