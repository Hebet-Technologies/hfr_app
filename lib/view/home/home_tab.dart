import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/staff_request_models.dart';
import '../../view_model/providers.dart';
import '../community/community_screen.dart';
import '../requests/requests_screen.dart';
import '../training/training_screen.dart';

const _homeBlue = Color(0xFF1F6BFF);
const _homeSurface = Color(0xFFF5F7FB);
const _homeCard = Colors.white;
const _homeText = Color(0xFF101828);
const _homeMuted = Color(0xFF6B7280);
const _homeBorder = Color(0xFFE8EEF6);

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final requestsState = ref.watch(staffRequestsViewModelProvider);
    final communityState = ref.watch(peerExchangeViewModelProvider);
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
                  actionLabel: '',
                  onTap: () {},
                  showAction: false,
                ),
                const SizedBox(height: 12),
                _AnnouncementCarousel(items: announcementItems),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Approval Queue',
                  actionLabel: 'Open Inbox',
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
                actionLabel: '',
                onTap: () {},
                showAction: false,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 142,
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
                title: 'Community Overview',
                actionLabel: 'See All',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CommunityScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _CommunitySummaryCard(
                title: 'My Groups',
                subtitle: communityState.groups.isNotEmpty
                    ? communityState.groups.first.title
                    : 'Infection Prevention Team',
                meta: communityState.groups.isNotEmpty
                    ? '${communityState.groups.first.usersCount} members'
                    : '18 Members',
                icon: Icons.groups_rounded,
              ),
              const SizedBox(height: 12),
              _CommunitySummaryCard(
                title: 'My Topics',
                subtitle: communityState.topics.isNotEmpty
                    ? communityState.topics.first.name
                    : 'Malaria Control Strategy',
                meta: communityState.topics.isNotEmpty
                    ? '${communityState.topics.first.commentsCount} posts'
                    : '14 posts',
                icon: Icons.topic_outlined,
              ),
              const SizedBox(height: 12),
              _CommunitySummaryCard(
                title: 'My Questions',
                subtitle: communityState.questions.isNotEmpty
                    ? communityState.questions.first.content
                    : 'How Can I Register A Group Activity?',
                meta: communityState.questions.isNotEmpty
                    ? '${communityState.questions.first.commentsCount} replies'
                    : '5 replies',
                icon: Icons.help_outline_rounded,
              ),
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

class _ApproverHeader extends StatelessWidget {
  const _ApproverHeader({
    required this.name,
    required this.role,
    required this.onNotificationsTap,
  });

