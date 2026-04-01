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
    final user = authState.user;
    final displayName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Staff Member';
    final roleLabel = _resolveRoleLabel(user);
    final training = requestsState.trainings.isNotEmpty
        ? requestsState.trainings.first
        : null;

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
                pendingCount: requestsState.pendingCount,
                leaveBalanceDays: requestsState.leaveBalanceDays,
                trainingCount: requestsState.trainings.length,
              ),
              const SizedBox(height: 10),
              _PillBanner(
                text:
                    '${requestsState.activityCountThisMonth} activities this month',
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Quick Actions',
                actionLabel: '',
                onTap: () {},
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
                  itemCount: requestsState.announcements.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = requestsState.announcements[index];
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
              _TrainingCard(
                item:
                    training ??
                    const HomeTrainingItem(
                      title: 'Maternal Health Capacity Training',
                      location: 'Zanzibar Health Training Institute',
                      dateLabel: '12/03/2026',
                      tag: 'Internal',
                    ),
              ),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Recent Activities',
                actionLabel: '',
                onTap: () {},
                showAction: false,
              ),
              const SizedBox(height: 12),
              if (requestsState.recentRecords.isEmpty)
                _EmptyActivityCard(message: 'No recent activities yet')
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.role,
    required this.onNotificationsTap,
    required this.pendingCount,
    required this.leaveBalanceDays,
    required this.trainingCount,
  });

  final String name;
  final String role;
  final VoidCallback onNotificationsTap;
  final int pendingCount;
  final int leaveBalanceDays;
  final int trainingCount;

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
                  label: 'Pending Requests',
                  value: '$pendingCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Leave Balance',
                  value: '$leaveBalanceDays days',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Upcoming Training',
                  value: '$trainingCount',
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
