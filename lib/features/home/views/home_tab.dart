import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:staffportal/core/network/api_service.dart';
import 'package:staffportal/features/requests/models/staff_request_models.dart';
import 'package:staffportal/features/training/models/training_models.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/utils/url_resolver.dart';
import 'package:staffportal/core/providers/app_providers.dart';
import 'package:staffportal/features/community/views/community_screen.dart';
import 'package:staffportal/features/requests/views/requests_screen.dart';
import 'package:staffportal/features/training/views/training_screen.dart';

part '../widgets/home_tab_widgets.dart';

const _homeBlue = Color(0xFF1F6BFF);
const _homeSurface = Color(0xFFF5F7FB);
const _homeCard = Colors.white;
const _homeText = Color(0xFF101828);
const _homeMuted = Color(0xFF6B7280);
const _homeBorder = Color(0xFFE8EEF6);

void openAnnouncementDetailsScreen(
  BuildContext context,
  HomeAnnouncement announcement,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AnnouncementDetailsScreen(announcement: announcement),
    ),
  );
}

void openAnnouncementsScreen(
  BuildContext context,
  List<HomeAnnouncement> announcements,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AnnouncementsScreen(announcements: announcements),
    ),
  );
}

void openResourcesScreen(
  BuildContext context, {
  List<HomeResource> resources = const [],
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ResourcesScreen(resources: resources),
    ),
  );
}