  final String name;
  final String role;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFEAF2FF),
          child: Text(
            _initials(name),
            style: _homeTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _homeBlue,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: _homeTextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: _homeTextStyle(fontSize: 12, color: _homeMuted),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onNotificationsTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _homeBorder),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: _homeBlue,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _ApproverMetricsPanel extends StatelessWidget {
  const _ApproverMetricsPanel({
    required this.pendingCount,
    required this.overdueCount,
    required this.leaveCount,
  });

  final int pendingCount;
  final int overdueCount;
  final int leaveCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _homeBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ApproverMetricCell(
              icon: Icons.pending_actions_rounded,
              label: 'Pending Approvals',
              value: '$pendingCount requests',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ApproverMetricCell(
              icon: Icons.timer_outlined,
              label: 'Overdue Requests',
              value: '$overdueCount requests',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ApproverMetricCell(
              icon: Icons.event_note_rounded,
              label: 'Leave Requests',
              value: '$leaveCount pending',
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproverMetricCell extends StatelessWidget {
  const _ApproverMetricCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: _homeBlue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _homeTextStyle(
              fontSize: 10,
              color: _homeMuted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: _homeTextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCarousel extends StatefulWidget {
  const _AnnouncementCarousel({required this.items});

  final List<HomeAnnouncement> items;

  @override
  State<_AnnouncementCarousel> createState() => _AnnouncementCarouselState();
}

class _AnnouncementCarouselState extends State<_AnnouncementCarousel> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.94);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    return Column(
      children: [
        if (items.isEmpty)
          const _EmptyActivityCard(message: 'No announcements found')
        else
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _controller,
              itemCount: items.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CarouselAnnouncementCard(item: items[index]),
                );
              },
            ),
          ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              items.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == _page ? 14 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == _page ? _homeBlue : const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CarouselAnnouncementCard extends StatelessWidget {
  const _CarouselAnnouncementCard({required this.item});

  final HomeAnnouncement item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6FAFF), Color(0xFFE3EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E7FF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.caption,
                    style: _homeTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _homeBlue,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _homeTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _homeTextStyle(
                    fontSize: 11,
                    color: _homeMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 18,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFFFD9D6),
                    child: Icon(
                      Icons.campaign_outlined,
                      size: 16,
                      color: const Color(0xFFD64545),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  left: 18,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFFEAF2FF),
                    child: Icon(Icons.star_rounded, size: 12, color: _homeBlue),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  right: 18,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFFEAFBF1),
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: const Color(0xFF12B76A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproverQueueCard extends ConsumerWidget {
  const _ApproverQueueCard({required this.task});

  final ApprovalTask task;

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    ApproverAction action,
  ) async {
    var actionableTask = task;
    if (task.type == ApproverRequestType.leave) {
      try {
        actionableTask = await ref
            .read(staffRequestsViewModelProvider.notifier)
            .loadApprovalTaskDetail(task);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
          ),
        );
        return;
      }
    }
    if (!context.mounted) return;

    final result = await showModalBottomSheet<_HomeApprovalActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _HomeApprovalActionSheet(task: actionableTask, action: action),
    );

    if (result == null) return;

    try {
      final message = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .performApprovalAction(
            task: actionableTask,
            action: action,
            comment: result.comment,
            startDate: result.startDate,
            endDate: result.endDate,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffPortalAccessProvider);
    final requestState = ref.watch(staffRequestsViewModelProvider);
    final actions = _homeApprovalActionsFor(access, task);
    final hasApprove = actions.contains(ApproverAction.approve);
    final hasDeny = actions.contains(ApproverAction.deny);
    final hasForward = actions.contains(ApproverAction.forward);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ApprovalTaskDetailScreen(task: task),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _homeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.type == ApproverRequestType.leave
                        ? 'Leave Request'
                        : 'Transfer Request',
                    style: _homeTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _HomeStatusBadge(status: task.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: _homeMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  _approvalDateLabel(task),
                  style: _homeTextStyle(fontSize: 12, color: _homeMuted),
                ),
                const Spacer(),
                Text(
                  'Submitted by',
                  style: _homeTextStyle(fontSize: 11, color: _homeMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.referenceNumber ?? task.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _homeTextStyle(fontSize: 12, color: _homeMuted),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFFFF0D6),
                  child: Text(
                    _initials(task.subjectName),
                    style: _homeTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7A3E00),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    task.subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _homeTextStyle(fontSize: 12, color: _homeText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (hasApprove && hasDeny && !hasForward)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: requestState.isSubmitting
                          ? null
                          : () => _handleAction(
                              context,
                              ref,
                              ApproverAction.deny,
                            ),
                      style: _homeOutlinedDangerStyle(),
                      child: Text(
                        requestState.isSubmitting ? 'Submitting...' : 'Reject',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: _homeFilledStyle(),
                      onPressed: requestState.isSubmitting
                          ? null
                          : () => _handleAction(
                              context,
                              ref,
                              ApproverAction.approve,
                            ),
                      child: Text(
                        requestState.isSubmitting ? 'Submitting...' : 'Approve',
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ApprovalTaskDetailScreen(task: task),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _homeMuted,
                        side: const BorderSide(color: _homeBorder),
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View'),
                    ),
                  ),
                  if (hasForward) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: _homeFilledStyle(),
                        onPressed: requestState.isSubmitting
                            ? null
                            : () => _handleAction(
                                context,
                                ref,
                                ApproverAction.forward,
                              ),
                        child: Text(
                          requestState.isSubmitting
                              ? 'Submitting...'
                              : 'Forward',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ApproverRecentActivitiesPanel extends StatelessWidget {
  const _ApproverRecentActivitiesPanel({
    required this.records,
    required this.training,
  });

  final List<StaffRequestRecord> records;
  final HomeTrainingItem? training;

  @override
  Widget build(BuildContext context) {
    final items = <_ApproverRecentActivityItem>[
      ...records
          .take(2)
          .map(
            (record) => _ApproverRecentActivityItem(
              title: _recentActivityTitle(record),
              subtitle: record.title,
              trailing: _calendarOrRelativeLabel(record.submittedAt),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RequestDetailScreen(request: record),
                  ),
                );
              },
            ),
          ),
      if (training != null)
        _ApproverRecentActivityItem(
          title: 'Training Application Submitted',
          subtitle: training!.title,
          trailing: training!.dateLabel,
          onTap: () => openTrainingHubScreen(context),
        ),
    ];

    if (items.isEmpty) {
      return const _EmptyActivityCard(message: 'No recent activities yet');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _homeBorder),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            InkWell(
              onTap: items[index].onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[index].title,
                            style: _homeTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[index].subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _homeTextStyle(
                              fontSize: 11,
                              color: _homeMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      items[index].trailing,
                      style: _homeTextStyle(fontSize: 11, color: _homeMuted),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _homeMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (index != items.length - 1)
              const Divider(height: 1, color: Color(0xFFF2F4F7)),
          ],
        ],
      ),
    );
  }
}

class _ApproverRecentActivityItem {
  const _ApproverRecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;
}

class _HomeStatusBadge extends StatelessWidget {
  const _HomeStatusBadge({required this.status});

  final StaffRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _homeStatusSoft(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: _homeTextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _homeStatusColor(status),
        ),
      ),
    );
  }
}

