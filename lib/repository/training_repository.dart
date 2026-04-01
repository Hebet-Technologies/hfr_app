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
      return buildMockLatestTrainings(myTrainings: myTrainings);
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
      final template = _latestTemplates[index % _latestTemplates.length];
      final developmentPlanVendorId = _stringValue(
        item['development_plan_vendor_id'],
      );
      final matchedTraining =
          byDevelopmentPlanVendorId[developmentPlanVendorId];
      final availableSlots = _intValue(
        item['quantity'],
        fallback: template.availableSlots,
      );
      final title = matchedTraining?.title.isNotEmpty == true
          ? matchedTraining!.title
          : template.title;
      final organizer = _stringValue(
        item['vendor_name'],
        fallback: template.organizer,
      );
      final location = matchedTraining?.location.isNotEmpty == true
          ? matchedTraining!.location
          : template.location;
      final educationLevelName = _stringValue(item['education_level_name']);
      final caderName = _stringValue(item['cader_name'], fallback: 'Staff');

      programs.add(
        TrainingProgram(
          id: 'latest-$developmentPlanVendorId-${index + 1}',
          title: title,
          trainingType: _boolValue(item['is_short_course'])
              ? 'Short Course'
              : template.trainingType,
          organizer: organizer,
          location: location,
          description: _buildLatestDescription(
            template: template,
            organizer: organizer,
            caderName: caderName,
          ),
          targetCadres: _resolveTargetCadres(
            item,
            fallbackCadres: template.targetCadres,
          ),
          badge: template.badge,
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

    programs.sort(_sortProgramsByDate);
    return programs;
  }

  Future<List<TrainingProgram>> fetchMyTrainings(UserModel user) async {
    if (user.personalInformationId.trim().isEmpty) {
      return buildMockMyTrainings(user);
    }

    final response = await _postJson(
      '/viewStaffTrainingRequest',
      data: {'personal_information_id': user.personalInformationId},
    );
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return buildMockMyTrainings(user);
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

    programs.sort(_sortProgramsByDate);
    return programs;
  }

  Future<List<TrainingResource>> fetchResources(UserModel user) async {
    if (user.personalInformationId.trim().isEmpty) {
      return buildMockResources();
    }

    final response = await _postJson(
      '/viewStaffTrainingRequestAttachment',
      data: {'personal_information_id': user.personalInformationId},
    );
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return buildMockResources();
    }

    final resources = items.map((item) {
      final fileName = _stringValue(
        item['file_name'],
        fallback: _stringValue(item['upload_file_name']),
      );
      return TrainingResource(
        id: 'resource-${_stringValue(item['training_attachment_id'], fallback: fileName)}',
        title: _stringValue(item['upload_name'], fallback: 'Training Resource'),
        sizeLabel: _resolveFileSize(fileName),
        fileName: fileName.isNotEmpty ? fileName : 'resource.pdf',
        filePath: _stringValue(item['file_path']),
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
            filePath: '',
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

  List<TrainingProgram> buildMockLatestTrainings({
    List<TrainingProgram> myTrainings = const [],
  }) {
    final myByVendor = <String, TrainingProgram>{};
    for (final item in myTrainings) {
      final key = _stringValue(item.developmentPlanVendorId);
      if (key.isNotEmpty) {
        myByVendor[key] = item;
      }
    }

    final programs = <TrainingProgram>[
      TrainingProgram(
        id: 'latest-mock-1001',
        title: 'Maternal Health Capacity Training',
        trainingType: 'Internal Training',
        organizer: 'Ministry of Health Zanzibar',
        location: 'Zanzibar Health Training Institute',
        description:
            'Training focused on strengthening maternal health services, improving monitoring of maternal indicators, and enhancing clinical response in health facilities.',
        targetCadres: const ['Clinical Officers', 'Nurses', 'Medical Officers'],
        badge: 'Internal',
        status:
            myByVendor['1001']?.status ??
            TrainingParticipationStatus.notApplied,
        availableSlots: 25,
        participantCount: 25,
        resources: const [],
        startDate: DateTime(2026, 3, 20),
        endDate: DateTime(2026, 3, 22),
        developmentPlanVendorId: '1001',
        isLive: false,
        canApplyLive: false,
      ),
      TrainingProgram(
        id: 'latest-mock-1002',
        title: 'Leadership in Health Systems',
        trainingType: 'Workshop',
        organizer: 'Leadership Institute Zanzibar',
        location: 'Zanzibar Health Training Institute',
        description:
            'Practical leadership sessions for supervisors and coordinators managing service delivery, planning, and performance reviews across health teams.',
        targetCadres: const [
          'Department Leads',
          'Programme Coordinators',
          'Facility Managers',
        ],
        badge: 'Internal',
        status:
            myByVendor['1002']?.status ??
            TrainingParticipationStatus.notApplied,
        availableSlots: 18,
        participantCount: 18,
        resources: const [],
        startDate: DateTime(2026, 4, 12),
        endDate: DateTime(2026, 4, 14),
        developmentPlanVendorId: '1002',
        isLive: false,
        canApplyLive: false,
      ),
      TrainingProgram(
        id: 'latest-mock-1003',
        title: 'Infection Prevention Workshop',
        trainingType: 'Workshop',
        organizer: 'Public Health Surveillance Unit',
        location: 'Mnazi Mmoja Conference Hall',
        description:
            'Workshop designed to strengthen prevention workflows, reporting discipline, and outbreak preparedness among front-line clinical teams.',
        targetCadres: const [
          'Nurses',
          'Clinical Officers',
          'Public Health Officers',
        ],
        badge: 'Workshop',
        status:
            myByVendor['1003']?.status ??
            TrainingParticipationStatus.notApplied,
        availableSlots: 30,
        participantCount: 30,
        resources: const [],
        startDate: DateTime(2026, 5, 8),
        endDate: DateTime(2026, 5, 9),
        developmentPlanVendorId: '1003',
        isLive: false,
        canApplyLive: false,
      ),
    ];

    programs.sort(_sortProgramsByDate);
    return programs;
  }

  List<TrainingProgram> buildMockMyTrainings(UserModel? user) {
    final workingStation = user?.workingStationName.trim().isNotEmpty == true
        ? user!.workingStationName.trim()
        : 'Ministry of Health Zanzibar';

    final programs = [
      TrainingProgram(
        id: 'my-mock-2001',
        title: 'Maternal Health Capacity Training',
        trainingType: 'Internal Training',
        organizer: 'Ministry of Health Zanzibar',
        location: 'Zanzibar Health Training Institute',
        description:
            'Training request submitted for maternal health strengthening and capacity building.',
        targetCadres: ['Clinical Officers', 'Nurses', workingStation],
        badge: 'Internal',
        status: TrainingParticipationStatus.pending,
        availableSlots: 25,
        participantCount: 25,
        resources: const [],
        startDate: DateTime(2026, 12, 12),
        endDate: DateTime(2026, 12, 14),
        trainingApplicationId: '2001',
        developmentPlanVendorId: '1001',
        instituteId: '501',
        workingStationName: workingStation,
        isLive: false,
        canApplyLive: false,
      ),
      TrainingProgram(
        id: 'my-mock-2002',
        title: 'Infection Prevention Workshop',
        trainingType: 'Workshop',
        organizer: 'Public Health Surveillance Unit',
        location: 'Mnazi Mmoja Hall',
        description:
            'Workshop covering prevention protocols and facility reporting practices.',
        targetCadres: ['Nurses', 'Clinical Officers', workingStation],
        badge: 'Workshop',
        status: TrainingParticipationStatus.completed,
        availableSlots: 24,
        participantCount: 24,
        resources: const [],
        startDate: DateTime(2026, 2, 12),
        endDate: DateTime(2026, 2, 12),
        trainingApplicationId: '2002',
        developmentPlanVendorId: '1003',
        instituteId: '502',
        workingStationName: workingStation,
        isLive: false,
        canApplyLive: false,
      ),
      TrainingProgram(
        id: 'my-mock-2003',
        title: 'Leadership in Health Systems',
        trainingType: 'Workshop',
        organizer: 'Leadership Institute Zanzibar',
        location: 'Zanzibar Health Training Institute',
        description:
            'Leadership programme approved for current supervisors and unit coordinators.',
        targetCadres: ['Department Leads', 'Coordinators', workingStation],
        badge: 'Internal',
        status: TrainingParticipationStatus.approved,
        availableSlots: 18,
        participantCount: 18,
        resources: const [],
        startDate: DateTime(2026, 2, 12),
        endDate: DateTime(2026, 2, 14),
        trainingApplicationId: '2003',
        developmentPlanVendorId: '1002',
        instituteId: '503',
        workingStationName: workingStation,
        isLive: false,
        canApplyLive: false,
      ),
    ];

    programs.sort(_sortProgramsByDate);
    return programs;
  }

  List<TrainingApprovalRecord> buildMockApprovalQueue() {
    return [
      TrainingApprovalRecord(
        id: 'approval-mock-3001',
        trainingApplicationId: '3001',
        trainingAppStatusId: '7001',
        title: 'Maternal Health Capacity Training',
        applicantName: 'Dr. Amina Salim',
        applicantPhone: '0712345678',
        applicantEmail: 'amina.salim@mohz.go.tz',
        applicantGender: 'Female',
        vendorName: 'Ministry of Health Zanzibar',
        cadreName: 'Clinical Officer',
        instituteName: 'Zanzibar Health Training Institute',
        educationLevelName: 'Internal Training',
        batchYear: '2026',
        workingStationName: 'Mnazi Mmoja Hospital',
        rawStatus: 'REQUESTED',
        startDate: DateTime(2026, 4, 10),
        endDate: DateTime(2026, 4, 12),
        resources: const [
          TrainingResource(
            id: 'approval-resource-3001',
            title: 'Training Invitation',
            sizeLabel: '94 KB',
            fileName: 'training_invitation.pdf',
            filePath: '',
            fileType: 'PDF',
          ),
        ],
      ),
      TrainingApprovalRecord(
        id: 'approval-mock-3002',
        trainingApplicationId: '3002',
        trainingAppStatusId: '7002',
        title: 'Infection Prevention Workshop',
        applicantName: 'Dr. Hassan Juma',
        applicantPhone: '0719876543',
        applicantEmail: 'hassan.juma@mohz.go.tz',
        applicantGender: 'Male',
        vendorName: 'Public Health Surveillance Unit',
        cadreName: 'Medical Officer',
        instituteName: 'Ministry of Health HQ',
        educationLevelName: 'Workshop',
        batchYear: '2026',
        workingStationName: 'Pemba Regional Hospital',
        rawStatus: 'FORWARDED',
        startDate: DateTime(2026, 4, 20),
        endDate: DateTime(2026, 4, 22),
      ),
    ];
  }

  List<TrainingResource> buildMockResources() {
    return const [
      TrainingResource(
        id: 'resource-guideline',
        title: 'Infection Prevention Guidelines',
        sizeLabel: '94 KB',
        fileName: 'infection_prevention_guidelines.pdf',
        filePath: '',
        fileType: 'PDF',
      ),
      TrainingResource(
        id: 'resource-maternal-best-practice',
        title: 'Maternal Health Best Practices',
        sizeLabel: '94 KB',
        fileName: 'maternal_health_best_practices.pdf',
        filePath: '',
        fileType: 'PDF',
      ),
      TrainingResource(
        id: 'resource-surveillance-manual',
        title: 'Public Health Surveillance Manual',
        sizeLabel: '94 KB',
        fileName: 'public_health_surveillance_manual.pdf',
        filePath: '',
        fileType: 'PDF',
      ),
      TrainingResource(
        id: 'resource-ipc-manual',
        title: 'Infection Prevention & Control Manual',
        sizeLabel: '94 KB',
        fileName: 'ipc_manual.pdf',
        filePath: '',
        fileType: 'PDF',
      ),
      TrainingResource(
        id: 'resource-malaria',
        title: 'Malaria Case Management Guide',
        sizeLabel: '94 KB',
        fileName: 'malaria_case_management_guide.pdf',
        filePath: '',
        fileType: 'PDF',
      ),
      TrainingResource(
        id: 'resource-health-data',
        title: 'Health Data Reporting Procedures',
        sizeLabel: '94 KB',
        fileName: 'health_data_reporting_procedures.pdf',
        filePath: '',
        fileType: 'PDF',
      ),
      TrainingResource(
        id: 'resource-emergency',
        title: 'Emergency Response Protocols',
        sizeLabel: '94 KB',
        fileName: 'emergency_response_protocols.pdf',
        filePath: '',
        fileType: 'PDF',
      ),
    ];
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

  String _buildLatestDescription({
    required _TrainingTemplate template,
    required String organizer,
    required String caderName,
  }) {
    return '${template.description} Organised with $organizer for $caderName teams.';
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
      filePath: _stringValue(item['file_path']),
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

class _TrainingTemplate {
  const _TrainingTemplate({
    required this.title,
    required this.trainingType,
    required this.organizer,
    required this.location,
    required this.description,
    required this.targetCadres,
    required this.badge,
    required this.availableSlots,
  });

  final String title;
  final String trainingType;
  final String organizer;
  final String location;
  final String description;
  final List<String> targetCadres;
  final String badge;
  final int availableSlots;
}

const _latestTemplates = [
  _TrainingTemplate(
    title: 'Maternal Health Capacity Training',
    trainingType: 'Internal Training',
    organizer: 'Ministry of Health Zanzibar',
    location: 'Zanzibar Health Training Institute',
    description:
        'Training focused on strengthening maternal health services, improving monitoring of maternal indicators, and enhancing clinical response in health facilities.',
    targetCadres: ['Clinical Officers', 'Nurses', 'Medical Officers'],
    badge: 'Internal',
    availableSlots: 25,
  ),
  _TrainingTemplate(
    title: 'Leadership in Health Systems',
    trainingType: 'Workshop',
    organizer: 'Leadership Institute Zanzibar',
    location: 'Zanzibar Health Training Institute',
    description:
        'Practical leadership sessions for supervisors and coordinators managing service delivery, planning, and performance reviews across health teams.',
    targetCadres: [
      'Department Leads',
      'Programme Coordinators',
      'Facility Managers',
    ],
    badge: 'Internal',
    availableSlots: 18,
  ),
  _TrainingTemplate(
    title: 'Infection Prevention Workshop',
    trainingType: 'Workshop',
    organizer: 'Public Health Surveillance Unit',
    location: 'Mnazi Mmoja Conference Hall',
    description:
        'Workshop designed to strengthen prevention workflows, reporting discipline, and outbreak preparedness among front-line clinical teams.',
    targetCadres: ['Nurses', 'Clinical Officers', 'Public Health Officers'],
    badge: 'Workshop',
    availableSlots: 30,
  ),
];
