import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:staffportal/features/community/models/peer_exchange_models.dart';
import 'package:staffportal/features/community/data/peer_exchange_repository.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/providers/app_providers.dart';

const _sentinel = Object();

class PeerExchangeState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedCategoryUuid;
  final List<PeerConversation> conversations;
  final List<PeerConversation> groups;
  final List<PeerTopic> topics;
  final List<PeerQuestion> questions;
  final List<PeerQuestionCategory> categories;

  const PeerExchangeState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategoryUuid,
    this.conversations = const [],
    this.groups = const [],
    this.topics = const [],
    this.questions = const [],
    this.categories = const [],
  });

  PeerExchangeState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    String? searchQuery,
    Object? selectedCategoryUuid = _sentinel,
    List<PeerConversation>? conversations,
    List<PeerConversation>? groups,
    List<PeerTopic>? topics,
    List<PeerQuestion>? questions,
    List<PeerQuestionCategory>? categories,
  }) {
    return PeerExchangeState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryUuid: selectedCategoryUuid == _sentinel
          ? this.selectedCategoryUuid
          : selectedCategoryUuid as String?,
      conversations: conversations ?? this.conversations,
      groups: groups ?? this.groups,
      topics: topics ?? this.topics,
      questions: questions ?? this.questions,
      categories: categories ?? this.categories,
    );
  }
}

class PeerExchangeViewModel extends Notifier<PeerExchangeState> {
  late PeerExchangeRepository _repository;

