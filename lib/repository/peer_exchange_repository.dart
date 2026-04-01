import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/network/api_service.dart';
import '../model/peer_exchange_models.dart';

class PeerExchangeRepository {
  PeerExchangeRepository()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiService.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {'Accept': 'application/json'},
        ),
      );

  final Dio _dio;

  Future<List<PeerConversation>> fetchConversations({
    String? search,
    int perPage = 20,
  }) async {
    final response = await _get(
      '/conversations',
      queryParameters: _cleanMap({'search': search, 'perPage': perPage}),
    );

    return _listFromResponse(
      response.data['conversations'],
      PeerConversation.fromJson,
    );
  }

  Future<PeerConversation> fetchConversationDetail(
    String conversationUuid,
  ) async {
    final response = await _get('/conversations/$conversationUuid');
    return PeerConversation.fromJson(
      _requireMap(response.data['conversation'], 'conversation'),
    );
  }

  Future<PeerMessage> sendConversationMessage({
    String? conversationUuid,
    int? receiverId,
    required String message,
    String? replyToUuid,
  }) async {
    final response = await _postForm(
      '/conversations/messages',
      data: _cleanMap({
        'conversation_uuid': conversationUuid,
        'receiver_id': receiverId,
        'message': message,
        'reply_to_uuid': replyToUuid,
      }),
    );

    return PeerMessage.fromJson(
      _requireMap(
        response.data['conversation_message'],
        'conversation_message',
      ),
    );
  }

  Future<List<PeerConversation>> fetchGroups({
    String? search,
    int perPage = 20,
  }) async {
    final response = await _get(
      '/conversations/groups',
      queryParameters: _cleanMap({'search': search, 'perPage': perPage}),
    );

    return _listFromResponse(
      response.data['groups'],
      PeerConversation.fromJson,
    );
  }

  Future<PeerConversation> fetchGroupDetail(String groupUuid) async {
    final response = await _get('/conversations/groups/$groupUuid');
    return PeerConversation.fromJson(
      _requireMap(response.data['group'], 'group'),
    );
  }

  Future<PeerConversation> createGroup({
    required String name,
    String? description,
    List<int> memberIds = const [],
  }) async {
    final response = await _postForm(
      '/conversations/groups',
      data: _cleanMap({
        'name': name,
        'description': description,
        'member_ids': memberIds.isEmpty ? null : memberIds,
      }),
      listFormat: ListFormat.multiCompatible,
    );

    return PeerConversation.fromJson(
      _requireMap(response.data['group'], 'group'),
    );
  }

  Future<PeerConversation> updateGroup({
    required String groupUuid,
    required String name,
    String? description,
  }) async {
    final response = await _putForm(
      '/conversations/groups/$groupUuid',
      data: _cleanMap({'name': name, 'description': description}),
    );

    return PeerConversation.fromJson(
      _requireMap(response.data['group'], 'group'),
    );
  }

  Future<void> deleteGroup(String groupUuid) async {
    await _delete('/conversations/groups/$groupUuid');
  }

  Future<List<PeerMember>> fetchGroupMembers(String groupUuid) async {
    final response = await _get('/conversations/groups/$groupUuid/members');
    return _listFromResponse(response.data['members'], PeerMember.fromJson);
  }

  Future<List<PeerMember>> addGroupMembers({
    required String groupUuid,
    required List<int> userIds,
  }) async {
    final response = await _postJson(
      '/conversations/groups/$groupUuid/members',
      data: {'user_ids': userIds},
    );

    return _listFromResponse(response.data['members'], PeerMember.fromJson);
  }

  Future<void> removeGroupMember({
    required String groupUuid,
    required int userId,
  }) async {
    await _delete('/conversations/groups/$groupUuid/members/$userId');
  }

  Future<List<PeerQuestionCategory>> fetchQuestionCategories({
    String? search,
    int perPage = 20,
  }) async {
    final response = await _get(
      '/question-categories',
      queryParameters: _cleanMap({'search': search, 'perPage': perPage}),
    );

    return _listFromResponse(
      response.data['question_categories'],
      PeerQuestionCategory.fromJson,
    );
  }

  Future<PeerQuestionCategory> createQuestionCategory({
    required String name,
  }) async {
    final response = await _postJson(
      '/question-categories',
      data: {'name': name},
    );

    return PeerQuestionCategory.fromJson(
      _requireMap(response.data['question_category'], 'question_category'),
    );
  }

  Future<PeerQuestionCategory> updateQuestionCategory({
    required String categoryUuid,
    required String name,
  }) async {
    final response = await _putJson(
      '/question-categories/$categoryUuid',
      data: {'name': name},
    );

    return PeerQuestionCategory.fromJson(
      _requireMap(response.data['question_category'], 'question_category'),
    );
  }

  Future<void> deleteQuestionCategory(String categoryUuid) async {
    await _delete('/question-categories/$categoryUuid');
  }

  Future<List<PeerQuestion>> fetchQuestions({
    String? search,
    String? categoryUuid,
    int perPage = 20,
  }) async {
    final response = await _get(
      '/questions',
      queryParameters: _cleanMap({
        'search': search,
        'category_uuid': categoryUuid,
        'perPage': perPage,
      }),
    );

    return _listFromResponse(response.data['questions'], PeerQuestion.fromJson);
  }

  Future<PeerQuestion> createQuestion({
    required String categoryUuid,
    required String content,
  }) async {
    final response = await _postForm(
      '/questions',
      data: {'category_uuid': categoryUuid, 'content': content},
    );

    return PeerQuestion.fromJson(
      _requireMap(response.data['question'], 'question'),
    );
  }

  Future<PeerQuestion> updateQuestion({
    required String questionUuid,
    required String categoryUuid,
    required String content,
  }) async {
    final response = await _putForm(
      '/questions/$questionUuid',
      data: {'category_uuid': categoryUuid, 'content': content},
    );

    return PeerQuestion.fromJson(
      _requireMap(response.data['question'], 'question'),
    );
  }

  Future<void> deleteQuestion(String questionUuid) async {
    await _delete('/questions/$questionUuid');
  }

  Future<List<PeerComment>> fetchQuestionComments(
    String questionUuid, {
    int perPage = 50,
  }) async {
    final response = await _get(
      '/questions/$questionUuid/comments',
      queryParameters: {'perPage': perPage},
    );

    return _listFromResponse(response.data['comments'], PeerComment.fromJson);
  }

  Future<PeerComment> createQuestionComment({
    required String questionUuid,
    required String message,
  }) async {
    final response = await _postForm(
      '/questions/$questionUuid/comments',
      data: {'message': message},
    );

    return PeerComment.fromJson(
      _requireMap(response.data['comment'], 'comment'),
    );
  }

  Future<List<PeerTopic>> fetchTopics({
    String? search,
    int perPage = 20,
  }) async {
    final response = await _get(
      '/topics',
      queryParameters: _cleanMap({'search': search, 'perPage': perPage}),
    );

    return _listFromResponse(response.data['topics'], PeerTopic.fromJson);
  }

  Future<PeerTopic> createTopic({
    required String name,
    String? description,
  }) async {
    final response = await _postJson(
      '/topics',
      data: _cleanMap({'name': name, 'description': description}),
    );

    return PeerTopic.fromJson(_requireMap(response.data['topic'], 'topic'));
  }

  Future<PeerTopic> updateTopic({
    required String topicUuid,
    required String name,
    String? description,
  }) async {
    final response = await _putJson(
      '/topics/$topicUuid',
      data: _cleanMap({'name': name, 'description': description}),
    );

    return PeerTopic.fromJson(_requireMap(response.data['topic'], 'topic'));
  }

  Future<void> deleteTopic(String topicUuid) async {
    await _delete('/topics/$topicUuid');
  }

  Future<List<PeerComment>> fetchTopicComments(
    String topicUuid, {
    int perPage = 50,
  }) async {
    final response = await _get(
      '/topics/$topicUuid/comments',
      queryParameters: {'perPage': perPage},
    );

    return _listFromResponse(response.data['comments'], PeerComment.fromJson);
  }

  Future<PeerComment> createTopicComment({
    required String topicUuid,
    required String message,
  }) async {
    final response = await _postForm(
      '/topics/$topicUuid/comments',
      data: {'message': message},
    );

    return PeerComment.fromJson(
      _requireMap(response.data['comment'], 'comment'),
    );
  }

  Future<List<PeerDirectoryPerson>> fetchStaffDirectory({
    String? search,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final workingStationId = prefs.getString('working_station_id') ?? '';
    final currentUserId = prefs.getString('user_id') ?? '';
    final paths = <String>[
      '/userAccounts',
      '/getAllSectionStaff',
      if (workingStationId.trim().isNotEmpty)
        '/getAllEmployee/$workingStationId',
      if (workingStationId.trim().isNotEmpty)
        '/getActiveEmployee/$workingStationId',
    ];

    for (final path in paths) {
      try {
        final response = await _get(path);
        final people = _directoryPeopleFromResponse(
          response.data,
        ).where((person) => person.id.toString() != currentUserId).toList();
        if (people.isNotEmpty) {
          return _filterDirectoryPeople(people, search);
        }
      } catch (_) {
        continue;
      }
    }

    return const [];
  }

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: await _authorizedOptions(),
      );
    } on DioException catch (error) {
      throw Exception(_resolveMessage(error));
    }
  }

  Future<Response<dynamic>> _postJson(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: await _authorizedOptions(
          extraHeaders: const {'Content-Type': 'application/json'},
        ),
      );
    } on DioException catch (error) {
      throw Exception(_resolveMessage(error));
    }
  }

  Future<Response<dynamic>> _putJson(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        options: await _authorizedOptions(
          extraHeaders: const {'Content-Type': 'application/json'},
        ),
      );
    } on DioException catch (error) {
      throw Exception(_resolveMessage(error));
    }
  }

  Future<Response<dynamic>> _postForm(
    String path, {
    required Map<String, dynamic> data,
    ListFormat listFormat = ListFormat.multi,
  }) async {
    try {
      return await _dio.post(
        path,
        data: FormData.fromMap(data, listFormat),
        options: await _authorizedOptions(
          extraHeaders: const {'Content-Type': 'multipart/form-data'},
        ),
      );
    } on DioException catch (error) {
      throw Exception(_resolveMessage(error));
    }
  }

  Future<Response<dynamic>> _putForm(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dio.put(
        path,
        data: FormData.fromMap(data),
        options: await _authorizedOptions(
          extraHeaders: const {'Content-Type': 'multipart/form-data'},
        ),
      );
    } on DioException catch (error) {
      throw Exception(_resolveMessage(error));
    }
  }

  Future<Response<dynamic>> _delete(String path) async {
    try {
      return await _dio.delete(path, options: await _authorizedOptions());
    } on DioException catch (error) {
      throw Exception(_resolveMessage(error));
    }
  }

  Future<Options> _authorizedOptions({
    Map<String, String>? extraHeaders,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication token not found. Please sign in again.');
    }

    return Options(
      headers: {'Authorization': 'Bearer $token', ...?extraHeaders},
    );
  }

  String _resolveMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return error.message ?? 'Something went wrong while contacting the server.';
  }

  List<T> _listFromResponse<T>(
    dynamic source,
    T Function(Map<String, dynamic> json) parser,
  ) {
    if (source is! List) return const [];

    return source
        .whereType<Map>()
        .map(
          (item) =>
              parser(item.map((key, value) => MapEntry(key.toString(), value))),
        )
        .toList();
  }

  Map<String, dynamic> _requireMap(dynamic value, String key) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((entryKey, entryValue) {
        return MapEntry(entryKey.toString(), entryValue);
      });
    }
    throw Exception('Invalid server response for $key.');
  }

  Map<String, dynamic> _cleanMap(Map<String, dynamic> values) {
    final result = <String, dynamic>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      result[entry.key] = value;
    }
    return result;
  }

  List<PeerDirectoryPerson> _directoryPeopleFromResponse(dynamic source) {
    final resolved = _unwrapDirectoryPayload(source);
    final rawList = _extractDirectoryList(resolved);

    return rawList
        .map(PeerDirectoryPerson.fromJson)
        .where((person) => person.id > 0)
        .toList();
  }

  dynamic _unwrapDirectoryPayload(dynamic source) {
    if (source is Map<String, dynamic>) {
      final data = source['data'];
      if (data is String) {
        final parsed = _tryDecodeJson(data);
        return parsed ?? source;
      }
      if (data != null) {
        return data;
      }
    }
    if (source is Map && source['data'] != null) {
      final data = source['data'];
      if (data is String) {
        final parsed = _tryDecodeJson(data);
        return parsed ?? source;
      }
      return data;
    }
    if (source is String) {
      return _tryDecodeJson(source) ?? source;
    }
    return source;
  }

  dynamic _tryDecodeJson(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!(trimmed.startsWith('[') || trimmed.startsWith('{'))) return null;

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _extractDirectoryList(dynamic source) {
    if (source is List) {
      return source
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    }

    if (source is Map<String, dynamic>) {
      for (final key in const [
        'data',
        'employees',
        'staff',
        'users',
        'records',
        'items',
      ]) {
        final value = source[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map(
                (item) => item.map((entryKey, entryValue) {
                  return MapEntry('$entryKey', entryValue);
                }),
              )
              .toList();
        }
      }
    }

    if (source is Map) {
      return _extractDirectoryList(
        source.map((key, value) => MapEntry('$key', value)),
      );
    }

    return const [];
  }

  List<PeerDirectoryPerson> _filterDirectoryPeople(
    List<PeerDirectoryPerson> people,
    String? search,
  ) {
    final query = (search ?? '').trim().toLowerCase();
    if (query.isEmpty) {
      return people;
    }

    return people.where((person) {
      final haystack = [
        person.fullName,
        person.email,
        person.phoneNo,
        person.title,
        person.workingStationName,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }
}
