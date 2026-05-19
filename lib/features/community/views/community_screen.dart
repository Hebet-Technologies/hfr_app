import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:staffportal/core/network/api_service.dart';
import 'package:staffportal/features/community/models/peer_exchange_access.dart';
import 'package:staffportal/features/community/models/peer_exchange_models.dart';
import 'package:staffportal/core/services/realtime_service.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import '../providers/peer_exchange_view_model.dart';
import 'package:staffportal/core/providers/app_providers.dart';
import 'package:staffportal/core/widgets/app_svg_icon.dart';

part '../widgets/community_widgets.dart';

const _peerPrimary = Color(0xFF1F6BFF);
const _peerBackground = Color(0xFFF7F9FC);
const _peerCard = Colors.white;
const _peerBorder = Color(0xFFE9EEF5);
const _peerText = Color(0xFF101828);
const _peerMuted = Color(0xFF667085);
const _peerSoftBlue = Color(0xFFEAF2FF);
const _peerSoftGreen = Color(0xFFE8FFF1);
const _peerSoftOrange = Color(0xFFFFF1E6);
const _qaToolbarHeight = 40.0;

enum _CommunitySection {
  overview('Community'),
  inbox('Messages'),
  groups('Groups'),
  questions('Q&A Forum'),
  topics('Topics');

  const _CommunitySection(this.label);
  final String label;
}

enum CommunityInitialSection { overview, inbox, groups, questions, topics }

extension on CommunityInitialSection {
  _CommunitySection get section {
    switch (this) {
      case CommunityInitialSection.overview:
        return _CommunitySection.overview;
      case CommunityInitialSection.inbox:
        return _CommunitySection.inbox;
      case CommunityInitialSection.groups:
        return _CommunitySection.groups;
      case CommunityInitialSection.questions:
        return _CommunitySection.questions;
      case CommunityInitialSection.topics:
        return _CommunitySection.topics;
    }
  }
}

enum _ItemMenuAction { edit, delete }

