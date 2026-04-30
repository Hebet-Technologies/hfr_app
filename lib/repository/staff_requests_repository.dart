import 'dart:developer';

import 'package:dio/dio.dart';

import '../data/network/api_service.dart';
import '../model/staff_request_models.dart';
import '../model/user_model.dart';
import 'auth_repository.dart';

class StaffRequestsRepository {
  StaffRequestsRepository(this._authRepository);

  final AuthRepository _authRepository;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );

  Future<List<StaffRequestRecord>> fetchLeaveRequests(UserModel user) async {
    final response = await _get('/viewStaffLeaveRequests');
    final items = _extractList(response.data);

    return items
        .map(
          (item) => StaffRequestRecord(
            id: 'leave-${_stringValue(item['leave_request_id'])}',
            type: StaffRequestType.leave,
            title:
                '${_stringValue(item['leave_type'], fallback: 'Leave')} Request',
            summary: [
              _stringValue(item['working_station_name']),
              _stringValue(item['department_name']),
            ].where((value) => value.isNotEmpty).join(' • '),
            status: _statusFromApi(item['status']),
            submittedAt:
                _dateValue(
                  item['created_at'],
                  fallback: _dateValue(item['proposed_start_date']),
                ) ??
                DateTime.now(),
            referenceNumber:
                'LV-${_stringValue(item['leave_request_id']).padLeft(5, '0')}',
            startDate: _dateValue(item['proposed_start_date']),
            endDate: _dateValue(item['proposed_end_date']),
            attachmentName: _stringValue(item['upload_file_name']),
            stageLabel: _stringValue(item['leave_path_name']),
            isLive: true,
            detailFields: [
              RequestDetailField(
                label: 'Leave Type',
                value: _stringValue(item['leave_type'], fallback: 'Leave'),
              ),
              RequestDetailField(
                label: 'Facility',
                value: _stringValue(
                  item['working_station_name'],
                  fallback: user.workingStationName,
                ),
              ),
              RequestDetailField(
                label: 'Department',
                value: _stringValue(item['department_name'], fallback: 'N/A'),
              ),
              RequestDetailField(
                label: 'Post Category',
                value: _stringValue(
                  item['post_category_name'],
                  fallback: 'General',
                ),
              ),
              RequestDetailField(
                label: 'Approval Stage',
                value: _stringValue(item['leave_path_name'], fallback: 'Open'),
              ),
              RequestDetailField(
                label: 'Status',
                value: _statusFromApi(item['status']).label,
                status: _statusFromApi(item['status']),
              ),
            ],
          ),
        )
        .toList();
  }

  Future<List<StaffRequestRecord>> fetchTransferRequests(UserModel user) async {
    final response = await _get('/viewStaffTransferSequence');
    final items = _extractTransferSequenceList(response.data);

    return items.map((item) {
      final transferFrom = _stringValue(
        item['transfer_from'],
        fallback: user.workingStationName,
      );
      final transferTo = _stringValue(
        item['transfer_to'],
        fallback: _stringValue(item['working_station_name']),
      );
      final fromDepartment = _stringValue(item['from_department']);
      final toDepartment = _stringValue(
        item['to_department'],
        fallback: _stringValue(item['department_name']),
      );
      final summary = [
        transferFrom,
        transferTo,
      ].where((value) => value.isNotEmpty).join(' → ');

      return StaffRequestRecord(
        id: 'transfer-${_stringValue(item['transfer_request_id'])}',
        type: StaffRequestType.transfer,
        title:
            '${_stringValue(item['transfer_reason_name'], fallback: 'Transfer')} Request',
        summary: summary.isEmpty
            ? _stringValue(
                item['transfer_reason_name'],
                fallback: 'Transfer request',
              )
            : summary,
        status: _statusFromApi(item['status']),
        submittedAt:
            _dateValue(
              item['created_at'],
              fallback: _dateValue(item['preferred_transfer_date']),
            ) ??
            DateTime.now(),
        referenceNumber:
            'TR-${_stringValue(item['transfer_request_id']).padLeft(5, '0')}',
        location: transferTo,
        attachmentName: _stringValue(item['upload_file_name']),
        stageLabel: _stringValue(item['transfer_path_name']),
        isLive: true,
        detailFields: [
          RequestDetailField(
            label: 'Reason',
            value: _stringValue(
              item['transfer_reason_name'],
              fallback: 'Transfer request',
            ),
          ),
          RequestDetailField(
            label: 'From',
            value: transferFrom.isEmpty ? 'N/A' : transferFrom,
          ),
          RequestDetailField(
            label: 'From Department',
            value: fromDepartment.isEmpty ? 'N/A' : fromDepartment,
          ),
          RequestDetailField(
            label: 'To',
            value: transferTo.isEmpty ? 'N/A' : transferTo,
          ),
          RequestDetailField(
            label: 'To Department',
            value: toDepartment.isEmpty ? 'N/A' : toDepartment,
          ),
          RequestDetailField(
            label: 'Cadre',
            value: _stringValue(
              item['post_category_name'],
              fallback: 'General',
            ),
          ),
          RequestDetailField(
            label: 'Transfer Notes',
            value: _stringValue(item['request_from'], fallback: 'Not provided'),
          ),
          RequestDetailField(
            label: 'Preferred Transfer Date',
            value: _displayOptionalDate(
              _dateValue(item['preferred_transfer_date']),
            ),
          ),
          RequestDetailField(
            label: 'Status',
            value: _statusFromApi(item['status']).label,
            status: _statusFromApi(item['status']),
          ),
        ],
      );
    }).toList();
  }

  Future<List<StaffRequestRecord>> fetchLoanRequests(UserModel user) async {
    final queryParameters = <String, dynamic>{'perPage': 50};
    final userId = int.tryParse(user.userId);
    if (userId != null) {
      queryParameters['loanee_id'] = userId;
    }
    log(queryParameters.toString());
    final response = await _dio.get(
      '/loans',
      queryParameters: queryParameters,
      options: await _authorizedOptions(),
    );
    log(response.data.toString());
    final items = _extractListByKey(response.data, 'loans');

    return items.map(_loanRecordFromApi).toList();
  }

  Future<List<StaffRequestRecord>> fetchSickSheets(UserModel user) async {
    final response = await _dio.get(
      '/sick-sheets',
      queryParameters: const {'perPage': 50},
      options: await _authorizedOptions(),
    );
    final items = _extractListByKey(response.data, 'sick_sheets');

    return items.map(_sickSheetRecordFromApi).toList();
  }

  Future<List<ApprovalTask>> fetchLeaveApprovalTasks() async {
    final response = await _get('/viewLeaveToApprove');
    final items = _extractList(response.data);

    return items
        .map(
          (item) => ApprovalTask(
            id: 'leave-approval-${_stringValue(item['leave_request_id'])}',
            requestId: _stringValue(item['leave_request_id']),
            type: ApproverRequestType.leave,
            title:
                '${_stringValue(item['leave_type'], fallback: 'Leave')} Approval',
            subjectName: _buildFullName(
              firstName: item['first_name'],
              middleName: item['middle_name'],
              lastName: item['last_name'],
              surName: item['sur_name'],
            ),
            summary: [
              _stringValue(item['working_station_name']),
              _stringValue(item['department_name']),
            ].where((value) => value.isNotEmpty).join(' • '),
            status: StaffRequestStatus.pending,
            submittedAt:
                _dateValue(
                  item['requested_date'],
                  fallback: _dateValue(item['proposed_start_date']),
                ) ??
                DateTime.now(),
            referenceNumber:
                'LV-${_stringValue(item['leave_request_id']).padLeft(5, '0')}',
            attachmentName: _stringValue(item['upload_file_name']),
            personalInformationId: _stringValue(
              item['personal_information_id'],
            ),
            proposedStartDate: _dateValue(item['proposed_start_date']),
            proposedEndDate: _dateValue(item['proposed_end_date']),
            detailFields: [
              RequestDetailField(
                label: 'Leave Type',
                value: _stringValue(item['leave_type'], fallback: 'Leave'),
              ),
              RequestDetailField(
                label: 'Facility',
                value: _stringValue(
                  item['working_station_name'],
                  fallback: 'N/A',
                ),
              ),
              RequestDetailField(
                label: 'Department',
                value: _stringValue(item['department_name'], fallback: 'N/A'),
              ),
              RequestDetailField(
                label: 'Position',
                value: _stringValue(
                  item['post_category_name'],
                  fallback: 'N/A',
                ),
              ),
              RequestDetailField(
                label: 'Phone',
                value: _stringValue(item['phone_number'], fallback: 'N/A'),
              ),
            ],
          ),
        )
        .toList();
  }

  Future<ApprovalTask> fetchLeaveApprovalDetail(
    String personalInformationId,
  ) async {
    final response = await _get('/viewLeaveHistory/$personalInformationId');
    final current = _extractMap(response.data, 'current');
    if (current.isEmpty) {
      throw Exception('Leave approval details are unavailable.');
    }

    final comments = _extractListByKey(response.data, 'comments')
        .map(
          (item) => ApprovalCommentRecord(
            stage: _stringValue(item['leave_path_name'], fallback: 'Workflow'),
            comment: _stringValue(item['comment'], fallback: 'No comment'),
            reason: _stringValue(item['leave_reason_name']),
            additionalComment: _stringValue(item['additional_comment']),
          ),
        )
        .toList();

    return ApprovalTask(
      id: 'leave-approval-${_stringValue(current['leave_request_id'])}',
      requestId: _stringValue(current['leave_request_id']),
      type: ApproverRequestType.leave,
      title:
          '${_stringValue(current['leave_type'], fallback: 'Leave')} Approval',
      subjectName: _buildFullName(
        firstName: current['first_name'],
        middleName: current['middle_name'],
        lastName: current['last_name'],
        surName: current['sur_name'],
      ),
      summary: [
        _stringValue(current['working_station_name']),
        _stringValue(current['department_name']),
      ].where((value) => value.isNotEmpty).join(' • '),
      status: _statusFromApi(current['status']),
      submittedAt:
          _dateValue(
            current['proposed_start_date'],
            fallback: _dateValue(current['start_date']),
          ) ??
          DateTime.now(),
      referenceNumber:
          'LV-${_stringValue(current['leave_request_id']).padLeft(5, '0')}',
      attachmentName: _stringValue(current['upload_file_name']),
      personalInformationId: _stringValue(current['personal_information_id']),
      employmentStatusId: _stringValue(current['employement_status_id']),
      numberOfDays: _intValue(current['number_of_days']),
      parentStageId: _stringValue(current['parent_id']),
      rawStatus: _stringValue(current['status']),
      proposedStartDate: _dateValue(current['proposed_start_date']),
      proposedEndDate: _dateValue(current['proposed_end_date']),
      startDate: _dateValue(current['start_date']),
      endDate: _dateValue(current['end_date']),
      detailFields: [
        RequestDetailField(
          label: 'Leave Type',
          value: _stringValue(current['leave_type'], fallback: 'Leave'),
        ),
        RequestDetailField(
          label: 'Facility',
          value: _stringValue(current['working_station_name'], fallback: 'N/A'),
        ),
        RequestDetailField(
          label: 'Department',
          value: _stringValue(current['department_name'], fallback: 'N/A'),
        ),
        RequestDetailField(
          label: 'Position',
          value: _stringValue(current['post_category_name'], fallback: 'N/A'),
        ),
        RequestDetailField(
          label: 'Phone',
          value: _stringValue(current['phone_no'], fallback: 'N/A'),
        ),
        RequestDetailField(
          label: 'Requested Start',
          value: _displayOptionalDate(
            _dateValue(current['proposed_start_date']),
          ),
        ),
        RequestDetailField(
          label: 'Requested End',
          value: _displayOptionalDate(_dateValue(current['proposed_end_date'])),
        ),
        RequestDetailField(
          label: 'Workflow Status',
          value: _stringValue(current['status'], fallback: 'Requested'),
        ),
      ],
      commentHistory: comments,
    );
  }

  Future<String> handleLeaveApproval({
    required ApprovalTask task,
    required ApproverAction action,
    required String comment,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    late Response<dynamic> response;

    switch (action) {
      case ApproverAction.forward:
        response = await _postJson(
          '/leaveForward',
          data: {'leave_request_id': task.requestId, 'comment': comment},
        );
      case ApproverAction.deny:
        response = await _postJson(
          '/denyLeave',
          data: {'leave_request_id': task.requestId, 'comment': comment},
        );
      case ApproverAction.approve:
        final resolvedStartDate =
            startDate ?? task.startDate ?? task.proposedStartDate;
        final resolvedEndDate = endDate ?? task.endDate ?? task.proposedEndDate;
        if (resolvedStartDate == null || resolvedEndDate == null) {
          throw Exception('Choose approved leave dates before continuing.');
        }

        final personalInformationId = task.personalInformationId?.trim() ?? '';
        final employmentStatusId = task.employmentStatusId?.trim() ?? '';
        if (personalInformationId.isEmpty || employmentStatusId.isEmpty) {
          throw Exception('Leave approval details are incomplete.');
        }

        final days =
            task.numberOfDays ??
            resolvedEndDate.difference(resolvedStartDate).inDays + 1;

        response = await _postJson(
          '/approveLeave',
          data: {
            'leave_request_id': task.requestId,
            'personal_information_id': personalInformationId,
            'employement_status_id': employmentStatusId,
            'number_of_days': '$days',
            'comment': comment,
            'start_date': _toSlashDate(resolvedStartDate),
            'end_date': _toSlashDate(resolvedEndDate),
          },
        );
    }

    _ensureSuccessfulResponse(
      response,
      fallback: 'Leave approval action failed.',
    );

    return _extractMessage(
      response.data,
      fallback: '${action.label} action completed.',
    );
  }

  Future<List<ApprovalTask>> fetchTransferApprovalTasks() async {
    final response = await _get('/viewStaffTransferToApprove');
    final items = _extractList(response.data);

    return items
        .map(
          (item) => ApprovalTask(
            id: 'transfer-approval-${_stringValue(item['transfer_request_id'])}',
            requestId: _stringValue(item['transfer_request_id']),
            type: ApproverRequestType.transfer,
            title: 'Transfer Approval',
            subjectName: _buildFullName(
              firstName: item['staff_first_name'],
              middleName: item['staff_middle_name'],
              lastName: item['staff_last_name'],
              surName: item['staff_sur_name'],
            ),
            summary: [
              _stringValue(item['transfer_from']),
              _stringValue(item['transfer_to']),
            ].where((value) => value.isNotEmpty).join(' → '),
            status: _statusFromApi(item['status']),
            submittedAt: _dateValue(item['created_at']) ?? DateTime.now(),
            referenceNumber:
                'TR-${_stringValue(item['transfer_request_id']).padLeft(5, '0')}',
            attachmentName: _stringValue(item['upload_file_name']),
            parentStageId: _stringValue(item['parent_id']),
            rawStatus: _stringValue(item['status']),
            detailFields: [
              RequestDetailField(
                label: 'Reason',
                value: _stringValue(
                  item['transfer_reason_name'],
                  fallback: 'Transfer request',
                ),
              ),
              RequestDetailField(
                label: 'From',
                value: _stringValue(item['transfer_from'], fallback: 'N/A'),
              ),
              RequestDetailField(
                label: 'Department',
                value: _stringValue(item['from_department'], fallback: 'N/A'),
              ),
              RequestDetailField(
                label: 'To',
                value: _stringValue(item['transfer_to'], fallback: 'N/A'),
              ),
              RequestDetailField(
                label: 'To Department',
                value: _stringValue(item['to_department'], fallback: 'N/A'),
              ),
              RequestDetailField(
                label: 'Position',
                value: _stringValue(
                  item['post_category_name'],
                  fallback: 'N/A',
                ),
              ),
              RequestDetailField(
                label: 'Requester Role',
                value: _stringValue(item['requester_role'], fallback: 'N/A'),
              ),
              RequestDetailField(
                label: 'Phone',
                value: _stringValue(
                  item['staff_phone_number'],
                  fallback: 'N/A',
                ),
              ),
              RequestDetailField(
                label: 'Transfer Notes',
                value: _stringValue(
                  item['request_from'],
                  fallback: 'Not provided',
                ),
              ),
              RequestDetailField(
                label: 'Preferred Transfer Date',
                value: _displayOptionalDate(
                  _dateValue(item['preferred_transfer_date']),
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  Future<String> handleTransferApproval({
    required ApprovalTask task,
    required ApproverAction action,
    required String comment,
  }) async {
    final path = switch (action) {
      ApproverAction.forward => '/transferForwaed',
      ApproverAction.approve => '/approveStaffTransfer',
      ApproverAction.deny => '/denyStaffTransfer',
    };

    final response = await _postJson(
      path,
      data: {'transfer_request_id': task.requestId, 'comment': comment},
    );

    _ensureSuccessfulResponse(
      response,
      fallback: 'Transfer approval action failed.',
    );

    return _extractMessage(
      response.data,
      fallback: '${action.label} action completed.',
    );
  }

  Future<List<HomeTrainingItem>> fetchUpcomingTraining(UserModel user) async {
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

    return items
        .map(
          (item) => HomeTrainingItem(
            title: _stringValue(
              item['training_name'],
              fallback: 'Training programme',
            ),
            location: _stringValue(
              item['institute_name'],
              fallback: _stringValue(item['vendor_name'], fallback: 'TBD'),
            ),
            dateLabel: _dateRangeLabel(
              _dateValue(item['start_date']),
              _dateValue(item['end_date']),
            ),
            tag: _stringValue(
              item['training_app_status'],
              fallback: 'Internal',
            ).replaceAll('_', ' '),
          ),
        )
        .toList();
  }

  Future<List<HomeAnnouncement>> fetchAnnouncements() async {
    final response = await _get('/trainingAnnouncements');
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return buildAnnouncements(null);
    }

    return items.map(_announcementFromApi).toList()..sort((first, second) {
      final firstDate = first.startsAt ?? DateTime(1970);
      final secondDate = second.startsAt ?? DateTime(1970);
      return secondDate.compareTo(firstDate);
    });
  }

  Future<List<RequestLookupOption>> fetchLeaveTypes(UserModel user) async {
    if (user.personalInformationId.trim().isEmpty) {
      return buildMockLeaveTypes();
    }

    final response = await _get('/getLeaveType/${user.personalInformationId}');
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return buildMockLeaveTypes();
    }

    return items
        .map(
          (item) => RequestLookupOption(
            id: _stringValue(item['employement_status_id']),
            label: _stringValue(
              item['employement_status_name'],
              fallback: 'Leave',
            ),
            requiresAttachment: _boolValue(item['need_upload']),
            requiresDayCount: _boolValue(item['need_end_date']),
          ),
        )
        .toList();
  }

  Future<List<RequestLookupOption>> fetchRepresentatives() async {
    final response = await _get('/getRepresentative');
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return buildMockRepresentatives();
    }

    return items
        .map(
          (item) => RequestLookupOption(
            id: _stringValue(item['personal_information_id']),
            label: [
              _stringValue(item['first_name']),
              _stringValue(item['middle_name']),
              _stringValue(item['last_name']),
            ].where((value) => value.isNotEmpty).join(' '),
            subtitle: _stringValue(item['senority_name']),
          ),
        )
        .toList();
  }

  Future<List<RequestLookupOption>> fetchTransferReasons() async {
    final response = await _get('/staffTransferReasons');
    final items = _extractList(response.data);
    if (items.isEmpty) {
      return buildMockTransferReasons();
    }

    return items
        .map(
          (item) => RequestLookupOption(
            id: _stringValue(item['transfer_reason_id']),
            label: _stringValue(
              item['transfer_reason_name'],
              fallback: 'Transfer',
            ),
            requiresAttachment: _boolValue(item['need_upload']),
          ),
        )
        .toList();
  }

  Future<List<RequestLookupOption>> fetchActivityOptions() async {
    try {
      final response = await _get('/activities');
      log('Activities response: ${response.data}');
      final items = _extractList(response.data);
      final options = <RequestLookupOption>[];

      void addActivity(Map<String, dynamic> item) {
        final id = _stringValue(item['activity_id']);
        if (id.isEmpty) return;
        options.add(
          RequestLookupOption(
            id: id,
            label: _stringValue(item['activity_name'], fallback: 'Activity'),
            subtitle: [
              _stringValue(item['activity_code']),
              _stringValue(item['type']),
            ].where((value) => value.isNotEmpty).join(' • '),
          ),
        );

        final children = item['children'];
        if (children is List) {
          for (final child in children) {
            if (child is! Map) continue;
            addActivity(
              child.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
        }
      }

      for (final item in items) {
        addActivity(item);
      }

      return options;
    } catch (e) {
      log('Error fetching activities: $e');
      return [];
    }
  }

  Future<List<RequestLookupOption>> fetchLoanBanks() async {
    final response = await _get('/banks');
    final items = _extractList(response.data);

    return items
        .map(
          (item) => RequestLookupOption(
            id: _stringValue(item['bank_id']),
            label: _stringValue(item['bank_name'], fallback: 'Bank'),
            subtitle: _stringValue(item['abraviation']),
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<FacilityDirectory> fetchFacilityDirectory() async {
    final response = await _get('/getAllWorkingStations');
    final items = _extractList(response.data);

    if (items.isEmpty) {
      return buildMockFacilityDirectory();
    }

    final facilities = <RequestLookupOption>[];
    final departmentsByFacilityId = <String, List<RequestLookupOption>>{};

    for (final item in items) {
      final facilityId = _stringValue(item['working_station_id']);
      final facilityLabel = _stringValue(
        item['working_station_name'],
        fallback: 'Facility',
      );
      facilities.add(RequestLookupOption(id: facilityId, label: facilityLabel));

      final workingPositions = item['working_positions'];
      final departments = <RequestLookupOption>[];
      if (workingPositions is List) {
        for (final position in workingPositions) {
          if (position is! Map) continue;
          final normalized = position.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          departments.add(
            RequestLookupOption(
              id: _stringValue(normalized['working_position_id']),
              label: _stringValue(
                normalized['department_name'],
                fallback: 'Department',
              ),
            ),
          );
        }
      }
      departmentsByFacilityId[facilityId] = departments;
    }

    return FacilityDirectory(
      facilities: facilities,
      departmentsByFacilityId: departmentsByFacilityId,
    );
  }

  Future<StaffRequestRecord> submitLeaveRequest({
    required UserModel user,
    required LeaveRequestDraft draft,
  }) async {
    final payload = <String, dynamic>{
      'personal_information_id': user.personalInformationId,
      'employement_status_id': draft.leaveTypeId,
      'proposed_start_date': _toApiDate(draft.startDate),
      'contact_on_leave': draft.contactOnLeave,
      'number_of_days': draft.numberOfDays?.toString() ?? 'null',
      if ((draft.representativeId ?? '').trim().isNotEmpty)
        'representative_id': draft.representativeId,
      if ((draft.placeToTravel ?? '').trim().isNotEmpty)
        'place_to_travel': draft.placeToTravel,
      if ((draft.filePath ?? '').trim().isNotEmpty)
        'upload_file_name': await MultipartFile.fromFile(
          draft.filePath!,
          filename: draft.fileName,
        ),
    };

    final response = await _postForm('/leaveRequests', data: payload);
    _ensureSuccessfulResponse(
      response,
      fallback: 'Leave request was not submitted.',
    );

    final reference = _reference(prefix: 'LV');
    return StaffRequestRecord(
      id: reference,
      type: StaffRequestType.leave,
      title: '${draft.leaveTypeLabel} Request',
      summary: draft.reason,
      status: StaffRequestStatus.pending,
      submittedAt: DateTime.now(),
      referenceNumber: reference,
      startDate: draft.startDate,
      endDate: draft.endDate,
      stageLabel: 'Submitted',
      isLive: true,
      detailFields: [
        RequestDetailField(label: 'Leave Type', value: draft.leaveTypeLabel),
        RequestDetailField(
          label: 'Start Date',
          value: _displayDate(draft.startDate),
        ),
        if (draft.endDate != null)
          RequestDetailField(
            label: 'End Date',
            value: _displayDate(draft.endDate!),
          ),
        RequestDetailField(
          label: 'Contact on Leave',
          value: draft.contactOnLeave,
        ),
        if (draft.numberOfDays != null)
          RequestDetailField(
            label: 'Number of Days',
            value: '${draft.numberOfDays}',
          ),
        RequestDetailField(
          label: 'Representative',
          value: draft.representativeLabel ?? 'Not selected',
        ),
        if ((draft.placeToTravel ?? '').trim().isNotEmpty)
          RequestDetailField(
            label: 'Place To Travel',
            value: draft.placeToTravel!,
          ),
        if ((draft.fileName ?? '').trim().isNotEmpty)
          RequestDetailField(label: 'Attachment', value: draft.fileName!),
        RequestDetailField(label: 'Reason', value: draft.reason),
        RequestDetailField(
          label: 'Status',
          value: StaffRequestStatus.pending.label,
          status: StaffRequestStatus.pending,
        ),
      ],
    );
  }

  Future<StaffRequestRecord> submitTransferRequest({
    required UserModel user,
    required TransferRequestDraft draft,
  }) async {
    final payload = <String, dynamic>{
      'personal_information_id': user.personalInformationId,
      'working_station_id_to': draft.facilityId,
      'transfer_reason_id': draft.reasonId,
      'preferred_transfer_date': _toApiDate(draft.preferredTransferDate),
      if (user.workingStationId.trim().isNotEmpty)
        'working_station_id_from': user.workingStationId,
      if ((draft.departmentId ?? '').trim().isNotEmpty)
        'working_position_id_to': draft.departmentId,
      if (draft.reasonText.trim().isNotEmpty) 'request_from': draft.reasonText,
      if (draft.reasonText.trim().isNotEmpty) 'reason_text': draft.reasonText,
      if ((draft.filePath ?? '').trim().isNotEmpty)
        'upload_file_name': await MultipartFile.fromFile(
          draft.filePath!,
          filename: draft.fileName,
        ),
    };

    final response = await _postForm('/staffTransferRequests', data: payload);
    _ensureSuccessfulResponse(
      response,
      fallback: 'Transfer request was not submitted.',
    );

    final reference = _reference(prefix: 'TR');
    return StaffRequestRecord(
      id: reference,
      type: StaffRequestType.transfer,
      title: 'Transfer Request',
      summary: draft.reasonText,
      status: StaffRequestStatus.pending,
      submittedAt: DateTime.now(),
      referenceNumber: reference,
      location: draft.facilityLabel,
      attachmentName: draft.fileName,
      stageLabel: 'Submitted',
      isLive: true,
      detailFields: [
        RequestDetailField(
          label: 'Preferred Facility',
          value: draft.facilityLabel,
        ),
        RequestDetailField(
          label: 'Preferred Department',
          value: draft.departmentLabel ?? 'Not selected',
        ),
        RequestDetailField(label: 'Reason', value: draft.reasonLabel),
        RequestDetailField(
          label: 'Transfer Notes',
          value: draft.reasonText.isEmpty ? 'Not provided' : draft.reasonText,
        ),
        RequestDetailField(
          label: 'Preferred Transfer Date',
          value: _displayDate(draft.preferredTransferDate),
        ),
        if ((draft.fileName ?? '').trim().isNotEmpty)
          RequestDetailField(label: 'Attachment', value: draft.fileName!),
        RequestDetailField(
          label: 'Status',
          value: StaffRequestStatus.pending.label,
          status: StaffRequestStatus.pending,
        ),
      ],
    );
  }

  Future<StaffRequestRecord> submitSickSheet({
    required UserModel user,
    required SickSheetDraft draft,
  }) async {
    final payload = <String, dynamic>{
      'document': await MultipartFile.fromFile(
        draft.filePath,
        filename: draft.fileName,
      ),
    };

    final response = await _postForm('/sick-sheets', data: payload);
    _ensureSuccessfulResponse(
      response,
      fallback: 'Sick sheet was not submitted.',
    );

    final serverRecord = _extractMap(response.data, 'sick_sheet');
    if (serverRecord.isNotEmpty) {
      return _sickSheetRecordFromApi(serverRecord).copyWith(
        startDate: draft.startDate,
        attachmentName: draft.fileName,
        detailFields: [
          ..._sickSheetRecordFromApi(serverRecord).detailFields,
          RequestDetailField(
            label: 'Sick Sheet Date',
            value: _displayDate(draft.startDate),
          ),
          RequestDetailField(label: 'Contact', value: draft.contactOnLeave),
          if (draft.note?.trim().isNotEmpty == true)
            RequestDetailField(label: 'Note', value: draft.note!.trim()),
        ],
      );
    }

    final reference = _reference(prefix: 'SL');
    return StaffRequestRecord(
      id: reference,
      type: StaffRequestType.sickLeave,
      title: 'Sick Sheet Submission',
      summary: draft.note?.trim().isNotEmpty == true
          ? draft.note!.trim()
          : 'Sick sheet uploaded for supervisor review',
      status: StaffRequestStatus.pending,
      submittedAt: DateTime.now(),
      referenceNumber: reference,
      startDate: draft.startDate,
      attachmentName: draft.fileName,
      stageLabel: 'Submitted',
      isLive: true,
      detailFields: [
        RequestDetailField(label: 'Leave Type', value: draft.leaveTypeLabel),
        RequestDetailField(
          label: 'Sick Sheet Date',
          value: _displayDate(draft.startDate),
        ),
        RequestDetailField(label: 'Attachment', value: draft.fileName),
        RequestDetailField(label: 'Contact', value: draft.contactOnLeave),
        if (draft.note?.trim().isNotEmpty == true)
          RequestDetailField(label: 'Note', value: draft.note!.trim()),
        RequestDetailField(
          label: 'Status',
          value: StaffRequestStatus.pending.label,
          status: StaffRequestStatus.pending,
        ),
      ],
    );
  }

  Future<StaffRequestRecord> submitActivityRequest({
    required UserModel user,
    required ActivityRequestDraft draft,
  }) async {
    final payload = <String, dynamic>{
      'name': draft.name,
      'activity_date': _toApiDate(draft.activityDate),
      'activity_area_type': draft.activityAreaType,
      if (draft.destinationName != null &&
          draft.destinationName!.trim().isNotEmpty)
        'destination_name': draft.destinationName!.trim(),
    };

    final response = await _postJson('/staff-activities', data: payload);
    _ensureSuccessfulResponse(
      response,
      fallback: 'Activity request was not submitted.',
    );

    final reference = _reference(prefix: 'AR');
    return StaffRequestRecord(
      id: reference,
      type: StaffRequestType.activity,
      title: draft.name,
      summary: draft.description?.trim().isEmpty == true
          ? 'Activity scope: ${draft.activityAreaType}'
          : draft.description!.trim(),
      status: StaffRequestStatus.submitted,
      submittedAt: DateTime.now(),
      referenceNumber: reference,
      startDate: draft.activityDate,
      location: draft.destinationName,
      stageLabel: 'Submitted',
      isLive: true,
      detailFields: [
        RequestDetailField(label: 'Activity', value: draft.name),
        RequestDetailField(
          label: 'Activity Scope',
          value: draft.activityAreaType,
        ),
        if (draft.destinationName?.trim().isNotEmpty == true)
          RequestDetailField(label: 'Location', value: draft.destinationName!),
        if (draft.description?.trim().isNotEmpty == true)
          RequestDetailField(label: 'Description', value: draft.description!),
        RequestDetailField(
          label: 'Status',
          value: StaffRequestStatus.submitted.label,
          status: StaffRequestStatus.submitted,
        ),
      ],
    );
  }

  Future<StaffRequestRecord> submitLoanRequest({
    required LoanRequestDraft draft,
  }) async {
    final amount = int.tryParse(draft.requestedAmount.replaceAll(',', ''));
    if (amount == null || amount < 1) {
      throw Exception('Enter a valid requested amount.');
    }

    final bankId = int.tryParse(draft.bankId);
    if (bankId == null) {
      throw Exception('Select a valid bank.');
    }

    final response = await _postJson(
      '/loans',
      data: {
        'approved_bank_id': bankId,
        'amount': amount,
        'term_duration': draft.termDuration,
        'term_period': draft.termPeriod,
      },
    );
    _ensureSuccessfulResponse(
      response,
      fallback: 'Loan request was not submitted.',
    );

    final serverRecord = _extractMap(response.data, 'loan');
    if (serverRecord.isNotEmpty) {
      return _loanRecordFromApi(serverRecord).copyWith(
        summary: draft.purpose.trim().isEmpty
            ? _loanRecordFromApi(serverRecord).summary
            : draft.purpose.trim(),
        detailFields: [
          ..._loanRecordFromApi(serverRecord).detailFields,
          RequestDetailField(label: 'Loan Type', value: draft.loanType),
          RequestDetailField(
            label: 'Employer Status',
            value: draft.employerStatus,
          ),
          RequestDetailField(
            label: 'Monthly Salary',
            value: draft.monthlySalary,
          ),
          if (draft.purpose.trim().isNotEmpty)
            RequestDetailField(label: 'Purpose', value: draft.purpose.trim()),
        ],
      );
    }

    final reference = _reference(prefix: 'LN');
    return StaffRequestRecord(
      id: reference,
      type: StaffRequestType.loan,
      title: 'Loan Application',
      summary: draft.purpose.trim().isEmpty
          ? draft.bankLabel
          : draft.purpose.trim(),
      status: StaffRequestStatus.pending,
      submittedAt: DateTime.now(),
      referenceNumber: reference,
      stageLabel: 'Submitted',
      isLive: true,
      detailFields: [
        RequestDetailField(label: 'Bank', value: draft.bankLabel),
        RequestDetailField(
          label: 'Requested Amount',
          value: draft.requestedAmount,
        ),
        RequestDetailField(
          label: 'Repayment Period',
          value: draft.repaymentMonths,
        ),
        RequestDetailField(label: 'Loan Type', value: draft.loanType),
        RequestDetailField(label: 'Purpose', value: draft.purpose),
        const RequestDetailField(
          label: 'Status',
          value: 'Pending',
          status: StaffRequestStatus.pending,
        ),
      ],
    );
  }

  StaffRequestRecord _loanRecordFromApi(Map<String, dynamic> item) {
    final amount = _stringValue(item['amount'], fallback: '0');
    final bank = _extractNestedMap(item['approved_bank']);
    final latestReview = _extractNestedMap(item['latest_review']);
    final status = _statusFromApi(
      latestReview['status'] ?? item['review_status'] ?? item['current_status'],
    );
    final uuid = _stringValue(item['uuid'], fallback: _reference(prefix: 'LN'));
    final termDuration = _stringValue(item['term_duration']);
    final termPeriod = _stringValue(item['term_period'], fallback: 'MONTH');
    final bankName = _stringValue(bank['bank_name'], fallback: 'Selected bank');

    return StaffRequestRecord(
      id: 'loan-$uuid',
      type: StaffRequestType.loan,
      title: 'Loan Application',
      summary: '$bankName • TZS $amount',
      status: status,
      submittedAt: _dateValue(item['created_at']) ?? DateTime.now(),
      referenceNumber: 'LN-${uuid.length > 8 ? uuid.substring(0, 8) : uuid}',
      stageLabel: _stringValue(item['current_status'], fallback: status.label),
      isLive: true,
      detailFields: [
        RequestDetailField(label: 'Bank', value: bankName),
        RequestDetailField(label: 'Requested Amount', value: 'TZS $amount'),
        RequestDetailField(
          label: 'Repayment Period',
          value: '$termDuration ${termPeriod.toLowerCase()}',
        ),
        RequestDetailField(
          label: 'Current Status',
          value: _stringValue(item['current_status'], fallback: status.label),
        ),
        RequestDetailField(
          label: 'Review Status',
          value: _stringValue(latestReview['status'], fallback: status.label),
          status: status,
        ),
        if (_stringValue(latestReview['comment']).isNotEmpty)
          RequestDetailField(
            label: 'Review Comment',
            value: _stringValue(latestReview['comment']),
          ),
      ],
    );
  }

  StaffRequestRecord _sickSheetRecordFromApi(Map<String, dynamic> item) {
    final uuid = _stringValue(item['uuid'], fallback: _reference(prefix: 'SL'));
    final status = _statusFromApi(item['status']);
    final filePath = _stringValue(item['file_path']);

    return StaffRequestRecord(
      id: 'sick-$uuid',
      type: StaffRequestType.sickLeave,
      title: 'Sick Sheet Submission',
      summary: _stringValue(
        item['review_comment'],
        fallback: 'Sick sheet uploaded for supervisor review',
      ),
      status: status,
      submittedAt: _dateValue(item['created_at']) ?? DateTime.now(),
      referenceNumber: 'SL-${uuid.length > 8 ? uuid.substring(0, 8) : uuid}',
      attachmentName: filePath.split('/').last,
      stageLabel: status.label,
      isLive: true,
      detailFields: [
        RequestDetailField(label: 'Submission Type', value: 'Sick Sheet'),
        if (filePath.isNotEmpty)
          RequestDetailField(
            label: 'Attachment',
            value: filePath.split('/').last,
          ),
        RequestDetailField(
          label: 'Review Comment',
          value: _stringValue(
            item['review_comment'],
            fallback: 'Pending review',
          ),
        ),
        RequestDetailField(
          label: 'Status',
          value: status.label,
          status: status,
        ),
      ],
    );
  }

  List<HomeAnnouncement> buildAnnouncements(UserModel? user) {
    return const [];
  }

  HomeAnnouncement _announcementFromApi(Map<String, dynamic> item) {
    final title = _stringValue(
      item['title'],
      fallback: _stringValue(
        item['training_name'],
        fallback: 'Training Announcement',
      ),
    );
    final description = _stringValue(
      item['body'],
      fallback: _stringValue(
        item['text'],
        fallback: _stringValue(
          item['discription'],
          fallback: 'Announcement details are available.',
        ),
      ),
    );
    final startsAt = _dateValue(
      item['starts_at'],
      fallback: _dateValue(item['announce_start_date']),
    );
    final endsAt = _dateValue(
      item['ends_at'],
      fallback: _dateValue(item['announce_end_date']),
    );
    final type = _stringValue(item['type'], fallback: 'Training');
    final caption = endsAt == null
        ? type
        : '$type • Ends ${_displayDate(endsAt)}';

    return HomeAnnouncement(
      id: _stringValue(
        item['announcement_id'],
        fallback: _stringValue(item['training_announcement_id']),
      ),
      title: title,
      subtitle: description,
      caption: caption,
      type: type,
      externalLink: _stringValue(item['external_link']),
      startsAt: startsAt,
      endsAt: endsAt,
      isLive: true,
    );
  }

  List<RequestLookupOption> buildMockLeaveTypes() {
    return const [
      RequestLookupOption(id: '2', label: 'Annual Leave'),
      RequestLookupOption(id: '5', label: 'Study Leave'),
      RequestLookupOption(id: '7', label: 'Maternity Leave'),
      RequestLookupOption(id: '9', label: 'Compassionate Leave'),
    ];
  }

  List<RequestLookupOption> buildMockRepresentatives() {
    return const [
      RequestLookupOption(
        id: '1001',
        label: 'Dr. Husein Ali',
        subtitle: 'Senior Medical Officer',
      ),
      RequestLookupOption(
        id: '1002',
        label: 'Nurse Fatma Juma',
        subtitle: 'Ward In-Charge',
      ),
      RequestLookupOption(
        id: '1003',
        label: 'Dr. Said Hamad',
        subtitle: 'Department Head',
      ),
    ];
  }

  List<RequestLookupOption> buildMockTransferReasons() {
    return const [
      RequestLookupOption(id: '1', label: 'Family Reasons'),
      RequestLookupOption(id: '2', label: 'Career Growth'),
      RequestLookupOption(id: '3', label: 'Medical Reasons'),
      RequestLookupOption(id: '4', label: 'Administrative Request'),
    ];
  }

  FacilityDirectory buildMockFacilityDirectory() {
    return const FacilityDirectory(
      facilities: [
        RequestLookupOption(id: '201', label: 'Mnazi Mmoja Hospital'),
        RequestLookupOption(id: '202', label: 'Kivunge Hospital'),
        RequestLookupOption(id: '203', label: 'Pemba Referral Hospital'),
      ],
      departmentsByFacilityId: {
        '201': [
          RequestLookupOption(id: '301', label: 'Clinical Services'),
          RequestLookupOption(id: '302', label: 'Public Health Unit'),
        ],
        '202': [
          RequestLookupOption(id: '303', label: 'Outpatient Department'),
          RequestLookupOption(id: '304', label: 'Maternity Unit'),
        ],
        '203': [
          RequestLookupOption(id: '305', label: 'Emergency Department'),
          RequestLookupOption(id: '306', label: 'Laboratory Services'),
        ],
      },
    );
  }

  List<StaffRequestRecord> buildMockRequests(UserModel? user) {
    final now = DateTime.now();
    return [
      StaffRequestRecord(
        id: 'activity-1',
        type: StaffRequestType.activity,
        title: 'Manual Hand Foot Wash',
        summary: 'Activity scope: Internal',
        status: StaffRequestStatus.pending,
        submittedAt: now.subtract(const Duration(days: 2)),
        startDate: DateTime(now.year, 4, 17),
        endDate: DateTime(now.year, 4, 17),
        location: 'Manzini District Hospital',
        referenceNumber: 'AC-2026-00214',
        detailFields: const [
          RequestDetailField(label: 'Title', value: 'Manual Hand Foot Wash'),
          RequestDetailField(label: 'Category', value: 'Travel'),
          RequestDetailField(label: 'Activity Scope', value: 'Within Zanzibar'),
          RequestDetailField(
            label: 'Location',
            value: 'Manzini District Hospital',
          ),
          RequestDetailField(label: 'Description', value: 'Fall Event'),
          RequestDetailField(
            label: 'Status',
            value: 'Pending',
            status: StaffRequestStatus.pending,
          ),
        ],
      ),
      StaffRequestRecord(
        id: 'leave-mock-1',
        type: StaffRequestType.leave,
        title: 'Annual Leave Request',
        summary: 'Annual leave - 10 days',
        status: StaffRequestStatus.approved,
        submittedAt: now.subtract(const Duration(days: 6)),
        startDate: DateTime(now.year, 4, 10),
        endDate: DateTime(now.year, 4, 20),
        attachmentName: 'Residence Letter.pdf',
        referenceNumber: 'LV-2026-00198',
        detailFields: const [
          RequestDetailField(label: 'Leave Type', value: 'Annual Leave'),
          RequestDetailField(label: 'Start Date', value: '10 Apr 2026'),
          RequestDetailField(label: 'End Date', value: '20 Apr 2026'),
          RequestDetailField(label: 'Contact on Leave', value: '0712 345 678'),
          RequestDetailField(label: 'Representative', value: 'Dr. Husein Ali'),
          RequestDetailField(
            label: 'Status',
            value: 'Approved',
            status: StaffRequestStatus.approved,
          ),
        ],
      ),
      StaffRequestRecord(
        id: 'transfer-mock-1',
        type: StaffRequestType.transfer,
        title: 'Transfer Request',
        summary: 'Requesting transfer to Kivunge Hospital',
        status: StaffRequestStatus.pending,
        submittedAt: now.subtract(const Duration(days: 3)),
        location: 'Kivunge Hospital',
        referenceNumber: 'TR-2026-00206',
        detailFields: [
          RequestDetailField(
            label: 'Current Facility',
            value: user?.workingStationName ?? 'Mnazi Mmoja Hospital',
          ),
          const RequestDetailField(
            label: 'Current Department',
            value: 'Outpatient Department',
          ),
          const RequestDetailField(
            label: 'Preferred Facility',
            value: 'Kivunge Hospital',
          ),
          const RequestDetailField(label: 'Reason', value: 'General Request'),
          const RequestDetailField(
            label: 'Status',
            value: 'Pending',
            status: StaffRequestStatus.pending,
          ),
        ],
      ),
      StaffRequestRecord(
        id: 'loan-1',
        type: StaffRequestType.loan,
        title: 'Loan Application',
        summary: 'School fees support',
        status: StaffRequestStatus.rejected,
        submittedAt: now.subtract(const Duration(days: 11)),
        referenceNumber: 'LN-2026-00161',
        detailFields: const [
          RequestDetailField(
            label: 'Loan Type',
            value: 'Soft Development Loan',
          ),
          RequestDetailField(label: 'Requested Amount', value: '1,200,000'),
          RequestDetailField(label: 'Purpose', value: 'School fees support'),
          RequestDetailField(label: 'Repayment Period', value: '12 Months'),
          RequestDetailField(
            label: 'Status',
            value: 'Rejected',
            status: StaffRequestStatus.rejected,
          ),
        ],
      ),
      StaffRequestRecord(
        id: 'sick-1',
        type: StaffRequestType.sickLeave,
        title: 'Sick Leave Submission',
        summary: 'Medical follow-up submitted',
        status: StaffRequestStatus.submitted,
        submittedAt: now.subtract(const Duration(days: 1)),
        referenceNumber: 'SL-2026-00222',
        attachmentName: 'Medical Note.pdf',
        detailFields: const [
          RequestDetailField(
            label: 'Submission Type',
            value: 'Medical Follow-up',
          ),
          RequestDetailField(label: 'Attachment', value: 'Medical Note.pdf'),
          RequestDetailField(
            label: 'Status',
            value: 'Submitted',
            status: StaffRequestStatus.submitted,
          ),
        ],
      ),
    ];
  }

  Future<Response<dynamic>> _get(String path) async {
    try {
      return await _dio.get(path, options: await _authorizedOptions());
    } on DioException catch (error) {
      throw Exception(
        _resolveRequestError(
          error,
          fallback: 'We could not load the requested data.',
        ),
      );
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
        options: await _authorizedOptions(),
      );
    } on DioException catch (error) {
      throw Exception(
        _resolveRequestError(
          error,
          fallback: 'The request could not be completed.',
        ),
      );
    }
  }

  Future<Response<dynamic>> _postForm(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _dio.post(
        path,
        data: FormData.fromMap(data),
        options: await _authorizedOptions(
          extraHeaders: const {'Content-Type': 'multipart/form-data'},
        ),
      );
    } on DioException catch (error) {
      throw Exception(
        _resolveRequestError(
          error,
          fallback: 'The request could not be submitted.',
        ),
      );
    }
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

  List<Map<String, dynamic>> _extractTransferSequenceList(
    dynamic responseData,
  ) {
    final data = _extractList(responseData);
    if (data.isNotEmpty) {
      return data;
    }

    final request = _extractListByKey(responseData, 'request');
    if (request.isNotEmpty) {
      return request;
    }

    return _extractListByKey(responseData, 'transfer');
  }

  List<Map<String, dynamic>> _extractListByKey(
    dynamic responseData,
    String key,
  ) {
    if (responseData is Map<String, dynamic>) {
      return _extractList(responseData[key]);
    }
    if (responseData is Map) {
      return _extractListByKey(
        responseData.map((mapKey, value) => MapEntry(mapKey.toString(), value)),
        key,
      );
    }
    return const [];
  }

  Map<String, dynamic> _extractNestedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((mapKey, mapValue) {
        return MapEntry(mapKey.toString(), mapValue);
      });
    }
    return const {};
  }

  Map<String, dynamic> _extractMap(dynamic responseData, String key) {
    if (responseData is Map<String, dynamic>) {
      final value = responseData[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((mapKey, mapValue) {
          return MapEntry(mapKey.toString(), mapValue);
        });
      }
    }
    if (responseData is Map) {
      return _extractMap(
        responseData.map((mapKey, value) => MapEntry(mapKey.toString(), value)),
        key,
      );
    }
    return const {};
  }

  StaffRequestStatus _statusFromApi(dynamic rawStatus) {
    final value = _stringValue(rawStatus).toUpperCase();
    switch (value) {
      case 'APPROVED':
      case 'COMPLETED':
        return StaffRequestStatus.approved;
      case 'DENIED':
      case 'REJECTED':
      case 'DEFAULTED':
        return StaffRequestStatus.rejected;
      case 'WITHDRAWN':
        return StaffRequestStatus.withdrawn;
      case 'SUBMITTED':
      case 'RECEIVED':
        return StaffRequestStatus.submitted;
      case 'APPLIED':
      case 'REQUESTED':
      case 'FORWARDED':
      default:
        return StaffRequestStatus.pending;
    }
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  int? _intValue(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString().trim());
  }

  bool _boolValue(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) return fallback;
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }

  DateTime? _dateValue(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback;
    if (value is DateTime) return value;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return fallback;
    return DateTime.tryParse(normalized) ?? fallback;
  }

  String _reference({required String prefix}) {
    final now = DateTime.now();
    final serial = (now.millisecondsSinceEpoch % 100000).toString().padLeft(
      5,
      '0',
    );
    return '$prefix-${now.year}-$serial';
  }

  String _toApiDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _toSlashDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year.toString().padLeft(4, '0')}';
  }

  String _displayDate(DateTime value) {
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
    return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
  }

  String _dateRangeLabel(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'To be scheduled';
    if (start != null && end != null) {
      return '${_displayDate(start)} - ${_displayDate(end)}';
    }
    return _displayDate(start ?? end!);
  }

  String _displayOptionalDate(DateTime? value) {
    if (value == null) return 'Not scheduled';
    return _displayDate(value);
  }

  String _buildFullName({
    dynamic firstName,
    dynamic middleName,
    dynamic lastName,
    dynamic surName,
  }) {
    return [
      _stringValue(firstName),
      _stringValue(middleName),
      _stringValue(lastName),
      _stringValue(surName),
    ].where((value) => value.isNotEmpty).join(' ');
  }

  String _extractMessage(dynamic responseData, {required String fallback}) {
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is Map && message.isNotEmpty) {
        final firstEntry = message.values.first;
        return _extractMessage(firstEntry, fallback: fallback);
      }
      if (message is List && message.isNotEmpty) {
        return _extractMessage(message.first, fallback: fallback);
      }
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }

      final messages = responseData['messages'];
      if (messages is Map && messages.isNotEmpty) {
        final firstEntry = messages.values.first;
        return _extractMessage(firstEntry, fallback: fallback);
      }
      if (messages is List && messages.isNotEmpty) {
        return _extractMessage(messages.first, fallback: fallback);
      }

      final error = responseData['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
    }
    if (responseData is Map) {
      return _extractMessage(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
        fallback: fallback,
      );
    }
    if (responseData is List && responseData.isNotEmpty) {
      return _extractMessage(responseData.first, fallback: fallback);
    }
    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }
    return fallback;
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
    if (statusCode == null || statusCode == 200 || statusCode == 201) {
      return;
    }

    throw Exception(_extractMessage(response.data, fallback: fallback));
  }

  int? _extractStatusCode(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final value = responseData['statusCode'];
      if (value is int) {
        return value;
      }
      return int.tryParse(value?.toString().trim() ?? '');
    }
    if (responseData is Map) {
      return _extractStatusCode(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  String _resolveRequestError(DioException error, {required String fallback}) {
    final responseData = error.response?.data;
    final message = _extractMessage(responseData, fallback: fallback);
    final normalized = message.trim();
    if (normalized.isNotEmpty && normalized != fallback) {
      return normalized;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Network error. Please check your connection and try again.';
    }

    return fallback;
  }
}