void openCommunityScreen(
  BuildContext context, {
  CommunityInitialSection initialSection = CommunityInitialSection.overview,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CommunityScreen(initialSection: initialSection),
    ),
  );
}

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final requestsState = ref.watch(staffRequestsViewModelProvider);
    final communityState = ref.watch(peerExchangeViewModelProvider);
    final hasCommunityOverviewData =
        communityState.groups.isNotEmpty ||
        communityState.topics.isNotEmpty ||
        communityState.questions.isNotEmpty;
    final access = ref.watch(staffPortalAccessProvider);
    final user = authState.user;
    final displayName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Staff Member';
    final isApproverMode = access.hasRequestApproverAccess;
    final roleLabel = _resolveRoleLabel(user);
    final training = requestsState.trainings.isNotEmpty
        ? requestsState.trainings.first
        : null;
    final announcementItems = requestsState.announcements.take(3).toList();
    final approvalItems = [
      ...requestsState.leaveApprovalTasks,
      ...requestsState.transferApprovalTasks,
    ]..sort((first, second) => second.submittedAt.compareTo(first.submittedAt));
    final overdueApprovals = approvalItems
        .where(
          (item) =>
              item.status.isOpen &&
              item.submittedAt.isBefore(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
        )
        .length;

    if (isApproverMode) {
      return Scaffold(
        backgroundColor: _homeSurface,
        body: SafeArea(
          child: RefreshIndicator(
            color: _homeBlue,
            onRefresh: () async {
              await ref.read(staffRequestsViewModelProvider.notifier).refresh();
              await ref.read(peerExchangeViewModelProvider.notifier).loadAll();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _ApproverHeader(
                  name: displayName,
                  role: roleLabel,
                  onNotificationsTap: () {},
                ),
                const SizedBox(height: 16),
                _ApproverMetricsPanel(
                  pendingCount: requestsState.totalApprovalCount,
                  overdueCount: overdueApprovals,
                  leaveCount: requestsState.leaveApprovalTasks.length,
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Announcements',
                  actionLabel: 'See All',
                  onTap: () => openAnnouncementsScreen(
                    context,
                    requestsState.announcements,
                  ),
                ),
                const SizedBox(height: 12),
                _AnnouncementCarousel(
                  items: announcementItems,
                  isLoading:
                      requestsState.isLoading &&
                      requestsState.announcements.isEmpty,
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Resources',
                  actionLabel: 'See All',
                  onTap: () => openResourcesScreen(
                    context,
                    resources: requestsState.resources,
                  ),
                ),
                const SizedBox(height: 12),
                if (requestsState.isLoading && requestsState.resources.isEmpty)
                  const _ResourceListShimmer()
                else if (requestsState.resources.isEmpty)
                  const _EmptyActivityCard(
                    message: 'No resources are available right now.',
                  )
                else
                  ...requestsState.resources
                      .take(2)
                      .map(
                        (resource) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ResourceListTile(resource: resource),
                        ),
                      ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Approval Queue',
                  actionLabel: 'See more',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const RequestsScreen(initialShowApprovals: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (approvalItems.isEmpty)
                  const _EmptyActivityCard(
                    message: 'No approval items are waiting right now.',
                  )
                else
                  ...approvalItems
                      .take(3)
                      .map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ApproverQueueCard(task: task),
                        ),
                      ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Recent Activities',
                  actionLabel: '',
                  onTap: () {},
                  showAction: false,
                ),
                const SizedBox(height: 12),
                _ApproverRecentActivitiesPanel(
                  records: requestsState.recentRecords,
                  training: training,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _homeSurface,
      body: SafeArea(
        child: RefreshIndicator(
          color: _homeBlue,
          onRefresh: () async {
            await ref.read(staffRequestsViewModelProvider.notifier).refresh();
            await ref.read(peerExchangeViewModelProvider.notifier).loadAll();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _ProfileHero(
                name: displayName,
                role: roleLabel,
                onNotificationsTap: () {},
                primaryMetricLabel: 'Pending Requests',
                primaryMetricValue: '${requestsState.pendingCount}',
                secondaryMetricLabel: 'Leave Balance',
                secondaryMetricValue: '${requestsState.leaveBalanceDays} days',
                tertiaryMetricLabel: 'Upcoming Training',
                tertiaryMetricValue: '${requestsState.trainings.length}',
              ),
              const SizedBox(height: 10),
              _PillBanner(
                text:
                    '${requestsState.activityCountThisMonth} activities this month',
              ),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'Quick Actions',
                actionLabel: '',
                onTap: _noop,
                showAction: false,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Register\nActivity',
                      onTap: () => openRequestFormScreen(
                        context,
                        StaffRequestType.activity,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.event_available_rounded,
                      label: 'Apply\nLeave',
                      onTap: () => openRequestFormScreen(
                        context,
                        StaffRequestType.leave,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.compare_arrows_rounded,
                      label: 'Request\nTransfer',
                      onTap: () => openRequestFormScreen(
                        context,
                        StaffRequestType.transfer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Announcements',
                actionLabel: 'See All',
                onTap: () => openAnnouncementsScreen(
                  context,
                  requestsState.announcements,
                ),
              ),
              const SizedBox(height: 12),
              if (requestsState.isLoading &&
                  requestsState.announcements.isEmpty)
                const _AnnouncementListShimmer()
              else if (announcementItems.isEmpty)
                const _EmptyActivityCard(message: 'No announcements found')
              else
                SizedBox(
                  height: 158,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: announcementItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = announcementItems[index];
                      return _AnnouncementCard(item: item);
                    },
                  ),
                ),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Resources',
                actionLabel: 'See All',
                onTap: () => openResourcesScreen(
                  context,
                  resources: requestsState.resources,
                ),
              ),
              const SizedBox(height: 12),
              if (requestsState.isLoading && requestsState.resources.isEmpty)
                const _ResourceListShimmer()
              else if (requestsState.resources.isEmpty)
                const _EmptyActivityCard(message: 'No resources found')
              else
                ...requestsState.resources
                    .take(3)
                    .map(
                      (resource) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ResourceListTile(resource: resource),
                      ),
                    ),
              if (communityState.isLoading || hasCommunityOverviewData) ...[
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Community Overview',
                  actionLabel: 'See All',
                  onTap: () => openCommunityScreen(context),
                ),
                const SizedBox(height: 12),
                if (communityState.isLoading && !hasCommunityOverviewData)
                  const _CommunitySummaryShimmer()
                else ...[
                  if (communityState.groups.isNotEmpty) ...[
                    _CommunitySummaryCard(
                      title: 'My Groups',
                      subtitle: communityState.groups.first.title,
                      meta: '${communityState.groups.first.usersCount} members',
                      icon: Icons.groups_rounded,
                      onTap: () => openCommunityScreen(
                        context,
                        initialSection: CommunityInitialSection.groups,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (communityState.topics.isNotEmpty) ...[
                    _CommunitySummaryCard(
                      title: 'My Topics',
                      subtitle: communityState.topics.first.name,
                      meta:
                          '${communityState.topics.first.commentsCount} posts',
                      icon: Icons.topic_outlined,
                      onTap: () => openCommunityScreen(
                        context,
                        initialSection: CommunityInitialSection.topics,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (communityState.questions.isNotEmpty)
                    _CommunitySummaryCard(
                      title: 'My Questions',
                      subtitle: communityState.questions.first.content,
                      meta:
                          '${communityState.questions.first.commentsCount} replies',
                      icon: Icons.help_outline_rounded,
                      onTap: () => openCommunityScreen(
                        context,
                        initialSection: CommunityInitialSection.questions,
                      ),
                    ),
                ],
              ],
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Upcoming Training',
                actionLabel: 'See All',
                onTap: () => openTrainingHubScreen(context),
              ),
              const SizedBox(height: 12),
              if (training != null)
                _TrainingCard(item: training)
              else
                const _EmptyActivityCard(message: 'No upcoming training found'),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Recent Activities',
                actionLabel: '',
                onTap: () {},
                showAction: false,
              ),
              const SizedBox(height: 12),
              if (requestsState.recentRecords.isEmpty)
                const _EmptyActivityCard(message: 'No recent activities yet')
              else
                ...requestsState.recentRecords.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentActivityTile(record: record),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveRoleLabel(dynamic user) {
    if (user == null) return 'Staff';
    if ((user.workingStationType ?? '').toString().trim().isNotEmpty) {
      return user.workingStationType.toString().trim();
    }
    if (user.roles is List<String> && (user.roles as List<String>).isNotEmpty) {
      return (user.roles as List<String>).first.replaceAll('ROLE ', '').trim();
    }
    return 'Staff';
  }
}

void _noop() {}
