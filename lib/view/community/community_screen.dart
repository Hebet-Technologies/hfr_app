import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/peer_exchange_access.dart';
import '../../model/peer_exchange_models.dart';
import '../../view_model/peer_exchange_view_model.dart';
import '../../view_model/providers.dart';
import '../../widget/app_svg_icon.dart';

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

enum _ItemMenuAction { edit, delete }

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  _CommunitySection _section = _CommunitySection.overview;
  DateTime? _selectedQuestionDay;

  @override
  void initState() {
    super.initState();
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
        body: Center(
          child: CircularProgressIndicator(color: _peerPrimary, strokeWidth: 3),
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

  Widget _buildSearchRow(PeerExchangeState state) {
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

    if (isQuestionSection) {
      final hasCategoryFilter = state.selectedCategoryUuid != null;
      final hasDateFilter = _selectedQuestionDay != null;

      return Row(
        children: [
          searchField,
          const SizedBox(width: 8),
          _SquareIconButton(
            isActive: hasCategoryFilter,
            icon: Icon(
              Icons.tune_rounded,
              color: hasCategoryFilter ? _peerPrimary : _peerText,
              size: 18,
            ),
            onTap: () => _showQuestionFiltersSheet(state),
            size: _qaToolbarHeight,
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            isActive: hasDateFilter,
            icon: Icon(
              Icons.calendar_today_outlined,
              color: hasDateFilter ? _peerPrimary : _peerText,
              size: 18,
            ),
            onTap: _pickQuestionDate,
            size: _qaToolbarHeight,
          ),
        ],
      );
    }

    return Row(
      children: [
        searchField,
        const SizedBox(width: 12),
        _SquareIconButton(
          icon: const AppSvgIcon(
            assetName: 'assets/icons/filter.svg',
            color: _peerText,
            size: 18,
          ),
          onTap: _showOverviewActionsSheet,
        ),
        const SizedBox(width: 8),
        _SquareIconButton(
          icon: const Icon(Icons.refresh_rounded, color: _peerText, size: 18),
          onTap: () =>
              ref.read(peerExchangeViewModelProvider.notifier).loadAll(),
        ),
      ],
    );
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
                  if (_canEditTopic(access, topic))
                    _buildEntityMenu(
                      onSelected: (action) async {
                        switch (action) {
                          case _ItemMenuAction.edit:
                            await _showEditTopicSheet(topic);
                            return;
                          case _ItemMenuAction.delete:
                            await _deleteTopic(topic);
                            return;
                        }
                      },
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

  bool _canEditTopic(PeerExchangeAccess access, PeerTopic topic) {
    return access.canEditTopic(topic.createdBy);
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

  Future<void> _pickQuestionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedQuestionDay ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _peerPrimary),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() => _selectedQuestionDay = picked);
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

  Future<void> _showQuestionFiltersSheet(PeerExchangeState state) async {
    final access = _currentAccess();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BottomSheetTitle(
                title: 'Filter questions',
                subtitle: 'Choose a category to narrow the Q&A list.',
              ),
              _ActionTile(
                title: 'All categories',
                subtitle: state.selectedCategoryUuid == null
                    ? 'Currently showing every question.'
                    : 'Clear the category filter.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref
                      .read(peerExchangeViewModelProvider.notifier)
                      .selectCategory(null);
                },
              ),
              if (state.categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 16),
                  child: Text('No categories available yet.'),
                )
              else
                ...state.categories.map(
                  (category) => _ActionTile(
                    title: category.name,
                    subtitle: state.selectedCategoryUuid == category.uuid
                        ? 'Currently selected.'
                        : 'Show questions in this category.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      ref
                          .read(peerExchangeViewModelProvider.notifier)
                          .selectCategory(category.uuid);
                    },
                  ),
                ),
              if (access.canManageQuestionCategories) ...[
                const SizedBox(height: 8),
                _PrimaryButton(
                  label: 'Manage categories',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showManageCategoriesSheet(state);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

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

                                  final created = await ref
                                      .read(
                                        peerExchangeViewModelProvider.notifier,
                                      )
                                      .createQuestion(
                                        categoryUuid: selectedCategoryUuid,
                                        content: content,
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
        _showMessage(
          error.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
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

                              setModalState(() => isSaving = true);
                              try {
                                await ref
                                    .read(peerExchangeRepositoryProvider)
                                    .updateQuestion(
                                      questionUuid: question.uuid,
                                      categoryUuid: selectedCategoryUuid,
                                      content: content,
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

  Future<void> _showEditTopicSheet(PeerTopic topic) async {
    final access = _currentAccess();
    if (!_canEditTopic(access, topic)) {
      _showMessage(
        'You do not have permission to update this topic.',
        error: true,
      );
      return;
    }

    final titleController = TextEditingController(text: topic.name);
    final descriptionController = TextEditingController(
      text: topic.description,
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
                      title: 'Edit topic',
                      subtitle:
                          'Update this moderated discussion topic and its description.',
                    ),
                    _FormField(
                      controller: titleController,
                      label: 'Topic name',
                      hintText: 'Topic name',
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: descriptionController,
                      label: 'Description',
                      hintText: 'Topic description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isSaving ? 'Saving...' : 'Save changes',
                      isBusy: isSaving,
                      onTap: isSaving
                          ? null
                          : () async {
                              final name = titleController.text.trim();
                              if (name.isEmpty) {
                                _showMessage(
                                  'Enter a topic name.',
                                  error: true,
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                await ref
                                    .read(peerExchangeRepositoryProvider)
                                    .updateTopic(
                                      topicUuid: topic.uuid,
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
                                _showMessage('Topic updated successfully.');
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
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
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
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _deleteTopic(PeerTopic topic) async {
    final access = _currentAccess();
    if (!_canEditTopic(access, topic)) {
      _showMessage(
        'You do not have permission to delete this topic.',
        error: true,
      );
      return;
    }

    final shouldDelete = await _confirmDestructiveAction(
      title: 'Delete topic?',
      body: 'This will remove the moderated topic and its discussion thread.',
    );
    if (!shouldDelete) return;

    try {
      await ref.read(peerExchangeRepositoryProvider).deleteTopic(topic.uuid);
      await ref.read(peerExchangeViewModelProvider.notifier).loadAll();
      _showMessage('Topic deleted successfully.');
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
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
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
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
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _postComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      await ref
          .read(peerExchangeRepositoryProvider)
          .createQuestionComment(
            questionUuid: widget.question.uuid,
            message: message,
          );
      _commentController.clear();
      await _loadComments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
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
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _postComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      await ref
          .read(peerExchangeRepositoryProvider)
          .createTopicComment(topicUuid: widget.topic.uuid, message: message);
      _commentController.clear();
      await _loadComments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
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

  PeerConversation? _conversation;
  List<PeerMember> _members = const [];
  List<PeerMessage> _messages = const [];
  bool _isLoading = true;
  bool _isPosting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
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
      final conversation = widget.isGroup
          ? await repository.fetchGroupDetail(widget.conversationUuid)
          : await repository.fetchConversationDetail(widget.conversationUuid);
      final members = widget.isGroup
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      await ref
          .read(peerExchangeRepositoryProvider)
          .sendConversationMessage(
            conversationUuid: widget.conversationUuid,
            message: message,
          );
      _messageController.clear();
      await _loadConversation();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
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
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.size = 46,
  });

  final Widget icon;
  final VoidCallback onTap;
  final bool isActive;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: isActive ? _peerPrimary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? _peerPrimary.withValues(alpha: 0.24)
                : _peerBorder,
          ),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}

class _QuestionHeaderIconButton extends StatelessWidget {
  const _QuestionHeaderIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: const SizedBox(
        width: 38,
        height: 38,
        child: Icon(Icons.chevron_left_rounded, color: _peerText, size: 28),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _peerPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          minimumSize: const Size(88, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: _textStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _QuestionSearchSuffix extends StatelessWidget {
  const _QuestionSearchSuffix({required this.showClear, required this.onClear});

  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showClear) ...[
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: _peerMuted,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.keyboard_command_key_rounded,
                  size: 12,
                  color: _peerMuted,
                ),
                const SizedBox(width: 2),
                Text(
                  '1',
                  style: _textStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _peerMuted,
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

class _OverviewShortcutCard extends StatelessWidget {
  const _OverviewShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _peerBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: _textStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: _textStyle(fontSize: 12, color: _peerMuted)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: _textStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: _textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _peerPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: _textStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _textStyle(fontSize: 12, color: _peerMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _textStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _QuestionInfoColumn extends StatelessWidget {
  const _QuestionInfoColumn({
    required this.label,
    required this.child,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: _textStyle(fontSize: 12, color: _peerMuted)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: _peerSoftBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: _textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _peerPrimary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: _peerPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberPreviewRow extends StatelessWidget {
  const _MemberPreviewRow({required this.members});

  final List<PeerMember> members;

  @override
  Widget build(BuildContext context) {
    final preview = members.take(4).toList();
    return Row(
      children: [
        SizedBox(
          width: preview.length * 22 + 24,
          height: 28,
          child: Stack(
            children: [
              for (var index = 0; index < preview.length; index++)
                Positioned(
                  left: index * 22,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: _peerSoftBlue,
                      child: Text(
                        _initials(preview[index].fullName),
                        style: _textStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _peerPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            members.length > 4
                ? '${members.length} people in this group'
                : preview.map((member) => member.fullName).join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(fontSize: 12, color: _peerMuted),
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _peerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _textStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: _textStyle(fontSize: 13, color: _peerMuted, height: 1.5),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: _peerPrimary,
                side: const BorderSide(color: _peerPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              child: Text(
                actionLabel!,
                style: _textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _peerPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomSheetCard extends StatelessWidget {
  const _BottomSheetCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: child,
        ),
      ),
    );
  }
}

class _BottomSheetTitle extends StatelessWidget {
  const _BottomSheetTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _textStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: _textStyle(fontSize: 13, color: _peerMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: _textStyle(
                      fontSize: 13,
                      color: _peerMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _peerMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _textStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: _textStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: _textStyle(fontSize: 13, color: const Color(0xFF98A2B3)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _AudiencePickerField extends StatelessWidget {
  const _AudiencePickerField({
    required this.label,
    required this.selectedLabels,
    required this.onTap,
  });

  final String label;
  final List<String> selectedLabels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewLabels = selectedLabels.take(3).toList();
    final extraCount = selectedLabels.length - previewLabels.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _textStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _peerBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabels.isEmpty
                        ? 'All staff'
                        : '${selectedLabels.length} selected',
                    style: _textStyle(
                      fontSize: 13,
                      color: selectedLabels.isEmpty ? _peerMuted : _peerText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _peerMuted,
                ),
              ],
            ),
          ),
        ),
        if (previewLabels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...previewLabels.map(
                (label) => _MetaChip(
                  label: label,
                  color: _peerSoftBlue,
                  textColor: _peerPrimary,
                ),
              ),
              if (extraCount > 0)
                _MetaChip(
                  label: '+$extraCount more',
                  color: const Color(0xFFF3F4F6),
                  textColor: _peerMuted,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _textStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          key: ValueKey('$label::$value'),
          initialValue: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap, this.isBusy = false});

  final String label;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _peerPrimary,
          disabledBackgroundColor: const Color(0xFF9EC0FF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: _textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard(this.comment);

  final PeerComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _peerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _peerSoftBlue,
            child: Text(
              _initials(comment.author?.fullName ?? 'U'),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.author?.fullName ?? 'Community member',
                        style: _textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      _formatRelative(comment.createdAt),
                      style: _textStyle(fontSize: 12, color: _peerMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment.comment,
                  style: _textStyle(
                    fontSize: 13,
                    color: _peerText.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                if (comment.attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _MetaChip(
                    label: '${comment.attachments.length} attachment(s)',
                    color: _peerSoftOrange,
                    textColor: const Color(0xFFB95817),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final PeerMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final background = isMine ? _peerPrimary : Colors.white;
    final textColor = isMine ? Colors.white : _peerText;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isMine ? _peerPrimary : _peerBorder),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine && (message.sender?.fullName ?? '').isNotEmpty) ...[
              Text(
                message.sender!.fullName,
                style: _textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isMine ? Colors.white : _peerPrimary,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message.preview,
              style: _textStyle(fontSize: 13, color: textColor, height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(message.sentAt ?? message.createdAt),
              style: _textStyle(
                fontSize: 11,
                color: isMine
                    ? Colors.white.withValues(alpha: 0.82)
                    : _peerMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.hintText,
    required this.isPosting,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isPosting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _peerBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: _textStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: _textStyle(
                  fontSize: 13,
                  color: const Color(0xFF98A2B3),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _peerBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _peerBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _peerPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isPosting ? null : onSend,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isPosting ? const Color(0xFF9EC0FF) : _peerPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

AppBar _buildDetailAppBar(String title) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleSpacing: 0,
    leadingWidth: 44,
    leading: Builder(
      builder: (context) {
        return IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const AppSvgIcon(
            assetName: 'assets/icons/back_arrow.svg',
            color: _peerText,
            size: 20,
          ),
        );
      },
    ),
    title: Text(
      title,
      style: _textStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );
}

TextStyle _textStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = _peerText,
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
  if (parts.isEmpty) return 'PE';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _formatRelative(DateTime? dateTime) {
  if (dateTime == null) return 'No update';

  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';

  return _formatDate(dateTime);
}

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) return 'Unknown date';

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

  return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]} ${dateTime.year}';
}

String _formatDateChip(DateTime dateTime) {
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

  return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
}

String _formatTime(DateTime? dateTime) {
  if (dateTime == null) return 'Now';
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
