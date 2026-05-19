import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:staffportal/features/auth/models/staff_portal_access.dart';
import 'package:staffportal/features/requests/models/staff_request_models.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/providers/app_providers.dart';
import '../providers/staff_request_view_model.dart';
import 'activity_request_form.dart';
import 'leave_request_form.dart';
import 'loan_request_form.dart';
import 'sick_sheet_form.dart';
import 'transfer_request_form.dart';

part '../widgets/requests_screen_widgets.dart';

const _requestBlue = Color(0xFF1F6BFF);
const _requestSurface = Color(0xFFF5F7FB);
const _requestCard = Colors.white;
const _requestBorder = Color(0xFFE8EEF6);
const _requestText = Color(0xFF111827);
const _requestMuted = Color(0xFF6B7280);

Future<void> showRequestComposerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _NewRequestSheet(parentContext: context),
  );
}

void openRequestFormScreen(BuildContext context, StaffRequestType type) {
  final page = switch (type) {
    StaffRequestType.activity => const ActivityRequestFormScreen(),
    StaffRequestType.leave => const LeaveRequestFormScreen(),
    StaffRequestType.transfer => const TransferRequestFormScreen(),
    StaffRequestType.loan => const LoanRequestFormScreen(),
    StaffRequestType.sickLeave => const SickSheetFormScreen(),
  };

  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key, this.initialShowApprovals = false});

  final bool initialShowApprovals;

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  bool _showApprovals = false;
  StaffRequestType? _requestFilterType;
  StaffRequestStatus? _requestFilterStatus;
  ApproverRequestType? _approvalFilterType;
  StaffRequestStatus? _approvalFilterStatus;

  @override
  void initState() {
    super.initState();
    _showApprovals = widget.initialShowApprovals;
  }

  bool get _hasRequestFilters =>
      _requestFilterType != null || _requestFilterStatus != null;

  bool get _hasApprovalFilters =>
      _approvalFilterType != null || _approvalFilterStatus != null;

  int _activeFilterCount(bool showApprovals) {
    if (showApprovals) {
      var count = 0;
      if (_approvalFilterType != null) count++;
      if (_approvalFilterStatus != null) count++;
      return count;
    }

    var count = 0;
    if (_requestFilterType != null) count++;
    if (_requestFilterStatus != null) count++;
    return count;
  }

  Future<void> _openFilterSheet(bool showApprovals) async {
    final selection = await showModalBottomSheet<_RequestFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestFilterSheet(
        showApprovals: showApprovals,
        requestType: _requestFilterType,
        requestStatus: _requestFilterStatus,
        approvalType: _approvalFilterType,
        approvalStatus: _approvalFilterStatus,
      ),
    );

    if (selection == null || !mounted) return;

    setState(() {
      _requestFilterType = selection.requestType;
      _requestFilterStatus = selection.requestStatus;
      _approvalFilterType = selection.approvalType;
      _approvalFilterStatus = selection.approvalStatus;
    });
  }

  void _clearRequestFilters() {
    setState(() {
      _requestFilterType = null;
      _requestFilterStatus = null;
    });
  }

  void _clearApprovalFilters() {
    setState(() {
      _approvalFilterType = null;
      _approvalFilterStatus = null;
    });
  }

  Iterable<StaffRequestRecord> _filteredRecordsForType(
    StaffRequestsState state,
    StaffRequestType type,
  ) {
    return state
        .recordsFor(type)
        .where(
          (record) =>
              _requestFilterStatus == null ||
              record.status == _requestFilterStatus,
        );
  }

  List<StaffRequestType> _visibleRequestTypes(StaffRequestsState state) {
    const ordered = [
      StaffRequestType.activity,
      StaffRequestType.leave,
      StaffRequestType.transfer,
      StaffRequestType.loan,
      StaffRequestType.sickLeave,
    ];

    if (!_hasRequestFilters) return ordered;

    if (_requestFilterType != null) return [_requestFilterType!];

    return ordered
        .where((type) => _filteredRecordsForType(state, type).isNotEmpty)
        .toList();
  }

  List<String> _activeFilterLabels(bool showApprovals) {
    if (showApprovals) {
      return [
        if (_approvalFilterType != null) _approvalFilterType!.label,
        if (_approvalFilterStatus != null) _approvalFilterStatus!.label,
      ];
    }

    return [
      if (_requestFilterType != null) _requestFilterType!.label,
      if (_requestFilterStatus != null) _requestFilterStatus!.label,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final access = ref.watch(staffPortalAccessProvider);
    final showApprovals = access.hasRequestApproverAccess && _showApprovals;
    final visibleRequestTypes = _visibleRequestTypes(state);
    final activeFilterLabels = _activeFilterLabels(showApprovals);
    final activeFilterCount = _activeFilterCount(showApprovals);

    return Scaffold(
      backgroundColor: _requestSurface,
      floatingActionButton: access.hasRequestApproverAccess && showApprovals
          ? null
          : FloatingActionButton(
              heroTag: 'requests-create-fab',
              backgroundColor: _requestBlue,
              onPressed: () => showRequestComposerSheet(context),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _requestBlue,
          onRefresh: () =>
              ref.read(staffRequestsViewModelProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Requests',
                      style: _requestTextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openFilterSheet(showApprovals),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _requestMuted,
                      side: const BorderSide(color: _requestBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.filter_list_rounded, size: 16),
                    label: Text(
                      activeFilterCount > 0
                          ? 'Filter ($activeFilterCount)'
                          : 'Filter',
                      style: _requestTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _requestMuted,
                      ),
                    ),
                  ),
                ],
              ),
              if (activeFilterLabels.isNotEmpty) ...[
                const SizedBox(height: 14),
                _InlineBanner(
                  message: 'Filters: ${activeFilterLabels.join(' • ')}',
                  onClose: showApprovals
                      ? _clearApprovalFilters
                      : _clearRequestFilters,
                ),
              ],
              if (access.hasRequestApproverAccess) ...[
                const SizedBox(height: 14),
                _RequestBoardToggle(
                  showApprovals: _showApprovals,
                  approvalCount: state.totalApprovalCount,
                  onChanged: (value) {
                    setState(() {
                      _showApprovals = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 18),
              if (state.errorMessage != null)
                _InlineBanner(
                  message: state.errorMessage!,
                  onClose: () => ref
                      .read(staffRequestsViewModelProvider.notifier)
                      .clearError(),
                  actionLabel: 'Retry',
                  onAction: () =>
                      ref.read(staffRequestsViewModelProvider.notifier).load(),
                ),
              if (state.errorMessage != null) const SizedBox(height: 14),
              if (showApprovals)
                ..._buildApproverContent(context, state)
              else if (state.isLoading && state.records.isEmpty)
                const _RequestOverviewShimmer()
              else ...[
                if (visibleRequestTypes.isEmpty)
                  const _ApprovalEmptyState(
                    message: 'No requests match the selected filters.',
                  )
                else
                  ..._buildRequestOverviewSections(
                    context,
                    state,
                    visibleRequestTypes,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildApproverContent(
    BuildContext context,
    StaffRequestsState state,
  ) {
    final items =
        [...state.leaveApprovalTasks, ...state.transferApprovalTasks].where((
          task,
        ) {
          if (_approvalFilterType != null && task.type != _approvalFilterType) {
            return false;
          }
          if (_approvalFilterStatus != null &&
              task.status != _approvalFilterStatus) {
            return false;
          }
          return true;
        }).toList()..sort(
          (first, second) => second.submittedAt.compareTo(first.submittedAt),
        );

    if (state.isLoading &&
        state.leaveApprovalTasks.isEmpty &&
        state.transferApprovalTasks.isEmpty) {
      return const [_ApprovalInboxShimmer()];
    }

    return [
      if (items.isEmpty)
        _ApprovalEmptyState(
          message: _hasApprovalFilters
              ? 'No approval items match the selected filters.'
              : 'No pending leave or transfer approvals right now.',
        )
      else
        ...items.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ApproverInboxCard(task: task),
          ),
        ),
    ];
  }

  List<Widget> _buildRequestOverviewSections(
    BuildContext context,
    StaffRequestsState state,
    List<StaffRequestType> visibleTypes,
  ) {
    final widgets = <Widget>[];

    for (var index = 0; index < visibleTypes.length; index++) {
      final type = visibleTypes[index];
      final items = _filteredRecordsForType(state, type).toList();

      widgets.add(
        _RequestOverviewSection(
          type: type,
          count: items.length,
          approvedCount: items
              .where((record) => record.status == StaffRequestStatus.approved)
              .length,
          pendingCount: items.where((record) => record.status.isOpen).length,
          onTap: () => _openList(context, type),
        ),
      );

      if (index < visibleTypes.length - 1) {
        widgets.add(const SizedBox(height: 14));
      }
    }

    return widgets;
  }

  void _openList(BuildContext context, StaffRequestType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestCategoryListScreen(
          type: type,
          initialStatusFilter: _requestFilterStatus,
        ),
      ),
    );
  }
}
