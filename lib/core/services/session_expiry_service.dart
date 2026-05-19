import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:staffportal/core/routing/routes_name.dart';
import 'app_navigation_service.dart';
import 'app_session_store.dart';
import 'push_notification_service.dart';
import 'realtime_service.dart';

class SessionExpiryService {
  SessionExpiryService._();

  static bool _isHandling = false;
  static final StreamController<void> _expiredController =
      StreamController<void>.broadcast();

  static Stream<void> get expired => _expiredController.stream;

  static Future<void> handleUnauthorized() async {
    if (_isHandling) return;
    _isHandling = true;

    try {
      await AppSessionStore.clearAuthSession();
      await RealtimeService.instance.disconnect();
      await PushNotificationService.instance.clearSessionBinding();
      _expiredController.add(null);

      final navigator = AppNavigationService.navigatorKey.currentState;
      final messenger = AppNavigationService.navigatorKey.currentContext == null
          ? null
          : ScaffoldMessenger.maybeOf(
              AppNavigationService.navigatorKey.currentContext!,
            );
      if (messenger != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Your session has expired. Please sign in again.'),
          ),
        );
      }

      navigator?.pushNamedAndRemoveUntil(RoutesName.login, (route) => false);
    } catch (error) {
      log('Failed to handle unauthorized session: $error', name: 'AUTH');
    } finally {
      Future<void>.delayed(const Duration(seconds: 2), () {
        _isHandling = false;
      });
    }
  }
}
