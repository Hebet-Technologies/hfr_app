import 'package:flutter/material.dart';

import '../utils/routes/routes_name.dart';
import '../view/community/community_screen.dart';

class AppNavigationService {
  AppNavigationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get _navigator => navigatorKey.currentState;

  static Future<void> openRoute({
    required String? routeName,
    required Map<String, dynamic> routeParams,
    String? title,
  }) async {
    final navigator = _navigator;
    if (navigator == null || routeName == null || routeName.trim().isEmpty) {
      return;
    }

    switch (routeName.trim()) {
      case 'conversation.show':
        final conversationUuid =
            routeParams['conversation_uuid']?.toString().trim() ?? '';
        if (conversationUuid.isEmpty) {
          await navigator.pushNamed(RoutesName.home);
          return;
        }

        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationDetailScreen(
              conversationUuid: conversationUuid,
              title: (title ?? '').trim().isEmpty ? 'Conversation' : title!.trim(),
              isGroup: false,
            ),
          ),
        );
        return;
      default:
        await navigator.pushNamed(RoutesName.home);
        return;
    }
  }
}