class _HomeApprovalActionResult {
  const _HomeApprovalActionResult({
    required this.comment,
    this.startDate,
    this.endDate,
  });

  final String comment;
  final DateTime? startDate;
  final DateTime? endDate;
}

class _HomeApprovalActionSheet extends StatefulWidget {
  const _HomeApprovalActionSheet({required this.task, required this.action});

  final ApprovalTask task;
  final ApproverAction action;

  @override
  State<_HomeApprovalActionSheet> createState() =>
      _HomeApprovalActionSheetState();
}

class _HomeApprovalActionSheetState extends State<_HomeApprovalActionSheet> {
  final _commentController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _requiresDates =>
      widget.task.type == ApproverRequestType.leave &&
      widget.action == ApproverAction.approve;

  @override
  void initState() {
    super.initState();
    _startDate = widget.task.startDate ?? widget.task.proposedStartDate;
    _endDate = widget.task.endDate ?? widget.task.proposedEndDate;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment is required.')));
      return;
    }
    if (_requiresDates) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose approved start and end dates.')),
        );
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date cannot be earlier than start date.'),
          ),
        );
        return;
      }
    }

    Navigator.of(context).pop(
      _HomeApprovalActionResult(
        comment: comment,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${widget.action.label} ${widget.task.type.label}',
                style: _homeTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.task.subjectName,
                style: _homeTextStyle(fontSize: 12, color: _homeMuted),
              ),
              const SizedBox(height: 16),
              if (_requiresDates) ...[
                _HomeDateInputField(
                  label: 'Approved Start Date',
                  value: _startDate,
                  onTap: () async {
                    final picked = await _pickHomeDate(
                      context,
                      initial: _startDate,
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                _HomeDateInputField(
                  label: 'Approved End Date',
                  value: _endDate,
                  onTap: () async {
                    final picked = await _pickHomeDate(
                      context,
                      initial: _endDate ?? _startDate,
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                ),
              ],
              Text(
                'Comment',
                style: _homeTextStyle(fontSize: 12, color: _homeMuted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentController,
                maxLines: 4,
                style: _homeTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _homeInputDecoration('Enter comment'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: widget.action == ApproverAction.deny
                    ? OutlinedButton(
                        onPressed: _submit,
                        style: _homeOutlinedDangerStyle(),
                        child: Text(widget.action.label),
                      )
                    : FilledButton(
                        onPressed: _submit,
                        style: _homeFilledStyle(),
                        child: Text(widget.action.label),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDateInputField extends StatelessWidget {
  const _HomeDateInputField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _homeTextStyle(fontSize: 12, color: _homeMuted)),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: _homeInputDecoration('DD / MM / YYYY').copyWith(
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: _homeMuted,
                ),
              ),
              child: Text(
                value == null ? 'DD / MM / YYYY' : _formatHomeInputDate(value!),
                style: _homeTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value == null ? const Color(0xFF9CA3AF) : _homeText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.role,
    required this.onNotificationsTap,
    required this.primaryMetricLabel,
    required this.primaryMetricValue,
    required this.secondaryMetricLabel,
    required this.secondaryMetricValue,
    required this.tertiaryMetricLabel,
    required this.tertiaryMetricValue,
  });

  final String name;
  final String role;
  final VoidCallback onNotificationsTap;
  final String primaryMetricLabel;
  final String primaryMetricValue;
  final String secondaryMetricLabel;
  final String secondaryMetricValue;
  final String tertiaryMetricLabel;
  final String tertiaryMetricValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _homeBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFFF0D6),
                child: Text(
                  _initials(name),
                  style: _homeTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: _homeTextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: _homeTextStyle(fontSize: 12, color: _homeMuted),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onNotificationsTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _homeBorder),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: _homeBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: primaryMetricLabel,
                  value: primaryMetricValue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: secondaryMetricLabel,
                  value: secondaryMetricValue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: tertiaryMetricLabel,
                  value: tertiaryMetricValue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: _homeTextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _homeTextStyle(
              fontSize: 11,
              color: _homeMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillBanner extends StatelessWidget {
  const _PillBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: _homeTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _homeBlue,
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _homeBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(62),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _homeTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final HomeAnnouncement item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF5FF), Color(0xFFDCEBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -6,
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.caption,
                  style: _homeTextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _homeBlue,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                item.title,
                style: _homeTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                style: _homeTextStyle(
                  fontSize: 12,
                  color: _homeMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunitySummaryCard extends StatelessWidget {
  const _CommunitySummaryCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String meta;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _homeBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _homeBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _homeTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _homeMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _homeTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: _homeTextStyle(fontSize: 11, color: _homeMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.item});

  final HomeTrainingItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _homeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: _homeTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.tag,
                  style: _homeTextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE67E22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: _homeMuted,
              ),
              const SizedBox(width: 6),
              Text(
                item.dateLabel,
                style: _homeTextStyle(fontSize: 12, color: _homeMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: _homeMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.location,
                  style: _homeTextStyle(fontSize: 12, color: _homeMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _homeBlue,
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => openTrainingHubScreen(context),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({required this.record});

  final StaffRequestRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _homeBorder),
      ),
      child: Row(
        children: [
          Icon(_iconFor(record.type), color: _homeBlue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: _homeTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _homeTextStyle(fontSize: 11, color: _homeMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _relativeLabel(record.submittedAt),
            style: _homeTextStyle(fontSize: 11, color: _homeMuted),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _homeBorder),
      ),
      child: Text(
        message,
        style: _homeTextStyle(fontSize: 13, color: _homeMuted),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
    this.showAction = true,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: _homeTextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        if (showAction)
          TextButton(
            onPressed: onTap,
            child: Text(
              actionLabel,
              style: _homeTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _homeBlue,
              ),
            ),
          ),
      ],
    );
  }
}

InputDecoration _homeInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: _homeTextStyle(fontSize: 13, color: const Color(0xFF9CA3AF)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _homeBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _homeBlue),
    ),
  );
}

ButtonStyle _homeFilledStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _homeBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(42),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: _homeTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );
}

ButtonStyle _homeOutlinedDangerStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFFF04438),
    side: const BorderSide(color: Color(0xFFFDA29B)),
    minimumSize: const Size.fromHeight(42),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: _homeTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );
}

