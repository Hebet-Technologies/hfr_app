import 'package:dio/dio.dart';

import '../data/network/api_service.dart';
import '../model/training_models.dart';
import '../model/user_model.dart';
import 'auth_repository.dart';

class TrainingRepository {
  TrainingRepository(this._authRepository);

  final AuthRepository _authRepository;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );

  Future<List<TrainingProgram>> fetchLatestTrainings({
    List<TrainingProgram> myTrainings = const [],
  }) async {
    final response = await _get('/getPublishedDevelopmentPlanCurrentYear');
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return const [];
    }

    final byDevelopmentPlanVendorId = <String, TrainingProgram>{};
    for (final item in myTrainings) {
      final key = _stringValue(item.developmentPlanVendorId);
      if (key.isNotEmpty) {
        byDevelopmentPlanVendorId[key] = item;
      }
    }

    final programs = <TrainingProgram>[];
    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      final developmentPlanVendorId = _stringValue(
        item['development_plan_vendor_id'],
      );
      final matchedTraining =
          byDevelopmentPlanVendorId[developmentPlanVendorId];
      final availableSlots = _intValue(item['quantity']);
      final educationLevelName = _stringValue(item['education_level_name']);
      final caderName = _stringValue(item['cader_name'], fallback: 'Staff');
      final trainingType = _boolValue(item['is_short_course'])
          ? 'Short Course'
          : _stringValue(item['training_name'], fallback: 'Training');
      final title = matchedTraining?.title.isNotEmpty == true
          ? matchedTraining!.title
          : _compact([trainingType, caderName, educationLevelName]).join(' - ');
      final organizer = _stringValue(
        item['vendor_name'],
        fallback: 'Ministry of Health Zanzibar',
      );
      final location = matchedTraining?.location.isNotEmpty == true
          ? matchedTraining!.location
          : _stringValue(item['institute_name'], fallback: organizer);

      programs.add(
        TrainingProgram(
          id: 'latest-$developmentPlanVendorId-${index + 1}',
          title: title,
          trainingType: trainingType,
          organizer: organizer,
          location: location,
          description: _compact([
            _stringValue(item['description']),
            'Organised with $organizer for $caderName teams.',
          ]).join(' '),
          targetCadres: _resolveTargetCadres(
            item,
            fallbackCadres: const ['Staff Members'],
          ),
          badge: trainingType,
          status:
              matchedTraining?.status ?? TrainingParticipationStatus.notApplied,
          availableSlots: availableSlots,
          participantCount:
              matchedTraining?.participantCount ??
              (availableSlots > 3 ? availableSlots - 3 : availableSlots),
          resources: matchedTraining?.resources ?? const [],
          startDate: _dateValue(item['start_date']),
          endDate: _dateValue(item['end_date']),
          trainingApplicationId: matchedTraining?.trainingApplicationId,
          developmentPlanVendorId: developmentPlanVendorId,
          instituteId: matchedTraining?.instituteId,
          educationLevelId: matchedTraining?.educationLevelId,
          educationLevelName: educationLevelName.isNotEmpty
              ? educationLevelName
              : null,
          workingStationName: matchedTraining?.workingStationName,
          batchYear: _stringValue(item['batch_year']),
          workingExperienceLabel: _stringValue(item['working_expirience']),
          isLive: true,
          canApplyLive: false,
        ),
      );
    }

    try {
      final shortCourses = await fetchShortCoursePlans(
        myTrainings: myTrainings,
      );
      programs.addAll(shortCourses);
    } catch (_) {}

    programs.sort(_sortProgramsByDate);
    return programs;
  }

  Future<List<TrainingProgram>> fetchShortCoursePlans({
    List<TrainingProgram> myTrainings = const [],
  }) async {
    final response = await _get('/shortCoursePlans');
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return const [];
    }

    final myByShortCourseId = <String, TrainingProgram>{};
    for (final item in myTrainings) {
      final key = _stringValue(item.shortCourseDescriptionId);
      if (key.isNotEmpty) {
        myByShortCourseId[key] = item;
      }
    }

    return items.map((item) {
      final shortCourseId = _stringValue(item['short_course_descr_id']);
      final programId = _stringValue(item['program_id']);
      final matchedTraining = myByShortCourseId[shortCourseId];
      final startDate = _dateValue(item['start_date']);
      final endDate = _dateValue(item['end_date']);
      final title = _stringValue(
        item['program_name'],
        fallback: _stringValue(item['training_name'], fallback: 'Short Course'),
      );
      final venue = _stringValue(
        item['venue_place'],
        fallback: 'Training Venue',
      );

      return TrainingProgram(
        id: 'short-course-$shortCourseId',
        title: title,
        trainingType: 'Short Course',
        organizer: _stringValue(
          item['vendor_name'],
          fallback: 'Ministry of Health Zanzibar',
        ),
        location: venue,
        description:
            'Short course scheduled for staff development and practical capacity building.',
        targetCadres: _compact([
          _stringValue(item['cader_name']),
          _stringValue(item['education_level_name']),
          'Staff Members',
        ]),
        badge: 'Short Course',
        status:
            matchedTraining?.status ?? TrainingParticipationStatus.notApplied,
        availableSlots: _intValue(item['quantity'], fallback: 1),
        participantCount: matchedTraining?.participantCount ?? 0,
        resources: matchedTraining?.resources ?? const [],
        startDate: startDate,
        endDate: endDate,
        trainingApplicationId: matchedTraining?.trainingApplicationId,
        shortCourseDescriptionId: shortCourseId,
        programId: programId,
        workingStationName: matchedTraining?.workingStationName,
        isLive: true,
        canApplyLive: shortCourseId.isNotEmpty && programId.isNotEmpty,
      );
    }).toList();
  }

  Future<List<TrainingProgram>> fetchMyTrainings(UserModel user) async {
    if (user.personalInformationId.trim().isEmpty) {
      return const [];
    }

    final response = await _postJson(
      '/viewStaffTrainingRequest',
      data: {'personal_information_id': user.personalInformationId},
    );
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return const [];
    }

    final programs = items
        .map(
          (item) => TrainingProgram(
            id: 'my-${_stringValue(item['training_application_id'], fallback: _stringValue(item['development_plan_vendor_id']))}',
            title: _stringValue(
              item['training_name'],
              fallback:
                  '${_stringValue(item['cader_name'], fallback: 'Staff')} Training',
            ),
            trainingType: _stringValue(
              item['education_level_name'],
              fallback: 'Internal Training',
            ),
            organizer: _stringValue(
              item['vendor_name'],
              fallback: 'Ministry of Health Zanzibar',
            ),
            location: _stringValue(
              item['institute_name'],
              fallback: 'Training Institute',
            ),
            description:
                'Training application submitted through the staff portal and awaiting the next workflow action.',
            targetCadres: _compact([
              _stringValue(item['cader_name']),
              _stringValue(item['education_level_name']),
              user.workingStationName,
            ]),
            badge: 'Internal',
            status: TrainingParticipationStatusX.fromRaw(
              item['training_app_status'],
            ),
            availableSlots: 25,
            participantCount: 25,
            resources: const [],
            startDate: _dateValue(item['start_date']),
            endDate: _dateValue(item['end_date']),
            trainingApplicationId: _stringValue(
              item['training_application_id'],
            ),
            developmentPlanVendorId: _stringValue(
              item['development_plan_vendor_id'],
            ),
            instituteId: _stringValue(item['institute_id']),
            educationLevelId: _stringValue(item['education_level_id']),
            educationLevelName: _stringValue(item['education_level_name']),
            workingStationName: user.workingStationName,
            batchYear: _stringValue(item['batch_year']),
            isLive: true,
            canApplyLive: false,
          ),
        )
        .toList();

    try {
      programs.addAll(await fetchMyShortCourseRequests(user));
    } catch (_) {}

    programs.sort(_sortProgramsByDate);
    return programs;
  }

  Future<List<TrainingProgram>> fetchMyShortCourseRequests(
    UserModel user,
  ) async {
    if (user.personalInformationId.trim().isEmpty) {
      return const [];
    }

    final response = await _postJson(
      '/viewStaffShortCourseRequest',
      data: {'personal_information_id': user.personalInformationId},
    );
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return const [];
    }

    return items.map((item) {
      final title = _stringValue(
        item['program_name'],
        fallback: 'Short Course',
      );
      final startDate = _dateValue(item['start_date']);
      final endDate = _dateValue(item['end_date']);
      final shortCourseId = _stringValue(item['short_course_descr_id']);

      return TrainingProgram(
        id: 'my-short-${_stringValue(item['short_course_application_id'], fallback: '$title-${_stringValue(item['start_date'])}')}',
        title: title,
        trainingType: 'Short Course',
        organizer: 'Ministry of Health Zanzibar',
        location: _stringValue(item['venue_place'], fallback: 'Training Venue'),
        description:
            'Short course request submitted through the staff portal and awaiting workflow review.',
        targetCadres: _compact([user.workingStationName, 'Staff Members']),
        badge: 'Short Course',
        status: TrainingParticipationStatusX.fromRaw(
          item['short_course_status'],
        ),
        availableSlots: 1,
        participantCount: 1,
        resources: const [],
        startDate: startDate,
        endDate: endDate,
        trainingApplicationId: _stringValue(
          item['short_course_application_id'],
        ),
        shortCourseDescriptionId: shortCourseId,
        programId: _stringValue(item['program_id']),
        workingStationName: _stringValue(
          item['working_station_name'],
          fallback: user.workingStationName,
        ),
        isLive: true,
        canApplyLive: false,
      );
    }).toList();
  }

  Future<List<TrainingResource>> fetchResources(UserModel user) async {
    if (user.personalInformationId.trim().isEmpty) {
      return const [];
    }

    final response = await _postJson(
      '/viewStaffTrainingRequestAttachment',
      data: {'personal_information_id': user.personalInformationId},
    );
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return const [];
    }

    final resources = items.map((item) {
      final fileName = _stringValue(
        item['file_name'],
        fallback: _stringValue(item['upload_file_name']),
      );
      final filePath = _resolveTrainingFileUrl(
        fileName: fileName,
        filePath: _stringValue(
          item['file_url'],
          fallback: _stringValue(item['file_path']),
        ),
      );
      return TrainingResource(
        id: 'resource-${_stringValue(item['training_attachment_id'], fallback: fileName)}',
        title: _stringValue(item['upload_name'], fallback: 'Training Resource'),
        sizeLabel: _resolveFileSize(fileName),
        fileName: fileName.isNotEmpty ? fileName : 'resource.pdf',
        filePath: filePath,
        fileType: _fileTypeFor(fileName),
        isLive: true,
      );
    }).toList();

    resources.sort((first, second) => first.title.compareTo(second.title));
    return resources;
  }

  Future<TrainingProgram> fetchTrainingDetails(TrainingProgram training) async {
    final trainingApplicationId = _stringValue(training.trainingApplicationId);
    if (trainingApplicationId.isEmpty) {
      return training;
    }

    final response = await _postJson(
      '/getTrainingRequestMoreDetails',
      data: {'training_application_id': trainingApplicationId},
    );

    final details = _extractList(response.data);
    final detail = details.isNotEmpty
        ? details.first
        : const <String, dynamic>{};
    final attachments = _extractNamedList(response.data, 'attachment');
    final resources = attachments
        .map(
          (item) => TrainingResource(
            id: 'attachment-$trainingApplicationId-${_stringValue(item['upload_type_id'], fallback: _stringValue(item['upload_name']))}',
            title: _stringValue(
              item['upload_name'],
              fallback: 'Training Attachment',
            ),
            sizeLabel: _resolveFileSize(_stringValue(item['upload_file_name'])),
            fileName: _stringValue(
              item['upload_file_name'],
              fallback: 'attachment.pdf',
            ),
            filePath: _resolveTrainingFileUrl(
              fileName: _stringValue(item['upload_file_name']),
              filePath: _stringValue(
                item['file_url'],
                fallback: _stringValue(item['file_path']),
              ),
            ),
            fileType: _fileTypeFor(_stringValue(item['upload_file_name'])),
            isLive: true,
          ),
        )
        .toList();

    return training.copyWith(
      title: _stringValue(detail['training_name'], fallback: training.title),
      organizer: _stringValue(
        detail['vendor_name'],
        fallback: training.organizer,
      ),
      location: _stringValue(
        detail['institute_name'],
        fallback: training.location,
      ),
      targetCadres: _compact([
        _stringValue(detail['cader_name']),
        training.educationLevelName ??
            _stringValue(detail['education_level_name']),
        _stringValue(detail['working_station_name']),
      ]),
      status: TrainingParticipationStatusX.fromRaw(
        detail['training_app_status'],
      ),
      resources: resources.isNotEmpty ? resources : training.resources,
      trainingApplicationId: trainingApplicationId,
      developmentPlanVendorId: _stringValue(
        detail['development_plan_vendor_id'],
        fallback: _stringValue(training.developmentPlanVendorId),
      ),
      instituteId: _stringValue(
        detail['institute_id'],
        fallback: _stringValue(training.instituteId),
      ),
      workingStationName: _stringValue(
        detail['working_station_name'],
        fallback: _stringValue(training.workingStationName),
      ),
      isLive: true,
      canApplyLive: false,
    );
  }

  Future<List<TrainingApprovalRecord>> fetchApprovalQueue({
    List<TrainingProgram> publishedTrainings = const [],
  }) async {
    final response = await _get('/getTrainingRequestForForwarding');
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return const [];
    }

    final approvals = items.map((item) {
      final fallbackProgram = _findMatchingPublishedTraining(
        item['training_name'],
        publishedTrainings,
      );
      final resources = <TrainingResource>[];
      final listResource = _approvalResourceFromItem(
        item,
        idPrefix:
            'approval-list-${_stringValue(item['training_application_id'])}',
      );
      if (listResource != null) {
        resources.add(listResource);
      }

      return TrainingApprovalRecord(
        id: 'approval-${_stringValue(item['training_application_id'])}',
        trainingApplicationId: _stringValue(item['training_application_id']),
        trainingAppStatusId: _stringValue(item['training_app_status_id']),
        title: _stringValue(item['training_name'], fallback: 'Training'),
        applicantName: _fullName(
          item['first_name'],
          item['middle_name'],
          item['last_name'],
        ),
        applicantPhone: _stringValue(item['phone_no']),
        applicantEmail: _stringValue(item['email']),
        applicantGender: _stringValue(item['gender']),
        vendorName: _stringValue(item['vendor_name']),
        cadreName: _stringValue(item['cader_name']),
        instituteName: _stringValue(item['institute_name']),
        educationLevelName: _stringValue(item['education_level_name']),
        batchYear: _stringValue(item['batch_year']),
        workingStationName: _stringValue(item['working_station_name']),
        rawStatus: _stringValue(item['training_app_status']),
        startDate: fallbackProgram?.startDate,
        endDate: fallbackProgram?.endDate,
        resources: resources,
        isLive: true,
      );
    }).toList();

    approvals.sort(
      (first, second) => first.applicantName.compareTo(second.applicantName),
    );
    return approvals;
  }

  Future<TrainingApprovalRecord> fetchApprovalDetails(
    TrainingApprovalRecord record, {
    TrainingProgram? fallbackProgram,
  }) async {
    final response = await _postJson(
      '/getTrainingRequestMoreDetails',
      data: {'training_application_id': record.trainingApplicationId},
    );

    final details = _extractList(response.data);
    final detail = details.isNotEmpty
        ? details.first
        : const <String, dynamic>{};
    final attachments = _extractNamedList(response.data, 'attachment');
    final resources = attachments
        .map(
          (item) => _approvalResourceFromItem(
            item,
            idPrefix:
                'approval-detail-${record.trainingApplicationId}-${_stringValue(item['upload_type_id'])}',
          ),
        )
        .whereType<TrainingResource>()
        .toList();

    return record.copyWith(
      title: _stringValue(detail['training_name'], fallback: record.title),
      applicantName: _fullName(
        detail['first_name'],
        detail['middle_name'],
        detail['last_name'],
        fallback: record.applicantName,
      ),
      applicantPhone: _stringValue(
        detail['phone_no'],
        fallback: record.applicantPhone,
      ),
      applicantEmail: _stringValue(
        detail['email'],
        fallback: record.applicantEmail,
      ),
      applicantGender: _stringValue(
        detail['gender'],
        fallback: record.applicantGender,
      ),
      vendorName: _stringValue(
        detail['vendor_name'],
        fallback: record.vendorName,
      ),
      cadreName: _stringValue(detail['cader_name'], fallback: record.cadreName),
      instituteName: _stringValue(
        detail['institute_name'],
        fallback: record.instituteName,
      ),
      educationLevelName: _stringValue(
        detail['education_level_name'],
        fallback: record.educationLevelName,
      ),
      batchYear: _stringValue(detail['batch_year'], fallback: record.batchYear),
      workingStationName: _stringValue(
        detail['working_station_name'],
        fallback: record.workingStationName,
      ),
      rawStatus: _stringValue(
        detail['training_app_status'],
        fallback: record.rawStatus,
      ),
      startDate: record.startDate ?? fallbackProgram?.startDate,
      endDate: record.endDate ?? fallbackProgram?.endDate,
      resources: resources.isNotEmpty ? resources : record.resources,
      isLive: true,
    );
  }

  Future<List<TrainingApprovalRecord>> fetchTrainingRequests({
    List<TrainingProgram> publishedTrainings = const [],
  }) async {
    final response = await _get('/viewTrainingRequestAll');
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return const [];
    }

    final requests = items
        .map(
          (item) => _approvalRecordFromItem(
            item,
            publishedTrainings: publishedTrainings,
            idPrefix: 'request',
          ),
        )
        .toList();

    requests.sort(
      (first, second) => first.applicantName.compareTo(second.applicantName),
    );
    return requests;
  }

  Future<String> submitApprovalAction({
    required TrainingApprovalRecord record,
    required String comment,
  }) async {
    final response = await _postJson(
      '/approveTrainingRequest',
      data: {
        'training_application_id': record.trainingApplicationId,
        'training_app_status_id': record.trainingAppStatusId,
        'app_comment': comment,
      },
    );

    return _extractMessage(
      response.data,
      fallback: 'Training approval action completed successfully.',
    );
  }

  Future<TrainingProgram> applyForTraining({
    required UserModel user,
    required TrainingProgram training,
  }) async {
    final shortCourseDescriptionId = _stringValue(
      training.shortCourseDescriptionId,
    );
    final programId = _stringValue(training.programId);
    if (shortCourseDescriptionId.isNotEmpty &&
        programId.isNotEmpty &&
        user.personalInformationId.trim().isNotEmpty) {
      await _postJson(
        '/storeShortRequest',
        data: {
          'personal_information_id': user.personalInformationId,
          'short_course_descr_id': shortCourseDescriptionId,
          'program_id': programId,
        },
      );

      return buildOptimisticAppliedProgram(training).copyWith(isLive: true);
    }

    final canSubmitLive =
        training.canApplyLive &&
        user.personalInformationId.trim().isNotEmpty &&
        _stringValue(training.developmentPlanVendorId).isNotEmpty &&
        _stringValue(training.instituteId).isNotEmpty &&
        training.startDate != null &&
        training.endDate != null;

    if (!canSubmitLive) {
      return buildOptimisticAppliedProgram(training);
    }

    await _postForm(
      '/storeTrainingRequest',
      data: {
        'personal_information_id': user.personalInformationId,
        'development_plan_vendor_id': training.developmentPlanVendorId,
        'institute_id': training.instituteId,
        'start_date': _toApiDate(training.startDate!),
        'end_date': _toApiDate(training.endDate!),
      },
    );

    return buildOptimisticAppliedProgram(training).copyWith(isLive: true);
  }

  TrainingProgram buildOptimisticAppliedProgram(TrainingProgram training) {
    final now = DateTime.now();
    return training.copyWith(
      status: TrainingParticipationStatus.pending,
      trainingApplicationId:
          training.trainingApplicationId ??
          'local-training-${now.microsecondsSinceEpoch}',
      canApplyLive: false,
    );
  }

  Future<Response<dynamic>> _get(String path) async {
    return _dio.get(path, options: await _authorizedOptions());
  }

  Future<Response<dynamic>> _postJson(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    return _dio.post(path, data: data, options: await _authorizedOptions());
  }

  Future<Response<dynamic>> _postForm(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    return _dio.post(
      path,
      data: FormData.fromMap(data),
      options: await _authorizedOptions(
        extraHeaders: const {'Content-Type': 'multipart/form-data'},
      ),
    );
  }

  Future<Options> _authorizedOptions({
    Map<String, String>? extraHeaders,
  }) async {
    final token = await _authRepository.getToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication token not found. Please sign in again.');
    }

    return Options(
      headers: {'Authorization': 'Bearer $token', ...?extraHeaders},
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      return _extractList(data);
    }
    if (responseData is List) {
      return responseData
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> _extractNamedList(
    dynamic responseData,
    String key,
  ) {
    if (responseData is Map<String, dynamic>) {
      return _extractList(responseData[key]);
    }
    return const [];
  }

  List<String> _resolveTargetCadres(
    Map<String, dynamic> item, {
    required List<String> fallbackCadres,
  }) {
    return _compact([
      _stringValue(item['cader_name']),
      _stringValue(item['education_level_name']),
      ...fallbackCadres,
    ]).take(3).toList();
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  DateTime? _dateValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1';
  }

  int _intValue(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _resolveFileSize(String fileName) {
    if (fileName.trim().isEmpty) return '94 KB';
    final normalized = fileName.toLowerCase();
    if (normalized.endsWith('.pdf')) return '94 KB';
    if (normalized.endsWith('.doc') || normalized.endsWith('.docx')) {
      return '128 KB';
    }
    return '64 KB';
  }

  String _fileTypeFor(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.endsWith('.pdf')) return 'PDF';
    if (normalized.endsWith('.doc') || normalized.endsWith('.docx')) {
      return 'DOC';
    }
    if (normalized.endsWith('.xls') || normalized.endsWith('.xlsx')) {
      return 'XLS';
    }
    return 'FILE';
  }

  String _resolveTrainingFileUrl({
    required String fileName,
    required String filePath,
  }) {
    final normalizedPath = filePath.trim();
    final pathUri = Uri.tryParse(normalizedPath);
    if (pathUri != null && pathUri.hasScheme) {
      return normalizedPath;
    }

    final apiUri = Uri.parse(ApiService.baseUrl);
    final publicBaseUrl = '${apiUri.scheme}://${apiUri.host}';
    if (normalizedPath.isNotEmpty) {
      final relativePath = normalizedPath.replaceFirst(RegExp(r'^/+'), '');
      return '$publicBaseUrl/$relativePath';
    }

    final normalizedFileName = fileName.trim();
    if (normalizedFileName.isEmpty) return '';
    return '$publicBaseUrl/uploads/Employee/TrainingFile/$normalizedFileName';
  }

  TrainingResource? _approvalResourceFromItem(
    Map<String, dynamic> item, {
    required String idPrefix,
  }) {
    final fileName = _stringValue(
      item['upload_file_name'],
      fallback: _stringValue(item['file_name']),
    );
    if (fileName.isEmpty) return null;

    return TrainingResource(
      id: idPrefix,
      title: _stringValue(item['upload_name'], fallback: 'Training Document'),
      sizeLabel: _resolveFileSize(fileName),
      fileName: fileName,
      filePath: _resolveTrainingFileUrl(
        fileName: fileName,
        filePath: _stringValue(
          item['file_url'],
          fallback: _stringValue(item['file_path']),
        ),
      ),
      fileType: _fileTypeFor(fileName),
      isLive: true,
    );
  }

  TrainingApprovalRecord _approvalRecordFromItem(
    Map<String, dynamic> item, {
    required List<TrainingProgram> publishedTrainings,
    required String idPrefix,
  }) {
    final fallbackProgram = _findMatchingPublishedTraining(
      item['training_name'],
      publishedTrainings,
    );
    final resources = <TrainingResource>[];
    final listResource = _approvalResourceFromItem(
      item,
      idPrefix:
          '$idPrefix-list-${_stringValue(item['training_application_id'])}',
    );
    if (listResource != null) {
      resources.add(listResource);
    }

    return TrainingApprovalRecord(
      id: '$idPrefix-${_stringValue(item['training_application_id'])}',
      trainingApplicationId: _stringValue(item['training_application_id']),
      trainingAppStatusId: _stringValue(item['training_app_status_id']),
      title: _stringValue(item['training_name'], fallback: 'Training'),
      applicantName: _fullName(
        item['first_name'],
        item['middle_name'],
        item['last_name'],
      ),
      applicantPhone: _stringValue(item['phone_no']),
      applicantEmail: _stringValue(item['email']),
      applicantGender: _stringValue(item['gender']),
      vendorName: _stringValue(item['vendor_name']),
      cadreName: _stringValue(item['cader_name']),
      instituteName: _stringValue(item['institute_name']),
      educationLevelName: _stringValue(item['education_level_name']),
      batchYear: _stringValue(item['batch_year']),
      workingStationName: _stringValue(item['working_station_name']),
      rawStatus: _stringValue(item['training_app_status']),
      startDate: fallbackProgram?.startDate,
      endDate: fallbackProgram?.endDate,
      resources: resources,
      isLive: true,
    );
  }

  String _fullName(
    dynamic firstName,
    dynamic middleName,
    dynamic lastName, {
    String fallback = 'Staff Member',
  }) {
    final fullName = [
      _stringValue(firstName),
      _stringValue(middleName),
      _stringValue(lastName),
    ].where((value) => value.isNotEmpty).join(' ');
    return fullName.isEmpty ? fallback : fullName;
  }

  TrainingProgram? _findMatchingPublishedTraining(
    dynamic trainingName,
    List<TrainingProgram> publishedTrainings,
  ) {
    final needle = _normalizedKey(trainingName);
    if (needle.isEmpty) return null;

    for (final training in publishedTrainings) {
      if (_normalizedKey(training.title) == needle) {
        return training;
      }
    }
    return null;
  }

  String _normalizedKey(dynamic value) {
    return _stringValue(value).toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _extractMessage(dynamic responseData, {required String fallback}) {
    if (responseData is Map<String, dynamic>) {
      final message = _stringValue(responseData['message']);
      return message.isEmpty ? fallback : message;
    }
    if (responseData is Map) {
      return _extractMessage(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
        fallback: fallback,
      );
    }
    return fallback;
  }

  String _toApiDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  int _sortProgramsByDate(TrainingProgram first, TrainingProgram second) {
    final firstDate = first.startDate ?? first.endDate ?? DateTime(2100);
    final secondDate = second.startDate ?? second.endDate ?? DateTime(2100);
    return firstDate.compareTo(secondDate);
  }

  List<String> _compact(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      result.add(normalized);
    }
    return result;
  }
}
