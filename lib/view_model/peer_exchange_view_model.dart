import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/peer_exchange_models.dart';
import '../repository/peer_exchange_repository.dart';
import 'providers.dart';

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

      final results = await Future.wait<dynamic>([
        _repository.fetchConversations(search: searchQuery),
        _repository.fetchGroups(search: searchQuery),
        _repository.fetchTopics(search: searchQuery),
        _repository.fetchQuestions(
          search: searchQuery,
          categoryUuid: categoryUuid,
        ),
        _repository.fetchQuestionCategories(),
      ]);

      state = state.copyWith(
        isLoading: false,
        conversations: results[0] as List<PeerConversation>,
        groups: results[1] as List<PeerConversation>,
        topics: results[2] as List<PeerTopic>,
        questions: results[3] as List<PeerQuestion>,
        categories: results[4] as List<PeerQuestionCategory>,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
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
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<PeerQuestion?> createQuestion({
    required String categoryUuid,
    required String content,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final question = await _repository.createQuestion(
        categoryUuid: categoryUuid,
        content: content,
      );
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return question;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<PeerTopic?> createTopic({
    required String name,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final topic = await _repository.createTopic(
        name: name,
        description: description,
      );
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return topic;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<PeerConversation?> createGroup({
    required String name,
    String? description,
    List<int> memberIds = const [],
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final group = await _repository.createGroup(
        name: name,
        description: description,
        memberIds: memberIds,
      );
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return group;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
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
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
