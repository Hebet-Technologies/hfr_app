import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staffportal/utils/routes/routes.dart';
import 'package:staffportal/utils/routes/routes_name.dart';

import 'services/app_navigation_service.dart';
import 'services/push_notification_service.dart';
import 'services/realtime_service.dart';
import 'view_model/auth_view_model.dart';
import 'view_model/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  ProviderSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthState>(
      authViewModelProvider,
      (previous, next) async {
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
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: RoutesName.splash,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