class _CommunityLoadingShimmer extends StatelessWidget {
  const _CommunityLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return _CommunityShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CommunitySkeletonBox(width: 160, height: 24, radius: 8),
          const SizedBox(height: 14),
          const _CommunitySkeletonBox(height: 46, radius: 14),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _CommunitySkeletonBox(height: 82, radius: 14)),
              SizedBox(width: 10),
              Expanded(child: _CommunitySkeletonBox(height: 82, radius: 14)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            4,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
              child: const _CommunitySkeletonBox(height: 88, radius: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityShimmer extends StatefulWidget {
  const _CommunityShimmer({required this.child});

  final Widget child;

  @override
  State<_CommunityShimmer> createState() => _CommunityShimmerState();
}

class _CommunityShimmerState extends State<_CommunityShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = -1.0 + (_controller.value * 2.0);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(position - 1, 0),
              end: Alignment(position + 1, 0),
              colors: const [
                Color(0xFFE9EEF5),
                Color(0xFFF8FBFF),
                Color(0xFFE9EEF5),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _CommunitySkeletonBox extends StatelessWidget {
  const _CommunitySkeletonBox({
    this.width,
    required this.height,
    required this.radius,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({
    super.key,
    this.initialSection = CommunityInitialSection.overview,
  });

  final CommunityInitialSection initialSection;

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late _CommunitySection _section;
  DateTime? _selectedQuestionDay;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection.section;
    _searchController.addListener(_handleSearchChange);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChange)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChange() {
    if (mounted) {
      setState(() {});
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref
          .read(peerExchangeViewModelProvider.notifier)
          .setSearchQuery(_searchController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(peerExchangeViewModelProvider);
    final currentUser = ref.watch(
      authViewModelProvider.select((authState) => authState.user),
    );

    final portalAccess = ref.watch(staffPortalAccessProvider);
    final access = PeerExchangeAccess.fromUser(
      currentUser,
      isApproverOverride: portalAccess.hasRequestApproverAccess,
    );
    final currentUserName = currentUser?.fullName.trim() ?? '';
    final directConversations = state.conversations
        .where((conversation) => !conversation.isGroup)
        .toList();
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text('Community'),
    //     backgroundColor: _peerPrimary,
    //     foregroundColor: Colors.white,
    //   ),
    //   body: Center(child: Text('Community')),
    // );

    final isQuestionSection = _section == _CommunitySection.questions;

    if (state.isLoading &&
        state.groups.isEmpty &&
        state.questions.isEmpty &&
        state.topics.isEmpty &&
        state.conversations.isEmpty) {
      return Scaffold(
        backgroundColor: _peerBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: const _CommunityLoadingShimmer(),
          ),
        ),
      );
    }

    if (state.errorMessage != null &&
        state.groups.isEmpty &&
        state.questions.isEmpty &&
        state.topics.isEmpty &&
        state.conversations.isEmpty) {
      return Scaffold(
        backgroundColor: _peerBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _EmptyStateCard(
              title: 'Peer exchange could not load',
              subtitle: state.errorMessage!,
              actionLabel: 'Try again',
              onTap: () =>
                  ref.read(peerExchangeViewModelProvider.notifier).loadAll(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isQuestionSection ? Colors.white : _peerBackground,
      floatingActionButton:
          !isQuestionSection && _canPerformPrimaryAction(access)
          ? FloatingActionButton(
              heroTag: 'community-${_section.name}-fab',
              onPressed: () => _handlePrimaryAction(state),
              backgroundColor: _peerPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              tooltip: _actionLabelForSection(),
              child: const Icon(Icons.add_rounded, size: 24),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: _peerPrimary,
          onRefresh: () =>
              ref.read(peerExchangeViewModelProvider.notifier).loadAll(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isQuestionSection ? 12 : 16,
                    8,
                    isQuestionSection ? 12 : 16,
                    110,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(state, access),
                      SizedBox(height: isQuestionSection ? 12 : 14),
                      _buildSearchRow(state),
                      if (isQuestionSection &&
                          (state.selectedCategoryUuid != null ||
                              _selectedQuestionDay != null)) ...[
                        const SizedBox(height: 12),
                        _buildQuestionFilterSummary(state),
                      ],
                      const SizedBox(height: 14),
                      if (state.errorMessage != null) ...[
                        _buildErrorBanner(state.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      _buildSectionBody(
                        state,
                        directConversations,
                        access,
                        currentUserName,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PeerExchangeState state, PeerExchangeAccess access) {
    final isOverview = _section == _CommunitySection.overview;
    final isQuestionSection = _section == _CommunitySection.questions;
    final title = isOverview
        ? 'Community'
        : isQuestionSection
        ? 'Q&A'
        : _section.label;

    if (isQuestionSection) {
      return SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _QuestionHeaderIconButton(
                onTap: () =>
                    setState(() => _section = _CommunitySection.overview),
              ),
            ),
            Text(
              title,
              style: _textStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: access.canAskQuestions
                  ? _HeaderActionButton(
                      label: 'Ask Question',
                      onTap: () => _handlePrimaryAction(state),
                    )
                  : const SizedBox(width: 118),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (!isOverview)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _SquareIconButton(
              icon: const AppSvgIcon(
                assetName: 'assets/icons/back_arrow.svg',
                color: _peerText,
                size: 18,
              ),
              onTap: () =>
                  setState(() => _section = _CommunitySection.overview),
            ),
          ),
        Expanded(
          child: Text(
            title,
            style: _textStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow(PeerExchangeState _) {
    final isQuestionSection = _section == _CommunitySection.questions;
    final searchField = Expanded(
      child: Container(
        height: isQuestionSection ? _qaToolbarHeight : 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isQuestionSection ? 12 : 14),
          border: Border.all(color: _peerBorder),
        ),
        child: TextField(
          controller: _searchController,
          style: _textStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: _textStyle(fontSize: 13, color: const Color(0xFF98A2B3)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(14),
              child: AppSvgIcon(
                assetName: 'assets/icons/search.svg',
                color: Color(0xFFA4A4A4),
                size: 18,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: isQuestionSection
                ? _QuestionSearchSuffix(
                    showClear: _searchController.text.isNotEmpty,
                    onClear: () {
                      _searchController.clear();
                      ref
                          .read(peerExchangeViewModelProvider.notifier)
                          .setSearchQuery('');
                    },
                  )
                : _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(peerExchangeViewModelProvider.notifier)
                          .setSearchQuery('');
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _peerMuted,
                    ),
                  ),
          ),
        ),
      ),
    );

    return Row(children: [searchField]);
  }

  Widget _buildSectionBody(
    PeerExchangeState state,
    List<PeerConversation> directConversations,
    PeerExchangeAccess access,
    String currentUserName,
  ) {
    switch (_section) {
      case _CommunitySection.overview:
        return _buildOverview(
          state,
          directConversations,
          access,
          currentUserName,
        );
      case _CommunitySection.inbox:
        return _buildChats(directConversations, access);
      case _CommunitySection.groups:
        return _buildGroups(state.groups, access);
      case _CommunitySection.questions:
        return _buildQuestions(state, access, currentUserName);
      case _CommunitySection.topics:
        return _buildTopics(state, access);
    }
  }

  Widget _buildOverview(
    PeerExchangeState state,
    List<PeerConversation> directConversations,
    PeerExchangeAccess access,
    String currentUserName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewShortcuts(state, directConversations),
        const SizedBox(height: 18),
        _buildOverviewSection(
          title: 'Messages',
          onTap: () => setState(() => _section = _CommunitySection.inbox),
          child: directConversations.isEmpty
              ? _EmptyStateCard(
                  title: 'No messages yet',
                  subtitle: access.canStartDirectChats
                      ? 'Start a new chat.'
                      : 'No chats available.',
                )
              : Column(
                  children: directConversations
                      .take(4)
                      .map(_buildConversationPreviewTile)
                      .toList(),
                ),
        ),
        const SizedBox(height: 22),
        _buildOverviewSection(
          title: 'Groups',
          onTap: () => setState(() => _section = _CommunitySection.groups),
          child: state.groups.isEmpty
              ? _EmptyStateCard(
                  title: 'No groups available',
                  subtitle: _canCreateGroups(access)
                      ? 'Create a group.'
                      : 'No groups yet.',
                )
              : Column(
                  children: state.groups
                      .take(2)
                      .map(_buildGroupPreviewTile)
                      .toList(),
                ),
        ),
        const SizedBox(height: 22),
        _buildOverviewSection(
          title: 'Q&A Forum',
          onTap: () => setState(() => _section = _CommunitySection.questions),
          child: state.questions.isEmpty
              ? const _EmptyStateCard(
                  title: 'No forum questions yet',
                  subtitle: 'Questions will appear here.',
                )
              : _buildOverviewQuestionCard(
                  state.questions.first,
                  access,
                  currentUserName,
                ),
        ),
        const SizedBox(height: 22),
        _buildOverviewSection(
          title: 'Topics',
          onTap: () => setState(() => _section = _CommunitySection.topics),
          child: state.topics.isEmpty
              ? _EmptyStateCard(
                  title: 'No topics published',
                  subtitle: _canCreateTopics(access)
                      ? 'Create a topic.'
                      : 'No topics yet.',
                )
              : _buildOverviewTopicCard(state.topics.first, access),
        ),
      ],
    );
  }

  Widget _buildOverviewShortcuts(
    PeerExchangeState state,
    List<PeerConversation> directConversations,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _OverviewShortcutCard(
                title: 'Messages',
                subtitle: _countLabel(
                  directConversations.length,
                  singular: 'chat',
                  plural: 'chats',
                ),
                icon: Icons.chat_bubble_outline_rounded,
                background: _peerSoftBlue,
                accent: _peerPrimary,
                onTap: () => setState(() => _section = _CommunitySection.inbox),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewShortcutCard(
                title: 'Groups',
                subtitle: _countLabel(
                  state.groups.length,
                  singular: 'group',
                  plural: 'groups',
                ),
                icon: Icons.groups_2_outlined,
                background: _peerSoftGreen,
                accent: const Color(0xFF039855),
                onTap: () =>
                    setState(() => _section = _CommunitySection.groups),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewShortcutCard(
                title: 'Q&A',
                subtitle: _countLabel(
                  state.questions.length,
                  singular: 'question',
                  plural: 'questions',
                ),
                icon: Icons.help_outline_rounded,
                background: _peerSoftOrange,
                accent: const Color(0xFFFF8D42),
                onTap: () =>
                    setState(() => _section = _CommunitySection.questions),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewShortcutCard(
                title: 'Topics',
                subtitle: _countLabel(
                  state.topics.length,
                  singular: 'topic',
                  plural: 'topics',
                ),
                icon: Icons.article_outlined,
                background: const Color(0xFFEEF4FF),
                accent: const Color(0xFF175CD3),
                onTap: () =>
                    setState(() => _section = _CommunitySection.topics),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewSection({
    required String title,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, actionLabel: 'See All', onTap: onTap),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildConversationPreviewTile(PeerConversation conversation) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openConversation(conversation),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _peerSoftBlue,
              child: Text(
                _initials(conversation.title),
                style: _textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _peerPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      fontSize: 13,
                      color: _peerMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatRelative(conversation.lastMessageAt),
              style: _textStyle(fontSize: 12, color: _peerMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupPreviewTile(PeerConversation group) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openConversation(group, isGroup: true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _peerCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _peerBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _peerSoftBlue,
                  child: Text(
                    _initials(group.title),
                    style: _textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _peerPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(fontSize: 13, color: _peerMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatRelative(group.lastMessageAt),
                  style: _textStyle(fontSize: 12, color: _peerMuted),
                ),
              ],
            ),
            if (group.users.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MemberPreviewRow(members: group.users),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                '${group.usersCount} members',
                style: _textStyle(fontSize: 12, color: _peerMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewQuestionCard(
    PeerQuestion question,
    PeerExchangeAccess access,
    String currentUserName,
  ) {
    return _buildQuestionCard(question, access, currentUserName);
  }

  Widget _buildOverviewTopicCard(PeerTopic topic, PeerExchangeAccess access) {
    return _buildTopicCard(topic, access);
  }

  Widget _buildQuestions(
    PeerExchangeState state,
    PeerExchangeAccess access,
    String currentUserName,
  ) {
    final questions = state.questions
        .where(_matchesSelectedQuestionDate)
        .toList();

    if (questions.isEmpty) {
      final hasActiveFilter =
          state.selectedCategoryUuid != null || _selectedQuestionDay != null;

      return _EmptyStateCard(
        title: hasActiveFilter
            ? 'No questions match these filters'
            : 'No questions here yet',
        subtitle: hasActiveFilter
            ? 'Try another category or clear the selected date.'
            : 'Ask one to get things started.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions
          .map(
            (question) => _buildQuestionCard(question, access, currentUserName),
          )
          .toList(),
    );
  }

  Widget _buildTopics(PeerExchangeState state, PeerExchangeAccess access) {
    if (state.topics.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          ...state.topics.map((topic) => _buildTopicCard(topic, access)),
        ],
      );
    }

    if (state.topics.isEmpty) {
      return _EmptyStateCard(
        title: 'No topics yet',
        subtitle: _canCreateTopics(access)
            ? 'Create the first topic.'
            : 'Topics will show here when shared.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGroups(
    List<PeerConversation> groups,
    PeerExchangeAccess access,
  ) {
    if (groups.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          ...groups.map((group) => _buildGroupCard(group, access)),
        ],
      );
    }

    if (groups.isEmpty) {
      return _EmptyStateCard(
        title: 'No groups yet',
        subtitle: _canCreateGroups(access)
            ? 'Create the first group.'
            : 'Groups will appear here when shared with you.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildChats(
    List<PeerConversation> conversations,
    PeerExchangeAccess access,
  ) {
    if (conversations.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          ...conversations.map(_buildConversationCard),
        ],
      );
    }

    if (conversations.isEmpty) {
      return _EmptyStateCard(
        title: 'No messages yet',
        subtitle: access.canStartDirectChats
            ? 'Start a new chat.'
            : 'Sign in to chat.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGroupCard(PeerConversation group, PeerExchangeAccess access) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openConversation(group, isGroup: true),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _peerCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _peerBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: _peerSoftBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(group.title),
                      style: _textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _peerPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: _textStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _textStyle(
                            fontSize: 13,
                            color: _peerMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatRelative(group.lastMessageAt),
                        style: _textStyle(fontSize: 12, color: _peerMuted),
                      ),
                      if (_canEditGroup(access, group) ||
                          _canDeleteGroup(access, group)) ...[
                        const SizedBox(width: 4),
                        _buildEntityMenu(
                          showEdit: _canEditGroup(access, group),
                          showDelete: _canDeleteGroup(access, group),
                          onSelected: (action) async {
                            switch (action) {
                              case _ItemMenuAction.edit:
                                await _showEditGroupSheet(group);
                                return;
                              case _ItemMenuAction.delete:
                                await _deleteGroup(group);
                                return;
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (group.users.isNotEmpty) ...[
                _MemberPreviewRow(members: group.users),
              ] else ...[
                Text(
                  '${group.usersCount} members',
                  style: _textStyle(fontSize: 12, color: _peerMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    PeerQuestion question,
    PeerExchangeAccess access,
    String currentUserName,
  ) {
    final askedBy = _questionAuthorName(question, access, currentUserName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openQuestion(question),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF1)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFF8D42)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.help_outline_rounded,
                      size: 13,
                      color: Color(0xFFFF8D42),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (_canEditQuestion(access, question))
                    _buildEntityMenu(
                      onSelected: (action) async {
                        switch (action) {
                          case _ItemMenuAction.edit:
                            await _showEditQuestionSheet(question);
                            return;
                          case _ItemMenuAction.delete:
                            await _deleteQuestion(question);
                            return;
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: _peerBorder),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuestionInfoColumn(
                      label: 'Asked by',
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: _peerSoftBlue,
                            child: Text(
                              _initials(askedBy),
                              style: _textStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _peerPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              askedBy,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _textStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _QuestionInfoColumn(
                    label: 'Replies',
                    crossAxisAlignment: CrossAxisAlignment.end,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: _peerMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${question.commentsCount}',
                          style: _textStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicCard(PeerTopic topic, PeerExchangeAccess access) {
    final updatedBy =
        topic.lastComment?.author?.fullName.trim().isNotEmpty == true
        ? topic.lastComment!.author!.fullName
        : 'Team lead';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openTopic(topic),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _peerCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _peerBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: _peerSoftBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.article_outlined,
                      size: 16,
                      color: _peerPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      topic.name,
                      style: _textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: _peerBorder),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InfoColumn(label: 'Updated by', value: updatedBy),
                  ),
                  Expanded(
                    child: _InfoColumn(
                      label: 'Posts',
                      value: '${topic.commentsCount}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationCard(PeerConversation conversation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openConversation(conversation),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _peerCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _peerBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _peerSoftBlue,
                child: Text(
                  _initials(conversation.title),
                  style: _textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _peerPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.title,
                            style: _textStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          _formatRelative(conversation.lastMessageAt),
                          style: _textStyle(fontSize: 12, color: _peerMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      conversation.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        fontSize: 13,
                        color: _peerMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntityMenu({
    required Future<void> Function(_ItemMenuAction action) onSelected,
    bool showEdit = true,
    bool showDelete = true,
  }) {
    final items = <PopupMenuItem<_ItemMenuAction>>[
      if (showEdit)
        const PopupMenuItem<_ItemMenuAction>(
          value: _ItemMenuAction.edit,
          child: Text('Edit'),
        ),
      if (showDelete)
        const PopupMenuItem<_ItemMenuAction>(
          value: _ItemMenuAction.delete,
          child: Text('Delete'),
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<_ItemMenuAction>(
      icon: const Icon(Icons.more_horiz_rounded, color: _peerMuted, size: 20),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (action) async => onSelected(action),
      itemBuilder: (context) => items,
    );
  }

  PeerExchangeAccess _currentAccess() {
    final user = ref.read(authViewModelProvider).user;
    final portalAccess = ref.read(staffPortalAccessProvider);
    return PeerExchangeAccess.fromUser(
      user,
      isApproverOverride: portalAccess.hasRequestApproverAccess,
    );
  }

  bool _canPerformPrimaryAction(PeerExchangeAccess access) {
    switch (_section) {
      case _CommunitySection.overview:
        return access.canStartDirectChats || access.canAskQuestions;
      case _CommunitySection.inbox:
        return access.canStartDirectChats;
      case _CommunitySection.groups:
        return _canCreateGroups(access);
      case _CommunitySection.questions:
        return access.canAskQuestions;
      case _CommunitySection.topics:
        return _canCreateTopics(access);
    }
  }

  bool _canCreateGroups(PeerExchangeAccess access) {
    return access.canCreateGroups;
  }

  bool _canEditGroup(PeerExchangeAccess access, PeerConversation group) {
    return access.canEditGroup(group.createdBy);
  }

  bool _canDeleteGroup(PeerExchangeAccess access, PeerConversation group) {
    return access.canDeleteGroup(group.createdBy);
  }

  bool _canCreateTopics(PeerExchangeAccess access) {
    final requestAccess = ref.read(staffPortalAccessProvider);
    return requestAccess.hasRequestApproverAccess;
  }

  bool _canEditQuestion(PeerExchangeAccess access, PeerQuestion question) {
    return access.canEditQuestion(question.createdBy);
  }

  PeerQuestionCategory? _selectedQuestionCategory(PeerExchangeState state) {
    final selectedUuid = state.selectedCategoryUuid;
    if (selectedUuid == null) return null;

    for (final category in state.categories) {
      if (category.uuid == selectedUuid) return category;
    }

    return null;
  }

  Widget _buildQuestionFilterSummary(PeerExchangeState state) {
    final selectedCategory = _selectedQuestionCategory(state);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (selectedCategory != null)
          _SelectionChip(
            label: selectedCategory.name,
            onRemove: () {
              ref
                  .read(peerExchangeViewModelProvider.notifier)
                  .selectCategory(null);
            },
          ),
        if (_selectedQuestionDay != null)
          _SelectionChip(
            label: _formatDateChip(_selectedQuestionDay!),
            onRemove: () => setState(() => _selectedQuestionDay = null),
          ),
      ],
    );
  }

  bool _matchesSelectedQuestionDate(PeerQuestion question) {
    final selectedDay = _selectedQuestionDay;
    if (selectedDay == null) return true;

    final date =
        question.createdAt ?? question.updatedAt ?? question.lastCommentAt;
    if (date == null) return false;

    return _isSameDay(date, selectedDay);
  }

  String _questionAuthorName(
    PeerQuestion question,
    PeerExchangeAccess access,
    String currentUserName,
  ) {
    final authorName = question.author?.fullName.trim() ?? '';
    if (authorName.isNotEmpty) return authorName;
    if (access.isOwner(question.createdBy) && currentUserName.isNotEmpty) {
      return currentUserName;
    }
    return access.isOwner(question.createdBy) ? 'You' : 'Team member';
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDCAD4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFD92D20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: _textStyle(
                fontSize: 13,
                color: const Color(0xFFB42318),
                height: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(peerExchangeViewModelProvider.notifier).clearError();
            },
            child: Text(
              'Dismiss',
              style: _textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD92D20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openQuestion(PeerQuestion question) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionDetailScreen(question: question),
      ),
    );

    if (mounted) {
      await ref.read(peerExchangeViewModelProvider.notifier).loadAll();
    }
  }

  Future<void> _openTopic(PeerTopic topic) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TopicDetailScreen(topic: topic)));

    if (mounted) {
      await ref.read(peerExchangeViewModelProvider.notifier).loadAll();
    }
  }

  Future<void> _openConversation(
    PeerConversation conversation, {
    bool isGroup = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationDetailScreen(
          conversationUuid: conversation.uuid,
          title: conversation.title,
          isGroup: isGroup || conversation.isGroup,
        ),
      ),
    );

    if (mounted) {
      await ref.read(peerExchangeViewModelProvider.notifier).loadAll();
    }
  }

  String _actionLabelForSection() {
    switch (_section) {
      case _CommunitySection.overview:
        return 'New';
      case _CommunitySection.inbox:
        return 'New Chat';
      case _CommunitySection.groups:
        return 'New Group';
      case _CommunitySection.questions:
        return 'Ask Question';
      case _CommunitySection.topics:
        return 'New Topic';
    }
  }

  String _countLabel(
    int count, {
    required String singular,
    required String plural,
  }) {
    final label = count == 1 ? singular : plural;
    return '$count $label';
  }

  Future<void> _handlePrimaryAction(PeerExchangeState state) async {
    final access = _currentAccess();
    switch (_section) {
      case _CommunitySection.overview:
        await _showOverviewActionsSheet();
        return;
      case _CommunitySection.inbox:
        if (!access.canStartDirectChats) {
          _showMessage(
            'Direct messaging is not available for your role.',
            error: true,
          );
          return;
        }
        await _showCreateConversationSheet();
        return;
      case _CommunitySection.groups:
        if (!_canCreateGroups(access)) {
          _showMessage(
            'You do not have permission to create groups.',
            error: true,
          );
          return;
        }
        await _showCreateGroupSheet();
        return;
      case _CommunitySection.questions:
        if (!access.canAskQuestions) {
          _showMessage(
            'Question posting is not available for your role.',
            error: true,
          );
          return;
        }
        await _showCreateQuestionSheet(state);
        return;
      case _CommunitySection.topics:
        if (!_canCreateTopics(access)) {
          _showMessage(
            'Only approvers, moderators, and HR admins can create moderated topics.',
            error: true,
          );
          return;
        }
        await _showCreateTopicSheet();
        return;
    }
  }

  Future<void> _showOverviewActionsSheet() async {
    final access = _currentAccess();
    final requestAccess = ref.read(staffPortalAccessProvider);
    final actions = <Widget>[
      if (access.canAskQuestions)
        _ActionTile(
          title: 'Ask a question',
          subtitle: 'Post a knowledge or practice question.',
          onTap: () {
            Navigator.pop(context);
            _showCreateQuestionSheet(ref.read(peerExchangeViewModelProvider));
          },
        ),
      if (requestAccess.hasRequestApproverAccess)
        _ActionTile(
          title: 'Create a topic',
          subtitle: 'Open a structured discussion for your team.',
          onTap: () {
            Navigator.pop(context);
            _showCreateTopicSheet();
          },
        ),
      if (requestAccess.hasRequestApproverAccess)
        _ActionTile(
          title: 'Create a group',
          subtitle: 'Set up a shared room for a team or activity.',
          onTap: () {
            Navigator.pop(context);
            _showCreateGroupSheet();
          },
        ),
      if (access.canStartDirectChats)
        _ActionTile(
          title: 'Start a chat',
          subtitle: 'Open a one-to-one conversation by receiver ID.',
          onTap: () {
            Navigator.pop(context);
            _showCreateConversationSheet();
          },
        ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BottomSheetTitle(
                title: 'Create something new',
                subtitle: 'Choose what you want to start inside peer exchange.',
              ),
              if (actions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: _EmptyStateCard(
                    title: 'No create actions available',
                    subtitle:
                        'Your current role has view or participation access only in this module.',
                  ),
                )
              else
                ...actions,
            ],
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _showManageCategoriesSheet(PeerExchangeState state) async {
    final access = _currentAccess();
    if (!access.canManageQuestionCategories) {
      _showMessage(
        'Question categories are managed by approvers, moderators, and HR admins.',
        error: true,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final currentState = ref.watch(peerExchangeViewModelProvider);

            return _BottomSheetCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BottomSheetTitle(
                    title: 'Manage categories',
                    subtitle:
                        'Create, rename, or remove question categories used by the Q&A forum.',
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: currentState.categories.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text('No categories available yet.'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: currentState.categories.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final category = currentState.categories[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category.name,
                                            style: _textStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            category.isActive
                                                ? 'Active category'
                                                : 'Inactive category',
                                            style: _textStyle(
                                              fontSize: 12,
                                              color: _peerMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        _showCreateCategorySheet(
                                          category: category,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: _peerPrimary,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        if (!sheetContext.mounted) return;
                                        Navigator.pop(sheetContext);
                                        await _deleteQuestionCategory(category);
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFD92D20),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: state.categories.isEmpty
                        ? 'Create first category'
                        : 'Add category',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showCreateCategorySheet();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateCategorySheet({
    PeerQuestionCategory? category,
  }) async {
    final access = _currentAccess();
    if (!access.canManageQuestionCategories) {
      _showMessage('Your role cannot manage question categories.', error: true);
      return;
    }

    final controller = TextEditingController(text: category?.name ?? '');
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _BottomSheetCard(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BottomSheetTitle(
                      title: category == null
                          ? 'New question category'
                          : 'Edit question category',
                      subtitle: category == null
                          ? 'Create a category to organize peer questions.'
                          : 'Rename this category for the Q&A forum.',
                    ),
                    _FormField(
                      controller: controller,
                      label: 'Category name',
                      hintText: 'Example: Clinical practice',
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isSaving ? 'Saving...' : 'Save category',
                      isBusy: isSaving,
                      onTap: isSaving
                          ? null
                          : () async {
                              final name = controller.text.trim();
                              if (name.isEmpty) {
                                _showMessage(
                                  'Enter a category name.',
                                  error: true,
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                final repository = ref.read(
                                  peerExchangeRepositoryProvider,
                                );
                                if (category == null) {
                                  await repository.createQuestionCategory(
                                    name: name,
                                  );
                                } else {
                                  await repository.updateQuestionCategory(
                                    categoryUuid: category.uuid,
                                    name: name,
                                  );
                                }
                                if (!mounted || !sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                await ref
                                    .read(
                                      peerExchangeViewModelProvider.notifier,
                                    )
                                    .loadAll();
                                _showMessage(
                                  category == null
                                      ? 'Question category created.'
                                      : 'Question category updated.',
                                );
                              } catch (error) {
                                if (!mounted) return;
                                _showMessage(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                  error: true,
                                );
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<PeerDirectoryPerson?> _showSingleStaffPicker({
    required String title,
  }) async {
    final selected = await _showStaffPickerSheet(
      title: title,
      multiSelect: false,
    );
    if (selected == null || selected.isEmpty) return null;
    return selected.first;
  }

  Future<List<PeerDirectoryPerson>?> _showMultiStaffPicker({
    required String title,
    List<PeerDirectoryPerson> initialSelection = const [],
  }) {
    return _showStaffPickerSheet(
      title: title,
      multiSelect: true,
      initialSelection: initialSelection,
    );
  }

  Future<List<PeerDirectoryPerson>?> _showStaffPickerSheet({
    required String title,
    required bool multiSelect,
    List<PeerDirectoryPerson> initialSelection = const [],
  }) async {
    final queryController = TextEditingController();
    final repository = ref.read(peerExchangeRepositoryProvider);
    Future<List<PeerDirectoryPerson>> directoryFuture = multiSelect
        ? repository.fetchStaffDirectory()
        : repository.fetchConversationUsers();
    final selected = <int, PeerDirectoryPerson>{
      for (final person in initialSelection) person.id: person,
    };

    return showModalBottomSheet<List<PeerDirectoryPerson>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _BottomSheetCard(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BottomSheetTitle(
                      title: title,
                      subtitle: multiSelect
                          ? 'Pick the people you want in this group.'
                          : 'Choose who you want to message.',
                    ),
                    _FormField(
                      controller: queryController,
                      label: 'Search staff',
                      hintText: 'Search by name, role, or email',
                      onChanged: (value) {
                        if (multiSelect) {
                          setModalState(() {});
                          return;
                        }

                        setModalState(() {
                          directoryFuture = repository.fetchConversationUsers(
                            search: value.trim(),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<PeerDirectoryPerson>>(
                      future: directoryFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: _peerPrimary,
                              ),
                            ),
                          );
                        }

                        final people =
                            snapshot.data ?? const <PeerDirectoryPerson>[];
                        final query = queryController.text.trim().toLowerCase();
                        final filtered = multiSelect
                            ? people.where((person) {
                                if (query.isEmpty) return true;
                                final haystack = [
                                  person.fullName,
                                  person.subtitle,
                                  person.email,
                                ].join(' ').toLowerCase();
                                return haystack.contains(query);
                              }).toList()
                            : people;

                        if (filtered.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              query.isEmpty
                                  ? 'No staff found.'
                                  : 'No match for your search.',
                              style: _textStyle(
                                fontSize: 13,
                                color: _peerMuted,
                              ),
                            ),
                          );
                        }

                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final person = filtered[index];
                              final isSelected = selected.containsKey(
                                person.id,
                              );

                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  if (multiSelect) {
                                    setModalState(() {
                                      if (isSelected) {
                                        selected.remove(person.id);
                                      } else {
                                        selected[person.id] = person;
                                      }
                                    });
                                  } else {
                                    Navigator.pop(sheetContext, [person]);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _peerSoftBlue
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? _peerPrimary
                                          : const Color(0xFFE4E7EC),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _peerSoftBlue,
                                        child: Text(
                                          _initials(person.fullName),
                                          style: _textStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: _peerPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              person.fullName,
                                              style: _textStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              person.subtitle,
                                              style: _textStyle(
                                                fontSize: 12,
                                                color: _peerMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        multiSelect
                                            ? (isSelected
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined)
                                            : Icons.chevron_right_rounded,
                                        color: isSelected
                                            ? _peerPrimary
                                            : _peerMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    if (multiSelect) ...[
                      const SizedBox(height: 16),
                      _PrimaryButton(
                        label: selected.isEmpty
                            ? 'Choose people'
                            : 'Use selection',
                        onTap: selected.isEmpty
                            ? null
                            : () => Navigator.pop(
                                sheetContext,
                                selected.values.toList(),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateQuestionSheet(PeerExchangeState state) async {
    final access = _currentAccess();
    if (!access.canAskQuestions) {
      _showMessage('Your role cannot post questions.', error: true);
      return;
    }

    if (state.categories.isEmpty) {
      _showMessage(
        access.canManageQuestionCategories
            ? 'Create a question category first so questions can be classified.'
            : 'No question category is available yet. Ask a moderator or approver to create one.',
        error: true,
      );
      if (access.canManageQuestionCategories) {
        await _showCreateCategorySheet();
      }
      return;
    }

    final contentController = TextEditingController();
    String selectedCategoryUuid =
        state.selectedCategoryUuid ?? state.categories.first.uuid;
    List<PlatformFile> selectedFiles = const [];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, _) {
                final isSubmitting = ref.watch(
                  peerExchangeViewModelProvider.select(
                    (current) => current.isSubmitting,
                  ),
                );

                return _BottomSheetCard(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BottomSheetTitle(
                          title: 'Ask a question',
                          subtitle:
                              'Share a practice, service, or operational question.',
                        ),
                        _DropdownField<String>(
                          label: 'Category',
                          value: selectedCategoryUuid,
                          items: state.categories
                              .map(
                                (category) => DropdownMenuItem<String>(
                                  value: category.uuid,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() => selectedCategoryUuid = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        _FormField(
                          controller: contentController,
                          label: 'Question',
                          hintText: 'What do you need help with?',
                          maxLines: 5,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final picked = await _pickPeerFiles(
                                        context,
                                        existing: selectedFiles,
                                      );
                                      if (!sheetContext.mounted) return;
                                      setModalState(
                                        () => selectedFiles = picked,
                                      );
                                    },
                              icon: const Icon(Icons.attach_file_rounded),
                              label: Text(
                                selectedFiles.isEmpty
                                    ? 'Add attachments'
                                    : 'Add more files',
                              ),
                            ),
                            ...selectedFiles.map(
                              (file) => _AttachmentChip(
                                fileName: file.name,
                                fileSize: file.size,
                                onRemove: isSubmitting
                                    ? null
                                    : () => setModalState(() {
                                        selectedFiles = selectedFiles
                                            .where(
                                              (item) =>
                                                  !(item.path == file.path &&
                                                      item.name == file.name),
                                            )
                                            .toList();
                                      }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _PrimaryButton(
                          label: isSubmitting ? 'Posting...' : 'Post question',
                          isBusy: isSubmitting,
                          onTap: isSubmitting
                              ? null
                              : () async {
                                  final content = contentController.text.trim();
                                  if (content.isEmpty) {
                                    _showMessage(
                                      'Enter your question first.',
                                      error: true,
                                    );
                                    return;
                                  }

                                  final attachments =
                                      await _platformFilesToMultipart(
                                        selectedFiles,
                                      );
                                  final created = await ref
                                      .read(
                                        peerExchangeViewModelProvider.notifier,
                                      )
                                      .createQuestion(
                                        categoryUuid: selectedCategoryUuid,
                                        content: content,
                                        attachments: attachments,
                                      );

                                  if (created == null || !mounted) return;
                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                  _showMessage('Question posted successfully.');
                                },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateTopicSheet() async {
    final access = _currentAccess();
    if (!_canCreateTopics(access)) {
      _showMessage(
        'Only approvers, moderators, and HR admins can create topics.',
        error: true,
      );
      return;
    }

    final audienceOptions = await _loadTopicAudienceOptions();
    if (audienceOptions == null || !mounted) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final selectedCadreIds = <int>{};
    final selectedDepartmentIds = <int>{};
    final selectedLocationIds = <int>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, _) {
                final isSubmitting = ref.watch(
                  peerExchangeViewModelProvider.select(
                    (state) => state.isSubmitting,
                  ),
                );

                return _BottomSheetCard(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BottomSheetTitle(
                          title: 'Create a topic',
                          subtitle:
                              'Open a guided discussion for a team or practice area.',
                        ),
                        _FormField(
                          controller: titleController,
                          label: 'Topic name',
                          hintText: 'Example: Safe referral workflow',
                        ),
                        const SizedBox(height: 14),
                        _FormField(
                          controller: descriptionController,
                          label: 'Description',
                          hintText: 'Add the purpose or focus of this topic',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Audience filters',
                          style: _textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Leave all filters empty to publish the topic to everyone, or narrow it by cadre, department, or location.',
                          style: _textStyle(
                            fontSize: 12,
                            color: _peerMuted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AudiencePickerField(
                          label: 'Cadres',
                          selectedLabels: _selectedAudienceLabels(
                            selectedCadreIds,
                            audienceOptions.cadres,
                          ),
                          onTap: () async {
                            final selected = await _pickTopicAudienceIds(
                              title: 'Select cadres',
                              options: audienceOptions.cadres,
                              initialSelectedIds: selectedCadreIds,
                            );
                            if (selected == null || !sheetContext.mounted) {
                              return;
                            }
                            setModalState(() {
                              selectedCadreIds
                                ..clear()
                                ..addAll(selected);
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _AudiencePickerField(
                          label: 'Departments',
                          selectedLabels: _selectedAudienceLabels(
                            selectedDepartmentIds,
                            audienceOptions.departments,
                          ),
                          onTap: () async {
                            final selected = await _pickTopicAudienceIds(
                              title: 'Select departments',
                              options: audienceOptions.departments,
                              initialSelectedIds: selectedDepartmentIds,
                            );
                            if (selected == null || !sheetContext.mounted) {
                              return;
                            }
                            setModalState(() {
                              selectedDepartmentIds
                                ..clear()
                                ..addAll(selected);
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _AudiencePickerField(
                          label: 'Locations',
                          selectedLabels: _selectedAudienceLabels(
                            selectedLocationIds,
                            audienceOptions.locations,
                          ),
                          onTap: () async {
                            final selected = await _pickTopicAudienceIds(
                              title: 'Select locations',
                              options: audienceOptions.locations,
                              initialSelectedIds: selectedLocationIds,
                            );
                            if (selected == null || !sheetContext.mounted) {
                              return;
                            }
                            setModalState(() {
                              selectedLocationIds
                                ..clear()
                                ..addAll(selected);
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        _PrimaryButton(
                          label: isSubmitting ? 'Creating...' : 'Create topic',
                          isBusy: isSubmitting,
                          onTap: isSubmitting
                              ? null
                              : () async {
                                  final name = titleController.text.trim();
                                  final description = descriptionController.text
                                      .trim();
                                  if (name.isEmpty) {
                                    _showMessage(
                                      'Enter a topic name.',
                                      error: true,
                                    );
                                    return;
                                  }

                                  final created = await ref
                                      .read(
                                        peerExchangeViewModelProvider.notifier,
                                      )
                                      .createTopic(
                                        name: name,
                                        description: description,
                                        audiences: PeerTopicAudienceSelection(
                                          caderIds: selectedCadreIds.toList(),
                                          departmentIds: selectedDepartmentIds
                                              .toList(),
                                          locationIds: selectedLocationIds
                                              .toList(),
                                        ),
                                      );
                                  if (created == null || !mounted) return;
                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                  _showMessage('Topic created successfully.');
                                },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<PeerTopicAudienceOptions?> _loadTopicAudienceOptions() async {
    final navigator = Navigator.of(context, rootNavigator: true);

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Material(
            type: MaterialType.transparency,
            child: Center(
              child: CircularProgressIndicator(color: _peerPrimary),
            ),
          );
        },
      ),
    );

    try {
      return await ref
          .read(peerExchangeRepositoryProvider)
          .fetchTopicAudienceOptions();
    } catch (error) {
      if (mounted) {
        _showMessage(friendlyErrorMessage(error), error: true);
      }
      return null;
    } finally {
      if (mounted && navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  List<String> _selectedAudienceLabels(
    Set<int> selectedIds,
    List<PeerAudienceOption> options,
  ) {
    if (selectedIds.isEmpty) return const [];

    final labels = options
        .where((option) => selectedIds.contains(option.id))
        .map((option) => option.label)
        .toList();
    labels.sort();
    return labels;
  }

  Future<Set<int>?> _pickTopicAudienceIds({
    required String title,
    required List<PeerAudienceOption> options,
    required Set<int> initialSelectedIds,
  }) async {
    final selectedIds = {...initialSelectedIds};

    return showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _BottomSheetCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BottomSheetTitle(
                    title: title,
                    subtitle:
                        'Choose one or more options, or leave empty for everyone.',
                  ),
                  if (options.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 18),
                      child: Text('No options are available right now.'),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.46,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: _peerBorder, height: 1),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final selected = selectedIds.contains(option.id);

                          return CheckboxListTile(
                            value: selected,
                            contentPadding: EdgeInsets.zero,
                            activeColor: _peerPrimary,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              option.label,
                              style: _textStyle(fontSize: 13),
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  selectedIds.add(option.id);
                                } else {
                                  selectedIds.remove(option.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setModalState(selectedIds.clear),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _peerMuted,
                            side: const BorderSide(color: _peerBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PrimaryButton(
                          label: 'Apply',
                          onTap: () => Navigator.pop(sheetContext, selectedIds),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateGroupSheet() async {
    // final access = _currentAccess();
    // final requestAccess = ref.read(staffPortalAccessProvider);
    // if (!_canCreateGroups(access)) {
    //   _showMessage(
    //     'You do not have permission to create groups.',
    //     error: true,
    //   );
    //   return;
    // }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final selectedMembers = <PeerDirectoryPerson>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, _) {
                final isSubmitting = ref.watch(
                  peerExchangeViewModelProvider.select(
                    (state) => state.isSubmitting,
                  ),
                );

                return _BottomSheetCard(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BottomSheetTitle(
                          title: 'Create a group',
                          subtitle:
                              'Name it, add a short note, then pick people.',
                        ),
                        _FormField(
                          controller: titleController,
                          label: 'Group name',
                          hintText: 'Example: Infection prevention team',
                        ),
                        const SizedBox(height: 14),
                        _FormField(
                          controller: descriptionController,
                          label: 'Description',
                          hintText: 'What is this group for?',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedMembers.isEmpty
                                    ? 'No members yet'
                                    : '${selectedMembers.length} people selected',
                                style: _textStyle(
                                  fontSize: 13,
                                  color: _peerMuted,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final picked = await _showMultiStaffPicker(
                                  title: 'Add members',
                                  initialSelection: selectedMembers,
                                );
                                if (picked == null || !sheetContext.mounted) {
                                  return;
                                }
                                setModalState(() {
                                  selectedMembers
                                    ..clear()
                                    ..addAll(picked);
                                });
                              },
                              child: Text(
                                selectedMembers.isEmpty ? 'Choose' : 'Edit',
                                style: _textStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _peerPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (selectedMembers.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedMembers
                                .map(
                                  (person) => _SelectionChip(
                                    label: person.fullName,
                                    onRemove: () {
                                      setModalState(() {
                                        selectedMembers.removeWhere(
                                          (item) => item.id == person.id,
                                        );
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _PrimaryButton(
                          label: isSubmitting ? 'Creating...' : 'Create group',
                          isBusy: isSubmitting,
                          onTap: isSubmitting
                              ? null
                              : () async {
                                  final name = titleController.text.trim();
                                  if (name.isEmpty) {
                                    _showMessage(
                                      'Enter a group name.',
                                      error: true,
                                    );
                                    return;
                                  }

                                  final created = await ref
                                      .read(
                                        peerExchangeViewModelProvider.notifier,
                                      )
                                      .createGroup(
                                        name: name,
                                        description: descriptionController.text
                                            .trim(),
                                        memberIds: selectedMembers
                                            .map((person) => person.id)
                                            .toList(),
                                      );

                                  if (created == null || !mounted) return;
                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                  _showMessage('Group created.');
                                },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showEditGroupSheet(PeerConversation group) async {
    final access = _currentAccess();
    if (!_canEditGroup(access, group)) {
      _showMessage(
        'You do not have permission to update this group.',
        error: true,
      );
      return;
    }

    final nameController = TextEditingController(text: group.title);
    final descriptionController = TextEditingController(
      text: group.description,
    );
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _BottomSheetCard(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BottomSheetTitle(
                      title: 'Edit group',
                      subtitle:
                          'Update the name or description of this closed group.',
                    ),
                    _FormField(
                      controller: nameController,
                      label: 'Group name',
                      hintText: 'Group name',
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: descriptionController,
                      label: 'Description',
                      hintText: 'Describe the group purpose',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isSaving ? 'Saving...' : 'Save changes',
                      isBusy: isSaving,
                      onTap: isSaving
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                _showMessage(
                                  'Enter a group name.',
                                  error: true,
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                await ref
                                    .read(peerExchangeRepositoryProvider)
                                    .updateGroup(
                                      groupUuid: group.uuid,
                                      name: name,
                                      description: descriptionController.text
                                          .trim(),
                                    );
                                if (!mounted || !sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                await ref
                                    .read(
                                      peerExchangeViewModelProvider.notifier,
                                    )
                                    .loadAll();
                                _showMessage('Group updated successfully.');
                              } catch (error) {
                                if (!mounted) return;
                                _showMessage(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                  error: true,
                                );
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditQuestionSheet(PeerQuestion question) async {
    final access = _currentAccess();
    if (!_canEditQuestion(access, question)) {
      _showMessage(
        'You do not have permission to update this question.',
        error: true,
      );
      return;
    }

    final currentState = ref.read(peerExchangeViewModelProvider);
    if (currentState.categories.isEmpty) {
      _showMessage(
        'No categories are available for updating this question.',
        error: true,
      );
      return;
    }

    final contentController = TextEditingController(text: question.content);
    String selectedCategoryUuid = question.categoryUuid;
    List<PlatformFile> selectedFiles = const [];
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _BottomSheetCard(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BottomSheetTitle(
                      title: 'Edit question',
                      subtitle:
                          'Refine the category or wording for this Q&A entry.',
                    ),
                    _DropdownField<String>(
                      label: 'Category',
                      value: selectedCategoryUuid,
                      items: currentState.categories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category.uuid,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedCategoryUuid = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: contentController,
                      label: 'Question',
                      hintText: 'What do you need help with?',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picked = await _pickPeerFiles(
                                    context,
                                    existing: selectedFiles,
                                  );
                                  if (!sheetContext.mounted) return;
                                  setModalState(() => selectedFiles = picked);
                                },
                          icon: const Icon(Icons.attach_file_rounded),
                          label: Text(
                            selectedFiles.isEmpty
                                ? 'Add attachments'
                                : 'Add more files',
                          ),
                        ),
                        ...selectedFiles.map(
                          (file) => _AttachmentChip(
                            fileName: file.name,
                            fileSize: file.size,
                            onRemove: isSaving
                                ? null
                                : () => setModalState(() {
                                    selectedFiles = selectedFiles
                                        .where(
                                          (item) =>
                                              !(item.path == file.path &&
                                                  item.name == file.name),
                                        )
                                        .toList();
                                  }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isSaving ? 'Saving...' : 'Save changes',
                      isBusy: isSaving,
                      onTap: isSaving
                          ? null
                          : () async {
                              final content = contentController.text.trim();
                              if (content.isEmpty) {
                                _showMessage(
                                  'Enter your question first.',
                                  error: true,
                                );
                                return;
                              }

                              final attachments =
                                  await _platformFilesToMultipart(
                                    selectedFiles,
                                  );
                              setModalState(() => isSaving = true);
                              try {
                                await ref
                                    .read(peerExchangeRepositoryProvider)
                                    .updateQuestion(
                                      questionUuid: question.uuid,
                                      categoryUuid: selectedCategoryUuid,
                                      content: content,
                                      attachments: attachments,
                                    );
                                if (!mounted || !sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                await ref
                                    .read(
                                      peerExchangeViewModelProvider.notifier,
                                    )
                                    .loadAll();
                                _showMessage('Question updated successfully.');
                              } catch (error) {
                                if (!mounted) return;
                                _showMessage(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                  error: true,
                                );
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGroup(PeerConversation group) async {
    final access = _currentAccess();
    if (!_canDeleteGroup(access, group)) {
      _showMessage(
        'You do not have permission to delete this group.',
        error: true,
      );
      return;
    }

    final shouldDelete = await _confirmDestructiveAction(
      title: 'Delete group?',
      body:
          'This will remove "${group.title}" and its group metadata from peer exchange.',
    );
    if (!shouldDelete) return;

    try {
      await ref.read(peerExchangeRepositoryProvider).deleteGroup(group.uuid);
      await ref.read(peerExchangeViewModelProvider.notifier).loadAll();
      _showMessage('Group deleted successfully.');
    } catch (error) {
      _showMessage(friendlyErrorMessage(error), error: true);
    }
  }

  Future<void> _deleteQuestion(PeerQuestion question) async {
    final access = _currentAccess();
    if (!_canEditQuestion(access, question)) {
      _showMessage(
        'You do not have permission to delete this question.',
        error: true,
      );
      return;
    }

    final shouldDelete = await _confirmDestructiveAction(
      title: 'Delete question?',
      body: 'This will permanently remove this Q&A post.',
    );
    if (!shouldDelete) return;

    try {
      await ref
          .read(peerExchangeRepositoryProvider)
          .deleteQuestion(question.uuid);
      await ref.read(peerExchangeViewModelProvider.notifier).loadAll();
      _showMessage('Question deleted successfully.');
    } catch (error) {
      _showMessage(friendlyErrorMessage(error), error: true);
    }
  }

  Future<void> _deleteQuestionCategory(PeerQuestionCategory category) async {
    final access = _currentAccess();
    if (!access.canManageQuestionCategories) {
      _showMessage(
        'You do not have permission to delete this category.',
        error: true,
      );
      return;
    }

    final shouldDelete = await _confirmDestructiveAction(
      title: 'Delete category?',
      body:
          'This will remove the "${category.name}" category. Use with care if questions already reference it.',
    );
    if (!shouldDelete) return;

    try {
      await ref
          .read(peerExchangeRepositoryProvider)
          .deleteQuestionCategory(category.uuid);
      await ref.read(peerExchangeViewModelProvider.notifier).loadAll();
      _showMessage('Question category deleted successfully.');
    } catch (error) {
      _showMessage(friendlyErrorMessage(error), error: true);
    }
  }

  Future<bool> _confirmDestructiveAction({
    required String title,
    required String body,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: _textStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          content: Text(
            body,
            style: _textStyle(fontSize: 14, color: _peerMuted, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: _textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _peerMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Delete',
                style: _textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFD92D20),
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _showCreateConversationSheet() async {
    final access = _currentAccess();
    if (!access.canStartDirectChats) {
      _showMessage(
        'Direct messaging is not available for your role.',
        error: true,
      );
      return;
    }

    final selectedPerson = await _showSingleStaffPicker(title: 'New message');
    if (selectedPerson == null || !mounted) {
      return;
    }

    final messageController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final isSubmitting = ref.watch(
              peerExchangeViewModelProvider.select(
                (state) => state.isSubmitting,
              ),
            );

            return _BottomSheetCard(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BottomSheetTitle(
                      title: 'Message ${selectedPerson.fullName}',
                      subtitle: selectedPerson.subtitle,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _peerSoftBlue,
                            child: Text(
                              _initials(selectedPerson.fullName),
                              style: _textStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _peerPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedPerson.fullName,
                                  style: _textStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedPerson.subtitle,
                                  style: _textStyle(
                                    fontSize: 12,
                                    color: _peerMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: messageController,
                      label: 'Message',
                      hintText: 'Write a message',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isSubmitting ? 'Sending...' : 'Send',
                      isBusy: isSubmitting,
                      onTap: isSubmitting
                          ? null
                          : () async {
                              final message = messageController.text.trim();
                              if (message.isEmpty) {
                                _showMessage(
                                  'Write a message first.',
                                  error: true,
                                );
                                return;
                              }

                              final result = await ref
                                  .read(peerExchangeViewModelProvider.notifier)
                                  .startConversation(
                                    receiverId: selectedPerson.id,
                                    message: message,
                                  );
                              if (result == null || !mounted) return;
                              if (!sheetContext.mounted) return;
                              Navigator.pop(sheetContext);
                              setState(
                                () => _section = _CommunitySection.inbox,
                              );
                              _showMessage('Conversation started.');
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFD92D20) : _peerPrimary,
        ),
      );
  }
}

class QuestionDetailScreen extends ConsumerStatefulWidget {
  const QuestionDetailScreen({super.key, required this.question});

  final PeerQuestion question;

  @override
  ConsumerState<QuestionDetailScreen> createState() =>
      _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<PlatformFile> _selectedFiles = const [];
  List<PeerComment> _comments = const [];
  bool _isLoading = true;
  bool _isPosting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comments = await ref
          .read(peerExchangeRepositoryProvider)
          .fetchQuestionComments(widget.question.uuid);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = listLoadErrorMessage(error);
      });
    }
  }

  Future<void> _postComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty && _selectedFiles.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final attachments = await _platformFilesToMultipart(_selectedFiles);
      await ref
          .read(peerExchangeRepositoryProvider)
          .createQuestionComment(
            questionUuid: widget.question.uuid,
            message: message,
            attachments: attachments,
          );
      _commentController.clear();
      setState(() {
        _selectedFiles = const [];
      });
      await _loadComments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(error)),
            backgroundColor: const Color(0xFFD92D20),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  Future<void> _pickAttachments() async {
    final picked = await _pickPeerFiles(context, existing: _selectedFiles);
    if (!mounted) return;
    setState(() {
      _selectedFiles = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _peerBackground,
      appBar: _buildDetailAppBar('Question'),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: _peerPrimary,
              onRefresh: _loadComments,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _peerCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _peerBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetaChip(
                              label:
                                  widget.question.category?.name ??
                                  'Uncategorized',
                              color: _peerSoftBlue,
                              textColor: _peerPrimary,
                            ),
                            _MetaChip(
                              label: '${widget.question.commentsCount} replies',
                              color: _peerSoftOrange,
                              textColor: const Color(0xFFB95817),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.question.content,
                          style: _textStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Asked ${_formatDate(widget.question.createdAt)}',
                          style: _textStyle(fontSize: 13, color: _peerMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Replies',
                    style: _textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: _peerPrimary),
                      ),
                    )
                  else if (_error != null)
                    _EmptyStateCard(
                      title: 'Replies could not load',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onTap: _loadComments,
                    )
                  else if (_comments.isEmpty)
                    const _EmptyStateCard(
                      title: 'Be the first to reply',
                      subtitle: 'Your answer will appear here.',
                    )
                  else
                    ..._comments.map(_CommentCard.new),
                ],
              ),
            ),
          ),
          _ComposerBar(
            controller: _commentController,
            hintText: 'Write a reply',
            isPosting: _isPosting,
            onSend: _postComment,
            onPickAttachments: _pickAttachments,
            attachments: _selectedFiles,
            onRemoveAttachment: (file) {
              setState(() {
                _selectedFiles = _selectedFiles
                    .where(
                      (item) =>
                          !(item.path == file.path && item.name == file.name),
                    )
                    .toList();
              });
            },
          ),
        ],
      ),
    );
  }
}

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topic});

  final PeerTopic topic;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<PlatformFile> _selectedFiles = const [];
  List<PeerComment> _comments = const [];
  bool _isLoading = true;
  bool _isPosting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comments = await ref
          .read(peerExchangeRepositoryProvider)
          .fetchTopicComments(widget.topic.uuid);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = listLoadErrorMessage(error);
      });
    }
  }

  Future<void> _postComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty && _selectedFiles.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final attachments = await _platformFilesToMultipart(_selectedFiles);
      await ref
          .read(peerExchangeRepositoryProvider)
          .createTopicComment(
            topicUuid: widget.topic.uuid,
            message: message,
            attachments: attachments,
          );
      _commentController.clear();
      setState(() {
        _selectedFiles = const [];
      });
      await _loadComments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(error)),
            backgroundColor: const Color(0xFFD92D20),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  Future<void> _pickAttachments() async {
    final picked = await _pickPeerFiles(context, existing: _selectedFiles);
    if (!mounted) return;
    setState(() {
      _selectedFiles = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _peerBackground,
      appBar: _buildDetailAppBar('Topic'),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: _peerPrimary,
              onRefresh: _loadComments,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _peerCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _peerBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.topic.name,
                                style: _textStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _MetaChip(
                              label: '${widget.topic.commentsCount} comments',
                              color: _peerSoftGreen,
                              textColor: const Color(0xFF0B8F55),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.topic.description.isNotEmpty
                              ? widget.topic.description
                              : 'No description provided for this topic.',
                          style: _textStyle(
                            fontSize: 14,
                            color: _peerText.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Created ${_formatDate(widget.topic.createdAt)}',
                          style: _textStyle(fontSize: 13, color: _peerMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Comments',
                    style: _textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: _peerPrimary),
                      ),
                    )
                  else if (_error != null)
                    _EmptyStateCard(
                      title: 'Comments could not load',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onTap: _loadComments,
                    )
                  else if (_comments.isEmpty)
                    const _EmptyStateCard(
                      title: 'Start the conversation',
                      subtitle: 'Comments will appear here.',
                    )
                  else
                    ..._comments.map(_CommentCard.new),
                ],
              ),
            ),
          ),
          _ComposerBar(
            controller: _commentController,
            hintText: 'Write a comment',
            isPosting: _isPosting,
            onSend: _postComment,
            onPickAttachments: _pickAttachments,
            attachments: _selectedFiles,
            onRemoveAttachment: (file) {
              setState(() {
                _selectedFiles = _selectedFiles
                    .where(
                      (item) =>
                          !(item.path == file.path && item.name == file.name),
                    )
                    .toList();
              });
            },
          ),
        ],
      ),
    );
  }
}

class ConversationDetailScreen extends ConsumerStatefulWidget {
  const ConversationDetailScreen({
    super.key,
    required this.conversationUuid,
    required this.title,
    required this.isGroup,
  });

  final String conversationUuid;
  final String title;
  final bool isGroup;

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<PlatformFile> _selectedFiles = const [];

  PeerConversation? _conversation;
  List<PeerMember> _members = const [];
  List<PeerMessage> _messages = const [];
  bool _isLoading = true;
  bool _isPosting = false;
  String? _error;
  StreamSubscription<RealtimeEnvelope>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_bindRealtime());
    _loadConversation();
  }

  @override
  void dispose() {
    unawaited(
      RealtimeService.instance.unsubscribeConversation(widget.conversationUuid),
    );
    _realtimeSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  PeerExchangeAccess _currentAccess() {
    final user = ref.read(authViewModelProvider).user;
    final portalAccess = ref.read(staffPortalAccessProvider);
    return PeerExchangeAccess.fromUser(
      user,
      isApproverOverride: portalAccess.hasRequestApproverAccess,
    );
  }

  String? _senderNameFor(PeerMessage message) {
    final directSenderName = message.sender?.fullName.trim() ?? '';
    if (directSenderName.isNotEmpty) {
      return directSenderName;
    }

    for (final member in _members) {
      if (member.numericId == message.senderId) {
        final memberName = member.fullName.trim();
        if (memberName.isNotEmpty) {
          return memberName;
        }
      }
    }

    return null;
  }

  bool _canManageGroupMembers(PeerExchangeAccess access, int? createdBy) {
    return access.isPrivileged && access.canManageGroupMembers(createdBy);
  }

  Future<void> _loadConversation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(peerExchangeRepositoryProvider);
      final baseConversation = await repository.fetchConversationDetail(
        widget.conversationUuid,
      );
      final shouldLoadGroupMembers = widget.isGroup || baseConversation.isGroup;
      final conversation = shouldLoadGroupMembers
          ? await repository.fetchGroupDetail(widget.conversationUuid)
          : baseConversation;
      final members = shouldLoadGroupMembers
          ? await repository.fetchGroupMembers(widget.conversationUuid)
          : conversation.users;
      final messages = [...conversation.recentMessages];
      if (messages.isEmpty && conversation.lastMessage != null) {
        messages.add(conversation.lastMessage!);
      }
      messages.sort((left, right) {
        final leftDate = left.sentAt ?? left.createdAt ?? DateTime(1970);
        final rightDate = right.sentAt ?? right.createdAt ?? DateTime(1970);
        return leftDate.compareTo(rightDate);
      });

      if (!mounted) return;
      setState(() {
        _conversation = conversation;
        _members = members;
        _messages = messages;
        _isLoading = false;
      });

      await _markConversationRead();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = listLoadErrorMessage(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedFiles.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final attachments = await _platformFilesToMultipart(_selectedFiles);
      final sent = await ref
          .read(peerExchangeRepositoryProvider)
          .sendConversationMessage(
            conversationUuid: widget.conversationUuid,
            message: message,
            attachments: attachments,
          );
      _messageController.clear();
      setState(() {
        _selectedFiles = const [];
      });
      _upsertMessage(sent);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(error)),
            backgroundColor: const Color(0xFFD92D20),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  Future<void> _pickAttachments() async {
    final picked = await _pickPeerFiles(context, existing: _selectedFiles);
    if (!mounted) return;
    setState(() {
      _selectedFiles = picked;
    });
  }

  Future<void> _bindRealtime() async {
    try {
      await RealtimeService.instance.subscribeConversation(
        widget.conversationUuid,
      );
      _realtimeSubscription = RealtimeService.instance.events
          .where(
            (event) =>
                event.channelName ==
                'private-conversations.${widget.conversationUuid}',
          )
          .listen(_handleRealtimeEvent);
    } catch (error) {
      log(
        'Conversation realtime subscription failed: $error',
        name: 'REALTIME',
      );
    }
  }

  Future<void> _markConversationRead() async {
    final currentUserId = ref.read(authViewModelProvider).user?.userId ?? '';
    final hasIncomingUnread = _messages.any(
      (message) =>
          message.senderId.toString() != currentUserId &&
          message.readAt == null,
    );
    if (!hasIncomingUnread) return;

    try {
      await ref
          .read(peerExchangeRepositoryProvider)
          .markConversationAsRead(widget.conversationUuid);
      if (!mounted) return;
      final now = DateTime.now().toUtc();
      setState(() {
        _messages = _messages.map((message) {
          if (message.senderId.toString() == currentUserId ||
              message.readAt != null) {
            return message;
          }
          return message.copyWith(
            deliveredAt: message.deliveredAt ?? now,
            readAt: now,
            status: 'read',
          );
        }).toList();
      });
    } catch (_) {}
  }

  void _handleRealtimeEvent(RealtimeEnvelope event) {
    switch (event.eventName) {
      case 'conversation.message.sent':
        final conversation = event.payload['conversation'];
        final message = event.payload['conversation_message'];
        if (conversation is Map) {
          _conversation = PeerConversation.fromJson(
            conversation.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
        if (message is Map) {
          final normalized = message.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final peerMessage = PeerMessage.fromJson(normalized);
          _upsertMessage(peerMessage);
          final currentUserId =
              ref.read(authViewModelProvider).user?.userId ?? '';
          if (peerMessage.senderId.toString() != currentUserId) {
            unawaited(_markConversationRead());
          }
        }
        break;
      case 'conversation.message.read':
        final uuids = event.payload['message_uuids'];
        final readAt = DateTime.tryParse(
          event.payload['read_at']?.toString() ?? '',
        );
        if (uuids is List && readAt != null && mounted) {
          final uuidSet = uuids.map((item) => item.toString()).toSet();
          setState(() {
            _messages = _messages.map((message) {
              if (!uuidSet.contains(message.uuid)) return message;
              return message.copyWith(
                deliveredAt: message.deliveredAt ?? readAt,
                readAt: readAt,
                status: 'read',
              );
            }).toList();
          });
        }
        break;
      case 'conversation.group.member_added':
      case 'conversation.group.member_removed':
      case 'conversation.group.created':
        unawaited(_loadConversation());
        break;
    }
  }

  void _upsertMessage(PeerMessage message) {
    if (!mounted) return;

    setState(() {
      final index = _messages.indexWhere((item) => item.uuid == message.uuid);
      if (index >= 0) {
        _messages[index] = message;
      } else {
        _messages = [..._messages, message];
      }
      _messages.sort((left, right) {
        final leftDate = left.sentAt ?? left.createdAt ?? DateTime(1970);
        final rightDate = right.sentAt ?? right.createdAt ?? DateTime(1970);
        return leftDate.compareTo(rightDate);
      });
    });
  }

  Future<List<PeerDirectoryPerson>?> _pickMembersForGroup() async {
    final queryController = TextEditingController();
    final directoryFuture = ref
        .read(peerExchangeRepositoryProvider)
        .fetchStaffDirectory();
    final selected = <int, PeerDirectoryPerson>{};

    return showModalBottomSheet<List<PeerDirectoryPerson>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _BottomSheetCard(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BottomSheetTitle(
                      title: 'Add members',
                      subtitle: 'Choose people for this group.',
                    ),
                    _FormField(
                      controller: queryController,
                      label: 'Search staff',
                      hintText: 'Search by name',
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<PeerDirectoryPerson>>(
                      future: directoryFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: _peerPrimary,
                              ),
                            ),
                          );
                        }

                        final people =
                            snapshot.data ?? const <PeerDirectoryPerson>[];
                        final query = queryController.text.trim().toLowerCase();
                        final filtered = people.where((person) {
                          if (query.isEmpty) return true;
                          return '${person.fullName} ${person.subtitle}'
                              .toLowerCase()
                              .contains(query);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'No staff found.',
                              style: _textStyle(
                                fontSize: 13,
                                color: _peerMuted,
                              ),
                            ),
                          );
                        }

                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final person = filtered[index];
                              final isSelected = selected.containsKey(
                                person.id,
                              );

                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selected.remove(person.id);
                                    } else {
                                      selected[person.id] = person;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _peerSoftBlue
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? _peerPrimary
                                          : const Color(0xFFE4E7EC),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _peerSoftBlue,
                                        child: Text(
                                          _initials(person.fullName),
                                          style: _textStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: _peerPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              person.fullName,
                                              style: _textStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              person.subtitle,
                                              style: _textStyle(
                                                fontSize: 12,
                                                color: _peerMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? _peerPrimary
                                            : _peerMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      label: selected.isEmpty
                          ? 'Choose people'
                          : 'Add selected',
                      onTap: selected.isEmpty
                          ? null
                          : () => Navigator.pop(
                              sheetContext,
                              selected.values.toList(),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showMembersSheet() async {
    final access = _currentAccess();
    final canManageMembers = _canManageGroupMembers(
      access,
      _conversation?.createdBy,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetCard(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BottomSheetTitle(
                  title: canManageMembers ? 'Group members' : 'Group info',
                  subtitle: canManageMembers
                      ? 'Add or remove people in this group.'
                      : 'People in this group.',
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: _members.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text('No members loaded for this group.'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _members.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: _peerSoftBlue,
                                    child: Text(
                                      _initials(member.fullName),
                                      style: _textStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _peerPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.fullName,
                                          style: _textStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          member.role.isEmpty
                                              ? 'Member'
                                              : member.role,
                                          style: _textStyle(
                                            fontSize: 12,
                                            color: _peerMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (canManageMembers &&
                                      member.numericId != null)
                                    IconButton(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        Navigator.pop(sheetContext);
                                        await ref
                                            .read(
                                              peerExchangeRepositoryProvider,
                                            )
                                            .removeGroupMember(
                                              groupUuid:
                                                  widget.conversationUuid,
                                              userId: member.numericId!,
                                            );
                                        if (!mounted) return;
                                        await _loadConversation();
                                        messenger
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text('Member removed.'),
                                              backgroundColor: _peerPrimary,
                                            ),
                                          );
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                        color: Color(0xFFD92D20),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                if (canManageMembers) ...[
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: 'Add members',
                    onTap: () async {
                      final picked = await _pickMembersForGroup();
                      if (picked == null || picked.isEmpty || !mounted) {
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      await ref
                          .read(peerExchangeRepositoryProvider)
                          .addGroupMembers(
                            groupUuid: widget.conversationUuid,
                            userIds: picked.map((person) => person.id).toList(),
                          );
                      if (!mounted) return;
                      await _loadConversation();
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Members updated.'),
                            backgroundColor: _peerPrimary,
                          ),
                        );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(
      authViewModelProvider.select((state) => state.user?.userId ?? ''),
    );
    ref.watch(staffPortalAccessProvider);
    final access = _currentAccess();

    return Scaffold(
      backgroundColor: _peerBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const AppSvgIcon(
            assetName: 'assets/icons/back_arrow.svg',
            color: _peerText,
            size: 20,
          ),
        ),
        title: Text(
          widget.title,
          style: _textStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (widget.isGroup && access.canViewGroupMembers)
            TextButton(
              onPressed: _showMembersSheet,
              child: Text(
                _canManageGroupMembers(access, _conversation?.createdBy)
                    ? 'Members'
                    : 'Info',
                style: _textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _peerPrimary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: _peerPrimary,
              onRefresh: _loadConversation,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  if (_conversation != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _peerCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _peerBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MetaChip(
                                label: widget.isGroup
                                    ? '${_members.length} members'
                                    : 'Direct chat',
                                color: _peerSoftBlue,
                                textColor: _peerPrimary,
                              ),
                              _MetaChip(
                                label:
                                    '${_conversation?.messagesCount ?? _messages.length} messages',
                                color: _peerSoftOrange,
                                textColor: const Color(0xFFB95817),
                              ),
                            ],
                          ),
                          if ((_conversation?.description ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              _conversation!.description,
                              style: _textStyle(
                                fontSize: 13,
                                color: _peerMuted,
                                height: 1.45,
                              ),
                            ),
                          ],
                          if (_members.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _MemberPreviewRow(members: _members),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Messages',
                    style: _textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: _peerPrimary),
                      ),
                    )
                  else if (_error != null)
                    _EmptyStateCard(
                      title: 'Conversation could not load',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onTap: _loadConversation,
                    )
                  else if (_messages.isEmpty)
                    const _EmptyStateCard(
                      title: 'No messages yet',
                      subtitle:
                          'Send the first message to start this conversation.',
                    )
                  else
                    ..._messages.map(
                      (message) => _MessageBubble(
                        message: message,
                        isMine: message.senderId.toString() == currentUserId,
                        senderName: _senderNameFor(message),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _ComposerBar(
            controller: _messageController,
            hintText: 'Type a message',
            isPosting: _isPosting,
            onSend: _sendMessage,
            onPickAttachments: _pickAttachments,
            attachments: _selectedFiles,
            onRemoveAttachment: (file) {
              setState(() {
                _selectedFiles = _selectedFiles
                    .where(
                      (item) =>
                          !(item.path == file.path && item.name == file.name),
                    )
                    .toList();
              });
            },
          ),
        ],
      ),
    );
  }
}
