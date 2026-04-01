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
    final items = _extractList(response.data);

    return items
        .map(
          (item) => StaffRequestRecord(
            id: 'transfer-${_stringValue(item['transfer_request_id'])}',
            type: StaffRequestType.transfer,
            title:
                '${_stringValue(item['transfer_reason_name'], fallback: 'Transfer')} Request',
            summary: [
              _stringValue(item['transfer_from']),
              _stringValue(item['transfer_to']),
            ].where((value) => value.isNotEmpty).join(' → '),
            status: _statusFromApi(item['status']),
            submittedAt: _dateValue(item['created_at']) ?? DateTime.now(),
            referenceNumber:
                'TR-${_stringValue(item['transfer_request_id']).padLeft(5, '0')}',
            location: _stringValue(item['transfer_to']),
            attachmentName: _stringValue(item['upload_file_name']),
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
                value: _stringValue(
                  item['transfer_from'],
                  fallback: user.workingStationName,
                ),
              ),
              RequestDetailField(
                label: 'From Department',
                value: _stringValue(item['from_department'], fallback: 'N/A'),
              ),
              RequestDetailField(
                label: 'To',
                value: _stringValue(item['transfer_to'], fallback: 'N/A'),
              ),
              RequestDetailField(
                label: 'Cadre',
                value: _stringValue(
                  item['post_category_name'],
                  fallback: 'General',
                ),
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

  Future<List<HomeTrainingItem>> fetchUpcomingTraining(UserModel user) async {
    if (user.personalInformationId.trim().isEmpty) {
      return buildMockTraining();
    }

    final response = await _postJson(
      '/viewStaffTrainingRequest',
      data: {'personal_information_id': user.personalInformationId},
    );

    final items = _extractList(response.data);
    if (items.isEmpty) {
      return buildMockTraining();
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
          ),
        )
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
    final days = draft.endDate.difference(draft.startDate).inDays + 1;

    final payload = <String, dynamic>{
      'personal_information_id': user.personalInformationId,
      'employement_status_id': draft.leaveTypeId,
      'proposed_start_date': _toApiDate(draft.startDate),
      'proposed_end_date': _toApiDate(draft.endDate),
      'contact_on_leave': draft.contactOnLeave,
      'number_of_days': '$days',
      if (draft.reason.trim().isNotEmpty) 'reason': draft.reason,
      if (draft.reason.trim().isNotEmpty) 'leave_reason': draft.reason,
      if ((draft.representativeId ?? '').trim().isNotEmpty)
        'representative_id': draft.representativeId,
      if ((draft.placeToTravel ?? '').trim().isNotEmpty)
        'place_to_travel': draft.placeToTravel,
    };

    await _postForm('/leaveRequests', data: payload);

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
        RequestDetailField(
          label: 'End Date',
          value: _displayDate(draft.endDate),
        ),
        RequestDetailField(
          label: 'Contact on Leave',
          value: draft.contactOnLeave,
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
      if (draft.reasonText.trim().isNotEmpty) 'reason': draft.reasonText,
      if (draft.reasonText.trim().isNotEmpty) 'reason_text': draft.reasonText,
    };

    await _postForm('/staffTransferRequests', data: payload);

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
        RequestDetailField(label: 'Notes', value: draft.reasonText),
        RequestDetailField(
          label: 'Preferred Transfer Date',
          value: _displayDate(draft.preferredTransferDate),
        ),
        RequestDetailField(
          label: 'Status',
          value: StaffRequestStatus.pending.label,
          status: StaffRequestStatus.pending,
        ),
      ],
    );
  }

  List<HomeAnnouncement> buildAnnouncements(UserModel? user) {
    return const [
      HomeAnnouncement(
        title: 'New Training Opportunity',
        subtitle: 'Public Health Surveillance training open for nominations.',
        caption: 'Deadline is 15 March 2026',
      ),
      HomeAnnouncement(
        title: 'Internal Memo',
        subtitle: 'Quarterly planning workshop registration closes this week.',
        caption: 'Seats are limited',
      ),
    ];
  }

  List<HomeTrainingItem> buildMockTraining() {
    return const [
      HomeTrainingItem(
        title: 'Maternal Health Capacity Training',
        location: 'Zanzibar Health Training Institute',
        dateLabel: '12/03/2026',
        tag: 'Internal',
      ),
      HomeTrainingItem(
        title: 'Public Health Surveillance',
        location: 'Mnazi Mmoja Conference Hall',
        dateLabel: '15/03/2026',
        tag: 'Workshop',
      ),
    ];
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

  StaffRequestStatus _statusFromApi(dynamic rawStatus) {
    final value = _stringValue(rawStatus).toUpperCase();
    switch (value) {
      case 'APPROVED':
        return StaffRequestStatus.approved;
      case 'DENIED':
      case 'REJECTED':
        return StaffRequestStatus.rejected;
      case 'WITHDRAWN':
        return StaffRequestStatus.withdrawn;
      case 'SUBMITTED':
        return StaffRequestStatus.submitted;
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
}