  @override
  PeerExchangeState build() {
    _repository = ref.watch(peerExchangeRepositoryProvider);
    Future<void>.microtask(loadAll);
    return const PeerExchangeState();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final searchQuery = state.searchQuery.trim();
      final categoryUuid = state.selectedCategoryUuid;

      final conversations = await _loadConversations(searchQuery);
      final results = await Future.wait<dynamic>([
        _loadGroups(searchQuery),
        _loadTopics(searchQuery),
        _loadQuestions(searchQuery, categoryUuid),
        _loadCategories(),
      ]);

      state = state.copyWith(
        isLoading: false,
        conversations: conversations,
        groups: results[0] as List<PeerConversation>,
        topics: results[1] as List<PeerTopic>,
        questions: results[2] as List<PeerQuestion>,
        categories: results[3] as List<PeerQuestionCategory>,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: listLoadErrorMessage(error),
      );
    }
  }

  Future<void> setSearchQuery(String value) async {
    state = state.copyWith(searchQuery: value);
    await loadAll();
  }

  Future<void> selectCategory(String? categoryUuid) async {
    state = state.copyWith(selectedCategoryUuid: categoryUuid);
    await loadAll();
  }

  Future<PeerQuestionCategory?> createQuestionCategory(String name) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final category = await _repository.createQuestionCategory(name: name);
      final categories = [...state.categories, category]
        ..sort((left, right) => left.name.compareTo(right.name));

      state = state.copyWith(isSubmitting: false, categories: categories);
      return category;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: friendlyErrorMessage(error),
      );
      return null;
    }
  }

  Future<PeerQuestion?> createQuestion({
    required String categoryUuid,
    required String content,
    List<MultipartFile> attachments = const [],
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final question = await _repository.createQuestion(
        categoryUuid: categoryUuid,
        content: content,
        attachments: attachments,
      );
      state = state.copyWith(
        isSubmitting: false,
        questions: _upsertQuestion(state.questions, question),
      );
      return question;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: friendlyErrorMessage(error),
      );
      return null;
    }
  }

  void recordQuestionComment({
    required String questionUuid,
    required PeerComment comment,
  }) {
    state = state.copyWith(
      questions: _recordQuestionComment(state.questions, questionUuid, comment),
    );
  }

  void recordTopicComment({
    required String topicUuid,
    required PeerComment comment,
  }) {
    state = state.copyWith(
      topics: _recordTopicComment(state.topics, topicUuid, comment),
    );
  }

  Future<PeerTopic?> createTopic({
    required String name,
    String? description,
    PeerTopicAudienceSelection? audiences,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final topic = await _repository.createTopic(
        name: name,
        description: description,
        audiences: audiences,
      );
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return topic;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: friendlyErrorMessage(error),
      );
      return null;
    }
  }

  Future<PeerConversation?> createGroup({
    required String name,
    String? description,
    List<int> memberIds = const [],
    bool stationGroup = false,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final group = stationGroup
          ? await _repository.createStationGroup(
              name: name.trim().isEmpty ? null : name,
              description: description,
            )
          : await _repository.createGroup(
              name: name,
              description: description,
              memberIds: memberIds,
            );
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return group;
    } catch (error) {
      log(error.toString());
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: friendlyErrorMessage(error),
      );
      return null;
    }
  }

  Future<PeerConversation?> startConversation({
    required int receiverId,
    required String message,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final conversation = await _repository.startDirectConversation(
        receiverId: receiverId,
        message: message,
      );
      state = state.copyWith(
        isSubmitting: false,
        conversations: _upsertConversation(state.conversations, conversation),
      );
      return conversation;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: friendlyErrorMessage(error),
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<List<PeerConversation>> _loadConversations(String searchQuery) async {
    try {
      return await _repository.fetchConversations(search: searchQuery);
    } catch (_) {
      return [];
    }
  }

  List<PeerConversation> _upsertConversation(
    List<PeerConversation> source,
    PeerConversation conversation,
  ) {
    final next = [
      conversation,
      ...source.where((item) => item.uuid != conversation.uuid),
    ];
    next.sort((left, right) {
      final leftDate =
          left.lastMessageAt ?? left.updatedAt ?? left.createdAt ?? DateTime(0);
      final rightDate =
          right.lastMessageAt ??
          right.updatedAt ??
          right.createdAt ??
          DateTime(0);
      return rightDate.compareTo(leftDate);
    });
    return next;
  }

  List<PeerQuestion> _upsertQuestion(
    List<PeerQuestion> source,
    PeerQuestion question,
  ) {
    if (!_questionMatchesCurrentFilters(question)) {
      return source;
    }

    final next = [
      question,
      ...source.where((item) => item.uuid != question.uuid),
    ];
    next.sort(_sortQuestions);
    return next;
  }

  List<PeerQuestion> _recordQuestionComment(
    List<PeerQuestion> source,
    String questionUuid,
    PeerComment comment,
  ) {
    var didUpdate = false;
    final next = source.map((question) {
      if (question.uuid != questionUuid) return question;
      didUpdate = true;
      final alreadyCounted =
          comment.uuid.isNotEmpty && question.lastComment?.uuid == comment.uuid;
      return question.copyWith(
        commentsCount: alreadyCounted
            ? question.commentsCount
            : question.commentsCount + 1,
        lastComment: comment,
        lastCommentAt: comment.createdAt ?? DateTime.now(),
        updatedAt: comment.createdAt ?? DateTime.now(),
      );
    }).toList();
    if (!didUpdate) return source;
    next.sort(_sortQuestions);
    return next;
  }

  List<PeerTopic> _recordTopicComment(
    List<PeerTopic> source,
    String topicUuid,
    PeerComment comment,
  ) {
    var didUpdate = false;
    final next = source.map((topic) {
      if (topic.uuid != topicUuid) return topic;
      didUpdate = true;
      final alreadyCounted =
          comment.uuid.isNotEmpty && topic.lastComment?.uuid == comment.uuid;
      return topic.copyWith(
        commentsCount: alreadyCounted
            ? topic.commentsCount
            : topic.commentsCount + 1,
        lastComment: comment,
        lastCommentAt: comment.createdAt ?? DateTime.now(),
        updatedAt: comment.createdAt ?? DateTime.now(),
      );
    }).toList();
    if (!didUpdate) return source;
    next.sort(_sortTopics);
    return next;
  }

  bool _questionMatchesCurrentFilters(PeerQuestion question) {
    final selectedCategoryUuid = state.selectedCategoryUuid?.trim();
    if (selectedCategoryUuid != null &&
        selectedCategoryUuid.isNotEmpty &&
        question.categoryUuid != selectedCategoryUuid) {
      return false;
    }

    final query = state.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return question.content.toLowerCase().contains(query) ||
        (question.category?.name ?? '').toLowerCase().contains(query);
  }

  int _sortQuestions(PeerQuestion left, PeerQuestion right) {
    final leftDate =
        left.lastCommentAt ?? left.updatedAt ?? left.createdAt ?? DateTime(0);
    final rightDate =
        right.lastCommentAt ??
        right.updatedAt ??
        right.createdAt ??
        DateTime(0);
    return rightDate.compareTo(leftDate);
  }

  int _sortTopics(PeerTopic left, PeerTopic right) {
    final leftDate =
        left.lastCommentAt ?? left.updatedAt ?? left.createdAt ?? DateTime(0);
    final rightDate =
        right.lastCommentAt ??
        right.updatedAt ??
        right.createdAt ??
        DateTime(0);
    return rightDate.compareTo(leftDate);
  }

  Future<List<PeerConversation>> _loadGroups(String searchQuery) async {
    try {
      return await _repository.fetchGroups(search: searchQuery);
    } catch (_) {
      return const [];
    }
  }

  Future<List<PeerTopic>> _loadTopics(String searchQuery) async {
    try {
      return await _repository.fetchTopics(search: searchQuery);
    } catch (_) {
      return const [];
    }
  }

  Future<List<PeerQuestion>> _loadQuestions(
    String searchQuery,
    String? categoryUuid,
  ) async {
    try {
      return await _repository.fetchQuestions(
        search: searchQuery,
        categoryUuid: categoryUuid,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<List<PeerQuestionCategory>> _loadCategories() async {
    try {
      return await _repository.fetchQuestionCategories();
    } catch (_) {
      return const [];
    }
  }
}
