import 'package:flutter/material.dart';

import 'package:staffportal/features/requests/models/staff_request_models.dart';
import 'package:staffportal/core/routing/routes_name.dart';
import 'package:staffportal/features/community/views/community_screen.dart';
import 'package:staffportal/features/home/views/home_tab.dart';
import 'package:staffportal/features/requests/views/requests_screen.dart';

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
              title: (title ?? '').trim().isEmpty
                  ? 'Conversation'
                  : title!.trim(),
              isGroup: false,
            ),
          ),
        );
        return;
      case 'announcement.show':
        final announcementUuid =
            routeParams['announcement_uuid']?.toString().trim() ?? '';
        if (announcementUuid.isEmpty) {
          await navigator.pushNamed(RoutesName.home);
          return;
        }

        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => AnnouncementDetailsScreen(
              announcement: HomeAnnouncement(
                announcementUuid: announcementUuid,
                title: (title ?? '').trim().isEmpty
                    ? 'Announcement'
                    : title!.trim(),
                subtitle: '',
                caption: 'announcement',
                type: 'general',
                isLive: true,
              ),
            ),
          ),
        );
        return;
      case 'resource.show':
        final resourceUuid =
            routeParams['resource_uuid']?.toString().trim() ?? '';
        if (resourceUuid.isEmpty) {
          await navigator.pushNamed(RoutesName.home);
          return;
        }

        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ResourceDetailsScreen(
              resource: HomeResource(
                uuid: resourceUuid,
                title: (title ?? '').trim().isEmpty
                    ? 'Resource'
                    : title!.trim(),
                subtitle: '',
                status: 'active',
                attachments: const [],
                isLive: true,
              ),
            ),
          ),
        );
        return;
      case 'topic.show':
      case 'question.show':
        await navigator.push(
          MaterialPageRoute<void>(builder: (_) => const CommunityScreen()),
        );
        return;
      case 'leave.show':
      case 'loan.show':
      case 'sick_sheet.show':
      case 'staff_activity.show':
        await navigator.push(
          MaterialPageRoute<void>(builder: (_) => const RequestsScreen()),
        );
        return;
      default:
        await navigator.pushNamed(RoutesName.home);
        return;
    }
  }
}