Future<DateTime?> _pickHomeDate(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
  );
}

String _formatHomeInputDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')} / ${value.month.toString().padLeft(2, '0')} / ${value.year.toString().padLeft(4, '0')}';
}

TextStyle _homeTextStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = _homeText,
  double? height,
}) {
  return GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

String _initials(String value) {
  final parts = value
      .split(' ')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'SP';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _relativeLabel(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inDays <= 0) return 'Today';
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays}d ago';
}

String _calendarOrRelativeLabel(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inDays <= 1) return _relativeLabel(dateTime);
  return '${_monthShort(dateTime.month)} ${dateTime.day}';
}

String _monthShort(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

String _approvalDateLabel(ApprovalTask task) {
  if (task.proposedStartDate != null && task.proposedEndDate != null) {
    return '${_formatCompactDate(task.proposedStartDate!)} - ${_formatCompactDate(task.proposedEndDate!)}';
  }
  if (task.proposedStartDate != null) {
    return _formatCompactDate(task.proposedStartDate!);
  }
  return _formatCompactDate(task.submittedAt);
}

String _formatCompactDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')} ${_monthShort(value.month)} ${value.year}';
}

String _recentActivityTitle(StaffRequestRecord record) {
  switch (record.status) {
    case StaffRequestStatus.approved:
      return '${record.type.label} Approved';
    case StaffRequestStatus.rejected:
      return '${record.type.label} Rejected';
    case StaffRequestStatus.withdrawn:
      return '${record.type.label} Withdrawn';
    case StaffRequestStatus.pending:
      return '${record.type.label} Submitted';
    case StaffRequestStatus.submitted:
      return '${record.type.label} Submitted';
  }
}

