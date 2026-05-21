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
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return question;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: friendlyErrorMessage(error),
      );
      return null;
    }
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

  Future<PeerMessage?> startConversation({
    required int receiverId,
    required String message,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final result = await _repository.sendConversationMessage(
        receiverId: receiverId,
        message: message,
      );
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return result;
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
