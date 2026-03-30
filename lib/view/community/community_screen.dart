import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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

enum _CommunitySection {
  inbox('Inbox'),
  groups('Groups'),
  questions('Q&A'),
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
  _CommunitySection _section = _CommunitySection.inbox;

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
    final directConversations = state.conversations
        .where((conversation) => !conversation.isGroup)
        .toList();

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
      backgroundColor: _peerBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handlePrimaryAction(state),
        backgroundColor: _peerPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        label: Text(
          _actionLabelForSection(),
          style: _textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
      ),
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      _buildSearchRow(),
                      const SizedBox(height: 18),
                      if (state.errorMessage != null) ...[
                        _buildErrorBanner(state.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      _buildSummaryRow(
                        groups: state.groups.length,
                        questions: state.questions.length,
                        topics: state.topics.length,
                        chats: directConversations.length,
                      ),
                      const SizedBox(height: 18),
                      _buildSectionSelector(),
                      const SizedBox(height: 18),
                      _buildSectionBody(state, directConversations),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peer Exchange',
                style: _textStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Questions, topics, groups, and direct support in one place.',
                style: _textStyle(
                  fontSize: 13,
                  color: _peerMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        _SquareIconButton(
          icon: const Icon(Icons.refresh_rounded, color: _peerText, size: 20),
          onTap: () =>
              ref.read(peerExchangeViewModelProvider.notifier).loadAll(),
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _peerBorder),
            ),
            child: TextField(
              controller: _searchController,
              style: _textStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search groups, questions, topics, or chats',
                hintStyle: _textStyle(
                  fontSize: 13,
                  color: const Color(0xFF98A2B3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(15),
                  child: AppSvgIcon(
                    assetName: 'assets/icons/search.svg',
                    color: Color(0xFFA4A4A4),
                    size: 18,
                  ),
                ),
                suffixIcon: _searchController.text.isEmpty
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
        ),
        const SizedBox(width: 12),
        _SquareIconButton(
          icon: const AppSvgIcon(
            assetName: 'assets/icons/filter.svg',
            color: _peerText,
            size: 18,
          ),
          onTap: _showOverviewActionsSheet,
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required int groups,
    required int questions,
    required int topics,
    required int chats,
  }) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(16) / 16;
    final cardHeight = (128 + ((textScaleFactor - 1) * 40)).clamp(128.0, 164.0);

    return SizedBox(
      height: cardHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _MetricCard(
            label: 'Groups',
            value: '$groups',
            subtitle: 'Active rooms',
            accent: _peerPrimary,
            background: _peerSoftBlue,
          ),
          const SizedBox(width: 12),
          _MetricCard(
            label: 'Questions',
            value: '$questions',
            subtitle: 'Open prompts',
            accent: const Color(0xFFFF8D42),
            background: _peerSoftOrange,
          ),
          const SizedBox(width: 12),
          _MetricCard(
            label: 'Topics',
            value: '$topics',
            subtitle: 'Discussion boards',
            accent: const Color(0xFF12B76A),
            background: _peerSoftGreen,
          ),
          const SizedBox(width: 12),
          _MetricCard(
            label: 'Chats',
            value: '$chats',
            subtitle: 'Direct threads',
            accent: const Color(0xFF7A5AF8),
            background: const Color(0xFFF1EDFF),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _CommunitySection.values.map((item) {
          final selected = item == _section;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _section = item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: selected ? _peerPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? _peerPrimary : _peerBorder,
                  ),
                ),
                child: Text(
                  item.label,
                  style: _textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _peerMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionBody(
    PeerExchangeState state,
    List<PeerConversation> directConversations,
  ) {
    switch (_section) {
      case _CommunitySection.inbox:
        return _buildChats(directConversations);
      case _CommunitySection.groups:
        return _buildGroups(state.groups);
      case _CommunitySection.questions:
        return _buildQuestions(state);
      case _CommunitySection.topics:
        return _buildTopics(state);
    }
  }

  Widget _buildQuestions(PeerExchangeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Q&A Forum',
          actionLabel: 'Manage categories',
          onTap: () => _showManageCategoriesSheet(state),
        ),
        const SizedBox(height: 10),
        Text(
          'Searchable professional questions with category filters and threaded replies.',
          style: _textStyle(fontSize: 13, color: _peerMuted, height: 1.45),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: state.selectedCategoryUuid == null,
                onTap: () => ref
                    .read(peerExchangeViewModelProvider.notifier)
                    .selectCategory(null),
              ),
              ...state.categories.map(
                (category) => _FilterChip(
                  label: category.name,
                  selected: state.selectedCategoryUuid == category.uuid,
                  onTap: () => ref
                      .read(peerExchangeViewModelProvider.notifier)
                      .selectCategory(category.uuid),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (state.questions.isEmpty)
          const _EmptyStateCard(
            title: 'No questions match the current filter',
            subtitle: 'Try a different category or post a new question.',
          )
        else
          ...state.questions.map(_buildQuestionCard),
      ],
    );
  }

  Widget _buildTopics(PeerExchangeState state) {
    if (state.topics.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeaderLabel(
            title: 'Moderated Topics',
            subtitle:
                'Professional topics for guided discussion and moderator-led updates.',
          ),
          const SizedBox(height: 12),
          ...state.topics.map(_buildTopicCard),
        ],
      );
    }

    if (state.topics.isEmpty) {
      return const _EmptyStateCard(
        title: 'No topics available',
        subtitle: 'Create a topic to organize focused discussion threads.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGroups(List<PeerConversation> groups) {
    if (groups.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeaderLabel(
            title: 'Closed Groups',
            subtitle:
                'Private group spaces for cohorts, task teams, and assigned members only.',
          ),
          const SizedBox(height: 12),
          ...groups.map(_buildGroupCard),
        ],
      );
    }

    if (groups.isEmpty) {
      return const _EmptyStateCard(
        title: 'No groups available',
        subtitle:
            'Create a group for shared discussions, updates, and planning.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildChats(List<PeerConversation> conversations) {
    if (conversations.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeaderLabel(
            title: 'Inbox',
            subtitle:
                'Direct one-to-one conversations with recent messages and quick follow-up.',
          ),
          const SizedBox(height: 12),
          ...conversations.map(_buildConversationCard),
        ],
      );
    }

    if (conversations.isEmpty) {
      return const _EmptyStateCard(
        title: 'No chats available',
        subtitle: 'Start a direct message thread using a receiver ID.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGroupCard(PeerConversation group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openConversation(group, isGroup: true),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _peerCard,
            borderRadius: BorderRadius.circular(20),
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.description.isNotEmpty
                              ? group.description
                              : 'Shared group conversation',
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: group.isActive
                              ? _peerSoftGreen
                              : _peerSoftOrange,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          group.isActive ? 'Active' : 'Muted',
                          style: _textStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: group.isActive
                                ? const Color(0xFF0B8F55)
                                : const Color(0xFFB95817),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildEntityMenu(
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
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    label: '${group.usersCount} members',
                    color: _peerSoftBlue,
                    textColor: _peerPrimary,
                  ),
                  _MetaChip(
                    label: '${group.messagesCount} messages',
                    color: _peerSoftOrange,
                    textColor: const Color(0xFFB95817),
                  ),
                  _MetaChip(
                    label: 'Closed group',
                    color: const Color(0xFFF2F4F7),
                    textColor: _peerMuted,
                  ),
                  _MetaChip(
                    label: _formatRelative(group.lastMessageAt),
                    color: const Color(0xFFF2F4F7),
                    textColor: _peerMuted,
                  ),
                ],
              ),
              if (group.subtitle.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  group.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    fontSize: 13,
                    color: _peerText.withValues(alpha: 0.84),
                    height: 1.5,
                  ),
                ),
              ],
              if (group.users.isNotEmpty) ...[
                const SizedBox(height: 14),
                _MemberPreviewRow(members: group.users),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(PeerQuestion question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openQuestion(question),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _peerCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _peerBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          label: question.category?.name ?? 'Uncategorized',
                          color: _peerSoftBlue,
                          textColor: _peerPrimary,
                        ),
                        _MetaChip(
                          label: '${question.commentsCount} replies',
                          color: _peerSoftOrange,
                          textColor: const Color(0xFFB95817),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatRelative(
                          question.lastCommentAt ?? question.createdAt,
                        ),
                        style: _textStyle(fontSize: 12, color: _peerMuted),
                      ),
                      const SizedBox(width: 4),
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
                ],
              ),
              const SizedBox(height: 14),
              Text(
                question.content,
                style: _textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              if (question.lastComment != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.lastComment?.author?.fullName ??
                            'Recent reply',
                        style: _textStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _peerMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        question.lastComment!.comment,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          fontSize: 13,
                          color: _peerText.withValues(alpha: 0.86),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicCard(PeerTopic topic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openTopic(topic),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _peerCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _peerBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      topic.name,
                      style: _textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatRelative(topic.lastCommentAt ?? topic.createdAt),
                        style: _textStyle(fontSize: 12, color: _peerMuted),
                      ),
                      const SizedBox(width: 4),
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
                ],
              ),
              const SizedBox(height: 8),
              Text(
                topic.description.isNotEmpty
                    ? topic.description
                    : 'Discussion topic for peer updates and coordination.',
                style: _textStyle(fontSize: 13, color: _peerMuted, height: 1.5),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    label: '${topic.commentsCount} comments',
                    color: _peerSoftGreen,
                    textColor: const Color(0xFF0B8F55),
                  ),
                  _MetaChip(
                    label: 'Moderated',
                    color: const Color(0xFFF1EDFF),
                    textColor: const Color(0xFF6941C6),
                  ),
                  _MetaChip(
                    label: '${topic.audiences.length} audiences',
                    color: _peerSoftBlue,
                    textColor: _peerPrimary,
                  ),
                ],
              ),
              if (topic.lastComment != null) ...[
                const SizedBox(height: 12),
                Text(
                  topic.lastComment!.comment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    fontSize: 13,
                    color: _peerText.withValues(alpha: 0.86),
                    height: 1.45,
                  ),
                ),
              ],
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
  }) {
    return PopupMenuButton<_ItemMenuAction>(
      icon: const Icon(Icons.more_horiz_rounded, color: _peerMuted, size: 20),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (action) async => onSelected(action),
      itemBuilder: (context) => const [
        PopupMenuItem<_ItemMenuAction>(
          value: _ItemMenuAction.edit,
          child: Text('Edit'),
        ),
        PopupMenuItem<_ItemMenuAction>(
          value: _ItemMenuAction.delete,
          child: Text('Delete'),
        ),
      ],
    );
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

  Future<void> _handlePrimaryAction(PeerExchangeState state) async {
    switch (_section) {
      case _CommunitySection.inbox:
        await _showCreateConversationSheet();
        return;
      case _CommunitySection.groups:
        await _showCreateGroupSheet();
        return;
      case _CommunitySection.questions:
        await _showCreateQuestionSheet(state);
        return;
      case _CommunitySection.topics:
        await _showCreateTopicSheet();
        return;
    }
  }

  Future<void> _showOverviewActionsSheet() async {
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
              _ActionTile(
                title: 'Ask a question',
                subtitle: 'Post a knowledge or practice question.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCreateQuestionSheet(
                    ref.read(peerExchangeViewModelProvider),
                  );
                },
              ),
              _ActionTile(
                title: 'Create a topic',
                subtitle: 'Open a structured discussion for your team.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCreateTopicSheet();
                },
              ),
              _ActionTile(
                title: 'Create a group',
                subtitle: 'Set up a shared room for a team or activity.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCreateGroupSheet();
                },
              ),
              _ActionTile(
                title: 'Start a chat',
                subtitle: 'Open a one-to-one conversation by receiver ID.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCreateConversationSheet();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showManageCategoriesSheet(PeerExchangeState state) async {
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

  Future<void> _showCreateQuestionSheet(PeerExchangeState state) async {
    if (state.categories.isEmpty) {
      _showMessage(
        'Create a question category first so questions can be classified.',
        error: true,
      );
      await _showCreateCategorySheet();
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
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

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
                                  .read(peerExchangeViewModelProvider.notifier)
                                  .createTopic(
                                    name: name,
                                    description: description,
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
  }

  Future<void> _showCreateGroupSheet() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final memberController = TextEditingController();

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
                    const _BottomSheetTitle(
                      title: 'Create a group',
                      subtitle:
                          'You can add optional member IDs now and manage more members later.',
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
                    _FormField(
                      controller: memberController,
                      label: 'Member IDs',
                      hintText: 'Optional, comma separated e.g. 12, 18, 23',
                    ),
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
                                  .read(peerExchangeViewModelProvider.notifier)
                                  .createGroup(
                                    name: name,
                                    description: descriptionController.text
                                        .trim(),
                                    memberIds: _parseIntegerList(
                                      memberController.text,
                                    ),
                                  );

                              if (created == null || !mounted) return;
                              if (!sheetContext.mounted) return;
                              Navigator.pop(sheetContext);
                              _showMessage('Group created successfully.');
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

  Future<void> _showEditGroupSheet(PeerConversation group) async {
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
    final receiverController = TextEditingController();
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
                    const _BottomSheetTitle(
                      title: 'Start a chat',
                      subtitle:
                          'Use the receiver ID from the available staff records.',
                    ),
                    _FormField(
                      controller: receiverController,
                      label: 'Receiver ID',
                      hintText: 'Enter numeric receiver ID',
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: messageController,
                      label: 'Message',
                      hintText: 'Write your first message',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: isSubmitting
                          ? 'Starting...'
                          : 'Start conversation',
                      isBusy: isSubmitting,
                      onTap: isSubmitting
                          ? null
                          : () async {
                              final receiverId = int.tryParse(
                                receiverController.text.trim(),
                              );
                              final message = messageController.text.trim();
                              if (receiverId == null) {
                                _showMessage(
                                  'Enter a valid receiver ID.',
                                  error: true,
                                );
                                return;
                              }
                              if (message.isEmpty) {
                                _showMessage(
                                  'Enter a message first.',
                                  error: true,
                                );
                                return;
                              }

                              final result = await ref
                                  .read(peerExchangeViewModelProvider.notifier)
                                  .startConversation(
                                    receiverId: receiverId,
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
                      title: 'No replies yet',
                      subtitle:
                          'Be the first person to respond to this question.',
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
                      title: 'No comments yet',
                      subtitle: 'Start the discussion with the first comment.',
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

  Future<void> _showMembersSheet() async {
    final controller = TextEditingController();

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
                const _BottomSheetTitle(
                  title: 'Group members',
                  subtitle:
                      'Add more members with user IDs or remove existing members.',
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
                                  if (member.numericId != null)
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
                const SizedBox(height: 16),
                _FormField(
                  controller: controller,
                  label: 'Add user IDs',
                  hintText: 'Comma separated e.g. 15, 28, 41',
                ),
                const SizedBox(height: 16),
                _PrimaryButton(
                  label: 'Add members',
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ids = _parseIntegerList(controller.text);
                    if (ids.isEmpty) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Enter at least one valid user ID.'),
                            backgroundColor: Color(0xFFD92D20),
                          ),
                        );
                      return;
                    }

                    Navigator.pop(sheetContext);
                    await ref
                        .read(peerExchangeRepositoryProvider)
                        .addGroupMembers(
                          groupUuid: widget.conversationUuid,
                          userIds: ids,
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
          if (widget.isGroup)
            TextButton(
              onPressed: _showMembersSheet,
              child: Text(
                'Members',
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.background,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _peerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const Spacer(),
          Text(
            value,
            style: _textStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: _peerText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _peerBorder),
        ),
        alignment: Alignment.center,
        child: icon,
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

class _SectionHeaderLabel extends StatelessWidget {
  const _SectionHeaderLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _textStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: _textStyle(fontSize: 13, color: _peerMuted, height: 1.45),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _peerPrimary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _peerPrimary : _peerBorder),
          ),
          child: Text(
            label,
            style: _textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _peerMuted,
            ),
          ),
        ),
      ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: child,
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
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLines;

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
          initialValue: value,
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

String _formatTime(DateTime? dateTime) {
  if (dateTime == null) return 'Now';
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

List<int> _parseIntegerList(String raw) {
  return raw
      .split(',')
      .map((item) => int.tryParse(item.trim()))
      .whereType<int>()
      .toSet()
      .toList();
}