List<ApproverAction> _homeApprovalActionsFor(
  dynamic access,
  ApprovalTask task,
) {
  final isOpen = task.status.isOpen;
  switch (task.type) {
    case ApproverRequestType.leave:
      return [
        if (isOpen && access.canForwardLeave && !task.isFinalStage)
          ApproverAction.forward,
        if (isOpen && access.canApproveLeave && task.isFinalStage)
          ApproverAction.approve,
        if (isOpen && access.canDenyLeave && task.isFinalStage)
          ApproverAction.deny,
      ];
    case ApproverRequestType.transfer:
      return [
        if (isOpen && access.canForwardTransfer && !task.isFinalStage)
          ApproverAction.forward,
        if (isOpen && access.canApproveTransfer && task.isFinalStage)
          ApproverAction.approve,
        if (isOpen && access.canDenyTransfer && task.isFinalStage)
          ApproverAction.deny,
      ];
  }
}

Color _homeStatusColor(StaffRequestStatus status) {
  switch (status) {
    case StaffRequestStatus.approved:
      return const Color(0xFF12B76A);
    case StaffRequestStatus.rejected:
      return const Color(0xFFF04438);
    case StaffRequestStatus.pending:
      return const Color(0xFFF79009);
    case StaffRequestStatus.withdrawn:
      return const Color(0xFF667085);
    case StaffRequestStatus.submitted:
      return _homeBlue;
  }
}

Color _homeStatusSoft(StaffRequestStatus status) {
  switch (status) {
    case StaffRequestStatus.approved:
      return const Color(0xFFEAFBF1);
    case StaffRequestStatus.rejected:
      return const Color(0xFFFFEAEA);
    case StaffRequestStatus.pending:
      return const Color(0xFFFFF2E8);
    case StaffRequestStatus.withdrawn:
      return const Color(0xFFF2F4F7);
    case StaffRequestStatus.submitted:
      return const Color(0xFFEAF2FF);
  }
}

IconData _iconFor(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.activity:
      return Icons.assignment_turned_in_outlined;
    case StaffRequestType.leave:
      return Icons.event_available_rounded;
    case StaffRequestType.transfer:
      return Icons.compare_arrows_rounded;
    case StaffRequestType.loan:
      return Icons.account_balance_wallet_outlined;
    case StaffRequestType.sickLeave:
      return Icons.medical_services_outlined;
  }
}
