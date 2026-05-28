import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:staffportal/core/network/api_service.dart';
import 'package:staffportal/features/requests/models/staff_request_models.dart';
import 'package:staffportal/features/training/models/training_models.dart';
import 'package:staffportal/features/auth/models/user_model.dart';
import 'package:staffportal/core/utils/url_resolver.dart';

class TrainingRepository {
  TrainingRepository();

  static const _countriesCacheKey = 'training_countries_cache_v1';
  static const _institutesCachePrefix = 'training_institutes_cache_v1';

  final Dio _dio = createLoggedDio(
    BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: ApiService.defaultConnectTimeout,
      receiveTimeout: ApiService.defaultReceiveTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );
  List<TrainingCountry>? _cachedCountries;
  final Map<String, List<TrainingInstitute>> _cachedInstitutes = {};

  Future<List<TrainingProgram>> fetchLatestTrainings({
    List<TrainingProgram> myTrainings = const [],
  }) async {
    final response = await _get('/getPublishedDevelopmentPlanCurrentYear');
    final items = _extractList(response.data);

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
      final caderName = _stringValue(item['cader_name']);
      final isShortCourse = _boolValue(item['is_short_course']);
      final trainingType = isShortCourse
          ? 'Short Course'
          : _stringValue(item['training_name'], fallback: 'Training');
      final title = matchedTraining?.title.isNotEmpty == true
          ? matchedTraining!.title
          : _compact([trainingType, caderName, educationLevelName]).join(' - ');
      final organizer = _stringValue(item['vendor_name']);
      final location = matchedTraining?.location.isNotEmpty == true
          ? matchedTraining!.location
          : _stringValue(item['institute_name']);

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
          educationLevelId:
              matchedTraining?.educationLevelId?.isNotEmpty == true
              ? matchedTraining!.educationLevelId
              : _stringValue(item['education_level_id']),
          educationLevelName: educationLevelName.isNotEmpty
              ? educationLevelName
              : null,
          workingStationName: matchedTraining?.workingStationName,
          batchYear: _stringValue(item['batch_year']),
          workingExperienceLabel: _stringValue(item['working_expirience']),
          rawStatus: matchedTraining?.rawStatus,
          isLive: true,
          canApplyLive:
              matchedTraining == null &&
              developmentPlanVendorId.isNotEmpty &&
              _dateValue(item['start_date']) != null &&
              _dateValue(item['end_date']) != null,
        ),
      );
    }

    try {
      final shortCourses = await fetchShortCoursePlans(
        myTrainings: myTrainings,
      );
      programs.addAll(shortCourses);
    } catch (_) {
      // Keep published trainings visible even if short-course plans fail.
    }

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
      final title = _stringValue(item['program_name']);
      final venue = _stringValue(item['venue_place']);

      return TrainingProgram(
        id: 'short-course-$shortCourseId',
        title: title,
        trainingType: 'Short Course',
        organizer: _stringValue(item['vendor_name']),
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
        availableSlots: _intValue(item['quantity']),
        participantCount: matchedTraining?.participantCount ?? 0,
        resources: matchedTraining?.resources ?? const [],
        startDate: startDate,
        endDate: endDate,
        trainingApplicationId: matchedTraining?.trainingApplicationId,
        shortCourseDescriptionId: shortCourseId,
        programId: programId,
        workingStationName: matchedTraining?.workingStationName,
        rawStatus: matchedTraining?.rawStatus,
        isLive: true,
        canApplyLive:
            matchedTraining == null &&
            shortCourseId.isNotEmpty &&
            programId.isNotEmpty &&
            startDate != null &&
            endDate != null,
      );
    }).toList();
  }

  Future<List<TrainingProgram>> fetchMyTrainingApplications(
    UserModel user,
  ) async {
    if (user.personalInformationId.trim().isEmpty) {
      return const [];
    }

    final response = await _postJson(
      '/viewStaffTrainingRequest',
      data: {'personal_information_id': user.personalInformationId},
    );
    final items = _extractList(response.data);

    final programs = items.map((item) {
      final rawStatus = _stringValue(item['training_app_status']);
      final attachmentItems = _extractList(item['attachments']);
      final resources = attachmentItems
          .map(
            (attachment) => _approvalResourceFromItem(
              attachment,
              idPrefix:
                  'my-attachment-${_stringValue(item['training_application_id'])}-${_stringValue(attachment['upload_type_id'], fallback: _stringValue(attachment['upload_file_name']))}',
            ),
          )
          .whereType<TrainingResource>()
          .toList();

      return TrainingProgram(
        id: 'my-${_stringValue(item['training_application_id'])}',
        title: _stringValue(item['training_name']),
        trainingType: _stringValue(item['education_level_name']),
        organizer: _stringValue(item['vendor_name']),
        location: _stringValue(item['institute_name']),
        description:
            'Training application submitted through the staff portal and awaiting the next workflow action.',
        targetCadres: _compact([
          _stringValue(item['cader_name']),
          _stringValue(item['education_level_name']),
          user.workingStationName,
        ]),
        badge: 'Internal',
        status: TrainingParticipationStatusX.fromRaw(rawStatus),
        availableSlots: 25,
        participantCount: 25,
        resources: resources,
        startDate: _dateValue(item['start_date']),
        endDate: _dateValue(item['end_date']),
        trainingApplicationId: _stringValue(item['training_application_id']),
        developmentPlanVendorId: _stringValue(
          item['development_plan_vendor_id'],
        ),
        instituteId: _stringValue(item['institute_id']),
        educationLevelId: _stringValue(item['education_level_id']),
        educationLevelName: _stringValue(item['education_level_name']),
        workingStationName: user.workingStationName,
        batchYear: _stringValue(item['batch_year']),
        rawStatus: rawStatus,
        isLive: true,
        canApplyLive: false,
      );
    }).toList();

    try {
      programs.addAll(await fetchMyShortCourseRequests(user));
    } catch (_) {
      // Keep training requests visible even if short-course requests fail.
    }

    programs.sort(_sortProgramsByDate);
    return programs;
  }

  Future<List<TrainingProgram>> fetchMyTrainings(UserModel user) async {
    if (user.personalInformationId.trim().isEmpty) {
      return const [];
    }

    final response = await _postJson(
      '/getTrainingStudentIndividual',
      data: {'personal_information_id': user.personalInformationId},
    );
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return const [];
    }

    final programs = items
        .map(
          (item) => TrainingProgram(
            id: 'student-${_stringValue(item['training_student_id'])}',
            title: _compact([
              _stringValue(item['cader_name']),
              _stringValue(item['education_level_name']),
            ]).join(' - '),
            trainingType: _stringValue(item['education_level_name']),
            organizer: _stringValue(item['vendor_name']),
            location: _stringValue(item['institute_name']),
            description:
                'Training history record from the active batch year for an admitted training participant.',
            targetCadres: _compact([
              _stringValue(item['cader_name']),
              _stringValue(item['education_level_name']),
              user.workingStationName,
            ]),
            badge: 'History',
            status: TrainingParticipationStatus.approved,
            availableSlots: 0,
            participantCount: 1,
            resources: const [],
            batchYear: _stringValue(item['batch_year']),
            educationLevelName: _stringValue(item['education_level_name']),
            workingStationName: user.workingStationName,
            rawStatus: 'APPROVED',
            isLive: true,
            canApplyLive: false,
          ),
        )
        .toList();

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
      final rawStatus = _stringValue(item['short_course_status']);

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
        status: TrainingParticipationStatusX.fromRaw(rawStatus),
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
        rawStatus: rawStatus,
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

  Future<List<TrainingCountry>> fetchTrainingCountries({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _readCachedCountries();
      if (cached != null && cached.isNotEmpty) return cached;
    }

    final response = await _get('/getCountries');
    final countries = _parseTrainingCountries(_extractList(response.data));
    await _writeCachedCountries(countries);
    return countries;
  }

  Future<List<TrainingInstitute>> fetchInstitutes({
    required String countryCode,
    required String educationLevelId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _institutesCacheKey(
      countryCode: countryCode,
      educationLevelId: educationLevelId,
    );
    if (!forceRefresh) {
      final cached = await _readCachedInstitutes(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    final response = await _get(
      '/getInstitutes/$countryCode/$educationLevelId',
    );
    final institutes = _parseTrainingInstitutes(_extractList(response.data));
    await _writeCachedInstitutes(cacheKey, institutes);
    return institutes;
  }

  Future<List<TrainingCountry>?> _readCachedCountries() async {
    final memoryCache = _cachedCountries;
    if (memoryCache != null && memoryCache.isNotEmpty) return memoryCache;

    try {
      final prefs = await SharedPreferences.getInstance();
      final countries = _parseTrainingCountries(
        _decodeCachedList(prefs.getString(_countriesCacheKey)),
      );
      if (countries.isEmpty) return null;
      _cachedCountries = countries;
      return countries;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedCountries(List<TrainingCountry> countries) async {
    if (countries.isEmpty) return;
    _cachedCountries = List<TrainingCountry>.unmodifiable(countries);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _countriesCacheKey,
        jsonEncode(
          countries
              .map((item) => {'code': item.code, 'name': item.name})
              .toList(),
        ),
      );
    } catch (_) {
      // Cache writes are best effort; fresh API data should still render.
    }
  }

  Future<List<TrainingInstitute>?> _readCachedInstitutes(String key) async {
    final memoryCache = _cachedInstitutes[key];
    if (memoryCache != null && memoryCache.isNotEmpty) return memoryCache;

    try {
      final prefs = await SharedPreferences.getInstance();
      final institutes = _parseTrainingInstitutes(
        _decodeCachedList(prefs.getString(key)),
      );
      if (institutes.isEmpty) return null;
      _cachedInstitutes[key] = institutes;
      return institutes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedInstitutes(
    String key,
    List<TrainingInstitute> institutes,
  ) async {
    if (institutes.isEmpty) return;
    _cachedInstitutes[key] = List<TrainingInstitute>.unmodifiable(institutes);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode(
          institutes
              .map(
                (item) => {
                  'id': item.id,
                  'name': item.name,
                  'countryName': item.countryName,
                },
              )
              .toList(),
        ),
      );
    } catch (_) {
      // Cache writes are best effort; fresh API data should still render.
    }
  }

  List<TrainingCountry> _parseTrainingCountries(
    List<Map<String, dynamic>> items,
  ) {
    return items
        .map(
          (item) => TrainingCountry(
            code: _stringValue(
              item['country_code'],
              fallback: _stringValue(item['code']),
            ),
            name: _stringValue(
              item['country_name'],
              fallback: _stringValue(item['name']),
            ),
          ),
        )
        .where((item) => item.code.isNotEmpty && item.name.isNotEmpty)
        .toList()
      ..sort((first, second) => first.name.compareTo(second.name));
  }

  List<TrainingInstitute> _parseTrainingInstitutes(
    List<Map<String, dynamic>> items,
  ) {
    return items
        .map(
          (item) => TrainingInstitute(
            id: _stringValue(
              item['institute_id'],
              fallback: _stringValue(item['id']),
            ),
            name: _stringValue(
              item['institute_name'],
              fallback: _stringValue(item['name']),
            ),
            countryName: _stringValue(
              item['country_name'],
              fallback: _stringValue(item['countryName']),
            ),
          ),
        )
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList()
      ..sort((first, second) => first.name.compareTo(second.name));
  }

  List<Map<String, dynamic>> _decodeCachedList(String? encoded) {
    if (encoded == null || encoded.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String _institutesCacheKey({
    required String countryCode,
    required String educationLevelId,
  }) {
    final country = _cacheKeyPart(countryCode);
    final education = _cacheKeyPart(educationLevelId);
    return '$_institutesCachePrefix.$country.$education';
  }

  String _cacheKeyPart(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
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

    final detail = _extractDataMap(response.data);
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
      rawStatus: _stringValue(
        detail['training_app_status'],
        fallback: _stringValue(training.rawStatus),
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

    final detail = _extractDataMap(response.data);
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
    required String action,
  }) async {
    final response = await _postJson(
      '/approveTrainingRequest',
      data: {
        'training_application_id': record.trainingApplicationId,
        'training_app_status_id': record.trainingAppStatusId,
        'app_comment': comment,
        'action': action,
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
    String? admissionLetterPath,
    String? admissionLetterName,
  }) async {
    final shortCourseDescriptionId = _stringValue(
      training.shortCourseDescriptionId,
    );
    final programId = _stringValue(training.programId);
    if (shortCourseDescriptionId.isNotEmpty &&
        programId.isNotEmpty &&
        user.personalInformationId.trim().isNotEmpty) {
      final response = await _postJson(
        '/storeShortRequest',
        data: {
          'personal_information_id': user.personalInformationId,
          'short_course_descr_id': shortCourseDescriptionId,
          'program_id': programId,
        },
      );
      _ensureSuccessfulResponse(
        response,
        fallback: 'Short course request could not be submitted.',
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
      if (training.isLive) {
        throw Exception('Training request details are incomplete.');
      }
      return buildOptimisticAppliedProgram(training);
    }

    if (_requiresAdmissionLetter(training) &&
        (admissionLetterPath ?? '').trim().isEmpty) {
      throw Exception(
        'Admission letter is required for short course training.',
      );
    }

    final payload = <String, dynamic>{
      'personal_information_id': user.personalInformationId,
      'development_plan_vendor_id': training.developmentPlanVendorId,
      'institute_id': training.instituteId,
      'start_date': _toApiDate(training.startDate!),
      'end_date': _toApiDate(training.endDate!),
    };
    if ((admissionLetterPath ?? '').trim().isNotEmpty) {
      payload['admission_letter'] = await MultipartFile.fromFile(
        admissionLetterPath!,
        filename: admissionLetterName,
      );
    }

    final response = await _postForm('/storeTrainingRequest', data: payload);
    _ensureSuccessfulResponse(
      response,
      fallback: 'Training request could not be submitted.',
    );

    return buildOptimisticAppliedProgram(training).copyWith(isLive: true);
  }

  Future<String> deleteTrainingRequest(TrainingProgram training) async {
    final trainingApplicationId = training.trainingApplicationId?.trim() ?? '';
    if (trainingApplicationId.isEmpty ||
        trainingApplicationId.startsWith('local-training-')) {
      throw Exception('Training application details are incomplete.');
    }

    final response = await _delete(
      '/destroyStaffTrainingRequest/$trainingApplicationId',
    );
    _ensureSuccessfulResponse(
      response,
      fallback: 'Training application could not be deleted.',
    );
    return _extractMessage(
      response.data,
      fallback: 'Training application deleted successfully.',
    );
  }

  Future<String> updateTrainingRequest({
    required UserModel user,
    required TrainingProgram training,
    required DateTime startDate,
    required DateTime endDate,
    String? admissionLetterPath,
    String? admissionLetterName,
  }) async {
    final trainingApplicationId = training.trainingApplicationId?.trim() ?? '';
    if (trainingApplicationId.isEmpty) {
      throw Exception('Training application details are incomplete.');
    }
    if (user.personalInformationId.trim().isEmpty) {
      throw Exception('Your employee profile is not linked to this session.');
    }

    final payload = <String, dynamic>{
      'training_application_id': trainingApplicationId,
      'personal_information_id': user.personalInformationId,
      'development_plan_vendor_id': training.developmentPlanVendorId,
      'institute_id': training.instituteId,
      'start_date': _toApiDate(startDate),
      'end_date': _toApiDate(endDate),
    };
    if ((admissionLetterPath ?? '').trim().isNotEmpty) {
      payload['admission_letter'] = await MultipartFile.fromFile(
        admissionLetterPath!,
        filename: admissionLetterName,
      );
    }

    final response = await _postForm('/updateTrainingRequest', data: payload);
    _ensureSuccessfulResponse(
      response,
      fallback: 'Training application could not be updated.',
    );
    return _extractMessage(
      response.data,
      fallback: 'Training application updated successfully.',
    );
  }

  Future<String> uploadTrainingContract({
    required TrainingProgram training,
    required String filePath,
    required String fileName,
  }) async {
    final trainingApplicationId = training.trainingApplicationId?.trim() ?? '';
    if (trainingApplicationId.isEmpty) {
      throw Exception('Training application details are incomplete.');
    }
    final response = await _postForm(
      '/storeTrainingContract',
      data: {
        'training_application_id': trainingApplicationId,
        'trining_contract': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      },
    );
    _ensureSuccessfulResponse(
      response,
      fallback: 'Training contract could not be uploaded.',
    );
    return _extractMessage(
      response.data,
      fallback: 'Training contract uploaded successfully.',
    );
  }

  Future<String> uploadTrainingResult({
    required String trainingStudentResultId,
    required String filePath,
    required String fileName,
  }) async {
    if (trainingStudentResultId.trim().isEmpty) {
      throw Exception('Training result ID is required.');
    }
    final response = await _postForm(
      '/updateTrainingResult',
      data: {
        'training_student_result_id': trainingStudentResultId.trim(),
        'training_result': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      },
    );
    _ensureSuccessfulResponse(
      response,
      fallback: 'Training result could not be uploaded.',
    );
    return _extractMessage(
      response.data,
      fallback: 'Training result uploaded successfully.',
    );
  }

  Future<String> generateTrainingContract({
    required TrainingProgram training,
    required String refereeId,
    required String directorId,
    required String costTypeId,
    required String costAmount,
    required String unit,
  }) async {
    final trainingApplicationId = training.trainingApplicationId?.trim() ?? '';
    if (trainingApplicationId.isEmpty) {
      throw Exception('Training application details are incomplete.');
    }
    final response = await _postJson(
      '/downloadTrainingContract',
      data: {
        'training_application_id': trainingApplicationId,
        'refferee_id': refereeId,
        'director_id': directorId,
        'study_cost': [
          {'cost_type_id': costTypeId, 'cost_amount': costAmount, 'unit': unit},
        ],
      },
    );
    _ensureSuccessfulResponse(
      response,
      fallback: 'Training contract could not be generated.',
    );
    return _extractMessage(
      response.data,
      fallback: 'Training contract generated successfully.',
    );
  }

  Future<List<RequestLookupOption>> fetchTrainingReferees(
    UserModel user,
  ) async {
    if (user.personalInformationId.trim().isEmpty) return const [];
    final response = await _get(
      '/personalRefferees/${user.personalInformationId}',
    );
    return _extractList(response.data)
        .map((item) {
          final name = _compact([
            _stringValue(item['first_name']),
            _stringValue(item['middle_name']),
            _stringValue(item['last_name']),
          ]).join(' ');
          return RequestLookupOption(
            id: _stringValue(item['refferee_id']),
            label: name.isEmpty ? 'Referee' : name,
            subtitle: _stringValue(item['refferee_position']),
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<RequestLookupOption>> fetchTrainingDirectors() async {
    final response = await _get('/getHeadOfDepartment');
    return _extractList(response.data)
        .map((item) {
          final name = _compact([
            _stringValue(item['first_name']),
            _stringValue(item['middle_name']),
            _stringValue(item['last_name']),
          ]).join(' ');
          return RequestLookupOption(
            id: _stringValue(item['personal_information_id']),
            label: name.isEmpty ? 'Director' : name,
            subtitle: _stringValue(item['working_station_name']),
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<RequestLookupOption>> fetchTrainingCostTypes() async {
    final response = await _get('/costTypes');
    return _extractList(response.data)
        .map((item) {
          return RequestLookupOption(
            id: _stringValue(item['cost_type_id']),
            label: _stringValue(
              item['cost_name'],
              fallback: _stringValue(item['cost_type_name'], fallback: 'Cost'),
            ),
            subtitle: _stringValue(item['unit']),
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<RequestLookupOption>> fetchTrainingResultOptions(
    UserModel user,
  ) async {
    if (user.personalInformationId.trim().isEmpty) return const [];
    final response = await _postJson(
      '/getStudentTrainingResult',
      data: {'personal_information_id': user.personalInformationId},
    );
    return _extractList(response.data)
        .map((item) {
          final id = _stringValue(item['training_student_result_id']);
          return RequestLookupOption(
            id: id,
            label: _stringValue(
              item['training_name'],
              fallback: _stringValue(
                item['upload_name'],
                fallback: 'Training Result $id',
              ),
            ),
            subtitle: _stringValue(item['result_year']),
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  String trainingLetterUrl(TrainingProgram training) {
    final trainingApplicationId = training.trainingApplicationId?.trim() ?? '';
    return '${ApiService.baseUrl}/getTrainingLetter/$trainingApplicationId';
  }

  TrainingProgram buildOptimisticAppliedProgram(TrainingProgram training) {
    final now = DateTime.now();
    return training.copyWith(
      status: TrainingParticipationStatus.pending,
      trainingApplicationId:
          training.trainingApplicationId ??
          'local-training-${now.microsecondsSinceEpoch}',
      rawStatus: training.rawStatus ?? 'REQUESTED',
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

  Future<Response<dynamic>> _delete(String path) async {
    return _dio.delete(path, options: await _authorizedOptions());
  }

  Future<Options> _authorizedOptions({
    Map<String, String>? extraHeaders,
  }) async {
    return requireAuth(headers: extraHeaders);
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

  Map<String, dynamic> _extractDataMap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }
      final list = _extractList(data);
      return list.isEmpty ? const <String, dynamic>{} : list.first;
    }
    if (responseData is Map) {
      return _extractDataMap(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return const <String, dynamic>{};
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

    if (normalizedPath.isNotEmpty) {
      return resolveApiFileUrl(normalizedPath);
    }

    final normalizedFileName = fileName.trim();
    if (normalizedFileName.isEmpty) return '';
    return resolveApiFileUrl(
      'uploads/Employee/TrainingFile/$normalizedFileName',
    );
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
    final validationMessage = _validationMessage(responseData);
    if (validationMessage.isNotEmpty) {
      return validationMessage;
    }

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

  String _validationMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      for (final entry in responseData.entries) {
        if (entry.key == 'data' || entry.key == 'message') continue;
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return _stringValue(value.first);
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    if (responseData is Map) {
      return _validationMessage(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return '';
  }

  void _ensureSuccessfulResponse(
    Response<dynamic> response, {
    required String fallback,
  }) {
    final httpStatus = response.statusCode;
    if (httpStatus != null && (httpStatus < 200 || httpStatus >= 300)) {
      throw Exception(_extractMessage(response.data, fallback: fallback));
    }

    final statusCode = _extractStatusCode(response.data);
    final validationMessage = _validationMessage(response.data);
    if (statusCode == null && validationMessage.isNotEmpty) {
      throw Exception(validationMessage);
    }
    if (statusCode == null || statusCode == 200 || statusCode == 201) return;

    throw Exception(_extractMessage(response.data, fallback: fallback));
  }

  int? _extractStatusCode(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final value = responseData['statusCode'];
      if (value is int) return value;
      return int.tryParse(value?.toString().trim() ?? '');
    }
    if (responseData is Map) {
      return _extractStatusCode(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  String _toApiDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  int _sortProgramsByDate(TrainingProgram first, TrainingProgram second) {
    final firstDate = first.startDate ?? first.endDate ?? DateTime(2100);
    final secondDate = second.startDate ?? second.endDate ?? DateTime(2100);
    return firstDate.compareTo(secondDate);
  }

  bool _requiresAdmissionLetter(TrainingProgram training) {
    final type = training.trainingType.trim().toLowerCase();
    return type == 'short course' &&
        _stringValue(training.shortCourseDescriptionId).isEmpty &&
        _stringValue(training.developmentPlanVendorId).isNotEmpty;
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
