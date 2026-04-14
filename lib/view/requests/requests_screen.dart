import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/staff_portal_access.dart';
import '../../model/staff_request_models.dart';
import '../../view_model/providers.dart';
import '../../view_model/staff_request_view_model.dart';

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
    StaffRequestType.sickLeave => const RequestCategoryListScreen(
      type: StaffRequestType.sickLeave,
    ),
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

    return ordered.where((type) {
      if (_requestFilterType != null && type != _requestFilterType) {
        return false;
      }
      return _filteredRecordsForType(state, type).isNotEmpty;
    }).toList();
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
    final showApprovals = access.isApproverMode && _showApprovals;
    final visibleRequestTypes = _visibleRequestTypes(state);
    final activeFilterLabels = _activeFilterLabels(showApprovals);
    final activeFilterCount = _activeFilterCount(showApprovals);

    return Scaffold(
      backgroundColor: _requestSurface,
      floatingActionButton: access.isApproverMode && showApprovals
          ? null
          : FloatingActionButton(
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
              if (access.isApproverMode) ...[
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
                ),
              if (state.errorMessage != null) const SizedBox(height: 14),
              if (showApprovals)
                ..._buildApproverContent(context, state)
              else if (state.isLoading && state.records.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
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
      return const [
        Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
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

class _RequestBoardToggle extends StatelessWidget {
  const _RequestBoardToggle({
    required this.showApprovals,
    required this.approvalCount,
    required this.onChanged,
  });

  final bool showApprovals;
  final int approvalCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _requestBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RequestBoardToggleChip(
              label: 'My Requests',
              selected: !showApprovals,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RequestBoardToggleChip(
              label: 'Approvals ($approvalCount)',
              selected: showApprovals,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestBoardToggleChip extends StatelessWidget {
  const _RequestBoardToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.fontSize = 12,
    this.horizontalPadding = 12,
    this.verticalPadding = 10,
    this.scaleDownLabel = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final bool scaleDownLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFB7D3FF) : Colors.transparent,
          ),
        ),
        child: scaleDownLabel
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: _requestTextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: selected ? _requestBlue : _requestMuted,
                  ),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: _requestTextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: selected ? _requestBlue : _requestMuted,
                ),
              ),
      ),
    );
  }
}

class _RequestFilterSelection {
  const _RequestFilterSelection({
    this.requestType,
    this.requestStatus,
    this.approvalType,
    this.approvalStatus,
  });

  final StaffRequestType? requestType;
  final StaffRequestStatus? requestStatus;
  final ApproverRequestType? approvalType;
  final StaffRequestStatus? approvalStatus;
}

class _RequestFilterSheet extends StatefulWidget {
  const _RequestFilterSheet({
    required this.showApprovals,
    this.requestType,
    this.requestStatus,
    this.approvalType,
    this.approvalStatus,
  });

  final bool showApprovals;
  final StaffRequestType? requestType;
  final StaffRequestStatus? requestStatus;
  final ApproverRequestType? approvalType;
  final StaffRequestStatus? approvalStatus;

  @override
  State<_RequestFilterSheet> createState() => _RequestFilterSheetState();
}

class _RequestFilterSheetState extends State<_RequestFilterSheet> {
  late StaffRequestType? _requestType;
  late StaffRequestStatus? _requestStatus;
  late ApproverRequestType? _approvalType;
  late StaffRequestStatus? _approvalStatus;

  @override
  void initState() {
    super.initState();
    _requestType = widget.requestType;
    _requestStatus = widget.requestStatus;
    _approvalType = widget.approvalType;
    _approvalStatus = widget.approvalStatus;
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = StaffRequestStatus.values;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DEE8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Filter Requests',
              style: _requestTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.showApprovals ? 'Approval Type' : 'Request Type',
              style: _requestTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _requestMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: widget.showApprovals
                      ? _approvalType == null
                      : _requestType == null,
                  onTap: () => setState(() {
                    if (widget.showApprovals) {
                      _approvalType = null;
                    } else {
                      _requestType = null;
                    }
                  }),
                ),
                if (widget.showApprovals)
                  ...ApproverRequestType.values.map(
                    (type) => _FilterChip(
                      label: type.label,
                      selected: _approvalType == type,
                      onTap: () => setState(() => _approvalType = type),
                    ),
                  )
                else
                  ...StaffRequestType.values.map(
                    (type) => _FilterChip(
                      label: type.label,
                      selected: _requestType == type,
                      onTap: () => setState(() => _requestType = type),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Status',
              style: _requestTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _requestMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: widget.showApprovals
                      ? _approvalStatus == null
                      : _requestStatus == null,
                  onTap: () => setState(() {
                    if (widget.showApprovals) {
                      _approvalStatus = null;
                    } else {
                      _requestStatus = null;
                    }
                  }),
                ),
                ...statusOptions.map(
                  (status) => _FilterChip(
                    label: status.label,
                    selected: widget.showApprovals
                        ? _approvalStatus == status
                        : _requestStatus == status,
                    onTap: () => setState(() {
                      if (widget.showApprovals) {
                        _approvalStatus = status;
                      } else {
                        _requestStatus = status;
                      }
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _requestType = null;
                      _requestStatus = null;
                      _approvalType = null;
                      _approvalStatus = null;
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _requestMuted,
                      side: const BorderSide(color: _requestBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: () {
                      Navigator.of(context).pop(
                        _RequestFilterSelection(
                          requestType: _requestType,
                          requestStatus: _requestStatus,
                          approvalType: _approvalType,
                          approvalStatus: _approvalStatus,
                        ),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: _requestTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? _requestBlue : _requestMuted,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFEAF2FF),
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? const Color(0xFFB7D3FF) : _requestBorder,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      showCheckmark: false,
    );
  }
}

class _ApproverInboxCard extends ConsumerWidget {
  const _ApproverInboxCard({required this.task});

  final ApprovalTask task;

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    ApproverAction action,
  ) async {
    var actionableTask = task;
    if (task.type == ApproverRequestType.leave) {
      try {
        actionableTask = await ref
            .read(staffRequestsViewModelProvider.notifier)
            .loadApprovalTaskDetail(task);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
          ),
        );
        return;
      }
    }
    if (!context.mounted) return;

    final result = await showModalBottomSheet<_ApprovalActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ApprovalActionSheet(task: actionableTask, action: action),
    );

    if (result == null) return;

    try {
      final message = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .performApprovalAction(
            task: actionableTask,
            action: action,
            comment: result.comment,
            startDate: result.startDate,
            endDate: result.endDate,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffPortalAccessProvider);
    final requestState = ref.watch(staffRequestsViewModelProvider);
    final actions = _approvalActionsFor(access, task);
    final hasApprove = actions.contains(ApproverAction.approve);
    final hasDeny = actions.contains(ApproverAction.deny);
    final hasForward = actions.contains(ApproverAction.forward);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.type == ApproverRequestType.leave
                      ? 'Leave Request'
                      : 'Transfer Request',
                  style: _requestTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: _requestMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _formatShortDate(task.submittedAt),
                style: _requestTextStyle(fontSize: 12, color: _requestMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFFFF0D6),
                child: Text(
                  _initials(task.subjectName),
                  style: _requestTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7A3E00),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Submitted by ${task.subjectName}',
                  style: _requestTextStyle(fontSize: 12, color: _requestMuted),
                ),
              ),
            ],
          ),
          if (task.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.summary,
              style: _requestTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (hasApprove && hasDeny && !hasForward)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: requestState.isSubmitting
                        ? null
                        : () =>
                              _handleAction(context, ref, ApproverAction.deny),
                    style: _outlinedDangerStyle(),
                    child: Text(
                      requestState.isSubmitting ? 'Submitting...' : 'Reject',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: requestState.isSubmitting
                        ? null
                        : () => _handleAction(
                            context,
                            ref,
                            ApproverAction.approve,
                          ),
                    child: Text(
                      requestState.isSubmitting ? 'Submitting...' : 'Approve',
                    ),
                  ),
                ),
              ],
            )
          else if (hasForward)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: requestState.isSubmitting
                        ? null
                        : () => _handleAction(
                            context,
                            ref,
                            ApproverAction.forward,
                          ),
                    child: Text(
                      requestState.isSubmitting ? 'Submitting...' : 'Forward',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ApprovalTaskDetailScreen(task: task),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _requestMuted,
                    side: const BorderSide(color: _requestBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View'),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ApprovalTaskDetailScreen(task: task),
                    ),
                  );
                },
                child: Text(
                  'View Details',
                  style: _requestTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _requestBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApprovalEmptyState extends StatelessWidget {
  const _ApprovalEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _requestBorder),
      ),
      child: Text(
        message,
        style: _requestTextStyle(fontSize: 13, color: _requestMuted),
      ),
    );
  }
}

class ApprovalTaskListScreen extends ConsumerStatefulWidget {
  const ApprovalTaskListScreen({super.key, required this.type});

  final ApproverRequestType type;

  @override
  ConsumerState<ApprovalTaskListScreen> createState() =>
      _ApprovalTaskListScreenState();
}

class _ApprovalTaskListScreenState
    extends ConsumerState<ApprovalTaskListScreen> {
  StaffRequestStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final items = switch (widget.type) {
      ApproverRequestType.leave => state.leaveApprovalTasks,
      ApproverRequestType.transfer => state.transferApprovalTasks,
    };
    final filteredItems = _filterStatus == null
        ? items
        : items.where((item) => item.status == _filterStatus).toList();

    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.type.pluralLabel,
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _StatusFilterTabs(
            selectedStatus: _filterStatus,
            onChanged: (value) => setState(() => _filterStatus = value),
          ),
          const SizedBox(height: 16),
          if (filteredItems.isEmpty)
            const _ApprovalEmptyState(
              message: 'No approval items match this status filter.',
            )
          else
            ...filteredItems.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ApprovalTaskCard(
                  task: task,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ApprovalTaskDetailScreen(task: task),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusFilterTabs extends StatelessWidget {
  const _StatusFilterTabs({
    required this.selectedStatus,
    required this.onChanged,
  });

  final StaffRequestStatus? selectedStatus;
  final ValueChanged<StaffRequestStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _requestBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RequestBoardToggleChip(
              label: 'All',
              selected: selectedStatus == null,
              onTap: () => onChanged(null),
              fontSize: 11,
              horizontalPadding: 6,
              verticalPadding: 9,
              scaleDownLabel: true,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _RequestBoardToggleChip(
              label: 'Pending',
              selected: selectedStatus == StaffRequestStatus.pending,
              onTap: () => onChanged(StaffRequestStatus.pending),
              fontSize: 11,
              horizontalPadding: 6,
              verticalPadding: 9,
              scaleDownLabel: true,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _RequestBoardToggleChip(
              label: 'Approved',
              selected: selectedStatus == StaffRequestStatus.approved,
              onTap: () => onChanged(StaffRequestStatus.approved),
              fontSize: 11,
              horizontalPadding: 6,
              verticalPadding: 9,
              scaleDownLabel: true,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _RequestBoardToggleChip(
              label: 'Rejected',
              selected: selectedStatus == StaffRequestStatus.rejected,
              onTap: () => onChanged(StaffRequestStatus.rejected),
              fontSize: 11,
              horizontalPadding: 6,
              verticalPadding: 9,
              scaleDownLabel: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalTaskCard extends StatelessWidget {
  const _ApprovalTaskCard({required this.task, required this.onTap});

  final ApprovalTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _requestCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _requestBorder),
        ),
        child: Row(
          children: [
            _SquareIcon(
              icon: _approvalIconFor(task.type),
              background: _approvalSoftFor(task.type),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.subjectName.isEmpty ? task.title : task.subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _requestTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.referenceNumber ?? _formatShortDate(task.submittedAt),
                    style: _requestTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _requestMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _requestTextStyle(
                      fontSize: 12,
                      color: _requestMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: task.status),
                const SizedBox(height: 12),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _requestMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ApprovalTaskDetailScreen extends ConsumerStatefulWidget {
  const ApprovalTaskDetailScreen({super.key, required this.task});

  final ApprovalTask task;

  @override
  ConsumerState<ApprovalTaskDetailScreen> createState() =>
      _ApprovalTaskDetailScreenState();
}

class _ApprovalTaskDetailScreenState
    extends ConsumerState<ApprovalTaskDetailScreen> {
  late ApprovalTask _task;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    Future<void>.microtask(_loadDetail);
  }

  Future<void> _loadDetail() async {
    if (widget.task.type != ApproverRequestType.leave) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final task = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .loadApprovalTaskDetail(widget.task);
      if (!mounted) return;
      setState(() {
        _task = task;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(ApproverAction action) async {
    final result = await showModalBottomSheet<_ApprovalActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApprovalActionSheet(task: _task, action: action),
    );

    if (result == null) return;

    try {
      final message = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .performApprovalAction(
            task: _task,
            action: action,
            comment: result.comment,
            startDate: result.startDate,
            endDate: result.endDate,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceAll('Exception: ', '');
      setState(() {
        _error = message;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffPortalAccessProvider);
    final requestState = ref.watch(staffRequestsViewModelProvider);
    final actions = _approvalDetailActionsFor(access, _task);
    final hasApprove = actions.contains(ApproverAction.approve);
    final hasDeny = actions.contains(ApproverAction.deny);
    final hasForward = actions.contains(ApproverAction.forward);

    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _task.type.label,
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _requestCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _requestBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _task.subjectName.isEmpty ? _task.title : _task.subjectName,
                  style: _requestTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _task.referenceNumber ?? 'Reference pending',
                  style: _requestTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _requestMuted,
                  ),
                ),
                const SizedBox(height: 16),
                _StatusBadge(status: _task.status),
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: _requestBlue,
                    backgroundColor: Color(0xFFEAF2FF),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _InlineBanner(message: _error!, onClose: _loadDetail),
                ],
                const SizedBox(height: 18),
                for (final field in _task.detailFields) ...[
                  _DetailRow(field: field),
                  const Divider(height: 24, color: _requestBorder),
                ],
                if (_task.attachmentName != null &&
                    _task.attachmentName!.trim().isNotEmpty)
                  _AttachmentCard(name: _task.attachmentName!),
              ],
            ),
          ),
          if (_task.commentHistory.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Workflow Comments',
              style: _requestTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ..._task.commentHistory.map(
              (comment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ApprovalCommentCard(comment: comment),
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Actions',
              style: _requestTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (hasApprove && hasDeny && !hasForward)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: requestState.isSubmitting
                          ? null
                          : () => _handleAction(ApproverAction.deny),
                      style: _outlinedDangerStyle(),
                      child: Text(
                        requestState.isSubmitting ? 'Submitting...' : 'Reject',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: _filledStyle(),
                      onPressed: requestState.isSubmitting
                          ? null
                          : () => _handleAction(ApproverAction.approve),
                      child: Text(
                        requestState.isSubmitting ? 'Submitting...' : 'Approve',
                      ),
                    ),
                  ),
                ],
              )
            else
              for (final action in actions) ...[
                SizedBox(
                  width: double.infinity,
                  child: action == ApproverAction.deny
                      ? OutlinedButton(
                          onPressed: requestState.isSubmitting
                              ? null
                              : () => _handleAction(action),
                          style: _outlinedDangerStyle(),
                          child: Text(
                            requestState.isSubmitting
                                ? 'Submitting...'
                                : action.label,
                          ),
                        )
                      : FilledButton(
                          style: _filledStyle(),
                          onPressed: requestState.isSubmitting
                              ? null
                              : () => _handleAction(action),
                          child: Text(
                            requestState.isSubmitting
                                ? 'Submitting...'
                                : action.label,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ],
      ),
    );
  }
}

class _ApprovalCommentCard extends StatelessWidget {
  const _ApprovalCommentCard({required this.comment});

  final ApprovalCommentRecord comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.stage,
            style: _requestTextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            comment.comment,
            style: _requestTextStyle(
              fontSize: 12,
              color: _requestMuted,
              height: 1.45,
            ),
          ),
          if ((comment.reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${comment.reason}',
              style: _requestTextStyle(fontSize: 12, color: _requestMuted),
            ),
          ],
          if ((comment.additionalComment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Additional note: ${comment.additionalComment}',
              style: _requestTextStyle(fontSize: 12, color: _requestMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApprovalActionResult {
  const _ApprovalActionResult({
    required this.comment,
    this.startDate,
    this.endDate,
  });

  final String comment;
  final DateTime? startDate;
  final DateTime? endDate;
}

class _ApprovalActionSheet extends StatefulWidget {
  const _ApprovalActionSheet({required this.task, required this.action});

  final ApprovalTask task;
  final ApproverAction action;

  @override
  State<_ApprovalActionSheet> createState() => _ApprovalActionSheetState();
}

class _ApprovalActionSheetState extends State<_ApprovalActionSheet> {
  final _commentController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _requiresDates =>
      widget.task.type == ApproverRequestType.leave &&
      widget.action == ApproverAction.approve;

  @override
  void initState() {
    super.initState();
    _startDate = widget.task.startDate ?? widget.task.proposedStartDate;
    _endDate = widget.task.endDate ?? widget.task.proposedEndDate;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment is required.')));
      return;
    }
    if (_requiresDates) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose approved start and end dates.')),
        );
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date cannot be earlier than start date.'),
          ),
        );
        return;
      }
    }

    Navigator.of(context).pop(
      _ApprovalActionResult(
        comment: comment,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${widget.action.label} ${widget.task.type.label}',
                style: _requestTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.task.subjectName,
                style: _requestTextStyle(fontSize: 12, color: _requestMuted),
              ),
              const SizedBox(height: 16),
              if (_requiresDates) ...[
                _DateInputField(
                  label: 'Approved Start Date',
                  value: _startDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _startDate,
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                _DateInputField(
                  label: 'Approved End Date',
                  value: _endDate,
                  onTap: () async {
                    final picked = await _pickDate(context, initial: _endDate);
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                ),
              ],
              _AppTextField(
                label: 'Comment',
                controller: _commentController,
                hintText: 'Enter comment',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: widget.action == ApproverAction.deny
                    ? OutlinedButton(
                        onPressed: _submit,
                        style: _outlinedDangerStyle(),
                        child: Text(widget.action.label),
                      )
                    : FilledButton(
                        style: _filledStyle(),
                        onPressed: _submit,
                        child: Text(widget.action.label),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestCategoryListScreen extends ConsumerStatefulWidget {
  const RequestCategoryListScreen({
    super.key,
    required this.type,
    this.initialStatusFilter,
  });

  final StaffRequestType type;
  final StaffRequestStatus? initialStatusFilter;

  @override
  ConsumerState<RequestCategoryListScreen> createState() =>
      _RequestCategoryListScreenState();
}

class _RequestCategoryListScreenState
    extends ConsumerState<RequestCategoryListScreen> {
  StaffRequestStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _filterStatus = widget.initialStatusFilter;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final items = state.recordsFor(widget.type);
    final filteredItems = _filterStatus == null
        ? items
        : items.where((item) => item.status == _filterStatus).toList();

    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.type.pluralLabel,
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: widget.type == StaffRequestType.sickLeave
          ? null
          : FloatingActionButton(
              backgroundColor: _requestBlue,
              mini: true,
              onPressed: () => openRequestFormScreen(context, widget.type),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _StatusFilterTabs(
            selectedStatus: _filterStatus,
            onChanged: (value) => setState(() => _filterStatus = value),
          ),
          const SizedBox(height: 16),
          if (filteredItems.isEmpty)
            const _ApprovalEmptyState(
              message: 'No requests match this status filter.',
            )
          else
            ...filteredItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestListCard(
                  request: item,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RequestDetailScreen(request: item),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.request});

  final StaffRequestRecord request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestState = ref.watch(staffRequestsViewModelProvider);
    final currentRequest =
        requestState.records.firstWhereOrNull(
          (item) => item.id == request.id,
        ) ??
        request;
    final user = ref.watch(authViewModelProvider).user;
    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _detailTitle(currentRequest.type),
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _DetailSectionCard(
            title: _sectionTitleFor(currentRequest.type),
            child: Column(
              children: _detailRowsForRequest(currentRequest)
                  .map(
                    (field) => Column(
                      children: [
                        _DetailRow(field: field),
                        const Divider(height: 24, color: _requestBorder),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _DetailSectionCard(
            title: _staffSectionTitleFor(currentRequest.type),
            child: Column(
              children: [
                _DetailRow(
                  field: RequestDetailField(
                    label: 'Name',
                    value: user?.fullName.trim().isNotEmpty == true
                        ? user!.fullName.trim()
                        : 'Staff member',
                  ),
                ),
                const Divider(height: 24, color: _requestBorder),
                _DetailRow(
                  field: RequestDetailField(
                    label: 'Employee ID',
                    value: user?.userId.trim().isNotEmpty == true
                        ? user!.userId.trim()
                        : 'Pending',
                  ),
                ),
                const Divider(height: 24, color: _requestBorder),
                _DetailRow(
                  field: RequestDetailField(
                    label: 'Facility',
                    value: user?.workingStationName.trim().isNotEmpty == true
                        ? user!.workingStationName.trim()
                        : 'Not available',
                  ),
                ),
              ],
            ),
          ),
          if (currentRequest.attachmentName != null &&
              currentRequest.attachmentName!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _DetailSectionCard(
              title: 'Attachments',
              child: _AttachmentCard(name: currentRequest.attachmentName!),
            ),
          ],
          const SizedBox(height: 14),
          _DetailSectionCard(
            title: 'Approval Timeline',
            child: Column(
              children: _timelineItemsForRequest(currentRequest)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TimelineTile(item: item),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (currentRequest.type == StaffRequestType.activity) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: _filledStyle(),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Activity report export is not available yet.',
                      ),
                    ),
                  );
                },
                child: const Text('Download Activity Report'),
              ),
            ),
          ] else if (_canWithdrawRequest(currentRequest)) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: _filledStyle(),
                onPressed: requestState.isSubmitting
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Withdraw request'),
                            content: Text(
                              _withdrawPromptFor(currentRequest.type),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Keep Request'),
                              ),
                              FilledButton(
                                style: _filledStyle(),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Withdraw'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true || !context.mounted) return;

                        final updated = await ref
                            .read(staffRequestsViewModelProvider.notifier)
                            .withdrawRequest(currentRequest);
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${updated.type.label} request marked as withdrawn.',
                            ),
                          ),
                        );
                      },
                child: Text(
                  requestState.isSubmitting
                      ? 'Withdrawing...'
                      : _detailActionLabel(currentRequest.type),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _detailTitle(StaffRequestType type) {
    switch (type) {
      case StaffRequestType.activity:
        return 'Activity Details';
      case StaffRequestType.leave:
        return 'Leave Request Details';
      case StaffRequestType.transfer:
        return 'Transfer Request Details';
      case StaffRequestType.loan:
        return 'Loan Application Details';
      case StaffRequestType.sickLeave:
        return 'Sick Leave Details';
    }
  }
}

class RequestSubmissionSuccessScreen extends StatelessWidget {
  const RequestSubmissionSuccessScreen({super.key, required this.request});

  final StaffRequestRecord request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF5),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _requestBlue,
                  size: 54,
                ),
                const SizedBox(height: 14),
                Text(
                  '${request.type.label} Request Submitted',
                  textAlign: TextAlign.center,
                  style: _requestTextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Request submitted successfully.\nReference Number ${request.referenceNumber ?? 'Pending'}',
                  textAlign: TextAlign.center,
                  style: _requestTextStyle(
                    fontSize: 13,
                    color: _requestMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => RequestDetailScreen(request: request),
                        ),
                      );
                    },
                    child: const Text('View Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LeaveRequestFormScreen extends ConsumerStatefulWidget {
  const LeaveRequestFormScreen({super.key});

  @override
  ConsumerState<LeaveRequestFormScreen> createState() =>
      _LeaveRequestFormScreenState();
}

class _LeaveRequestFormScreenState
    extends ConsumerState<LeaveRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _numberOfDaysController = TextEditingController();
  final _placeToTravelController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  String? _leaveTypeId;
  String? _representativeId;

  @override
  void dispose() {
    _contactController.dispose();
    _numberOfDaysController.dispose();
    _placeToTravelController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final selectedLeaveType = state.leaveTypes.firstWhereOrNull(
      (item) => item.id == _leaveTypeId,
    );

    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Apply Leave',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _AppDropdownField(
                  label: 'Leave Type',
                  value: _leaveTypeId,
                  hintText: 'Select',
                  items: state.leaveTypes,
                  onChanged: (value) {
                    setState(() {
                      _leaveTypeId = value;
                      final nextType = state.leaveTypes.firstWhereOrNull(
                        (item) => item.id == value,
                      );
                      if (nextType?.requiresDayCount != true) {
                        _numberOfDaysController.clear();
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a leave type' : null,
                ),
                _DateInputField(
                  label: 'Start Date',
                  value: _startDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _startDate,
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                if (selectedLeaveType?.requiresDayCount == true)
                  _AppTextField(
                    label: 'Number of Days',
                    controller: _numberOfDaysController,
                    hintText: 'Input Number of Days',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final normalized = (value ?? '').trim();
                      if (normalized.isEmpty) {
                        return 'This field is required';
                      }
                      final days = int.tryParse(normalized);
                      if (days == null || days <= 0) {
                        return 'Enter a valid number of days';
                      }
                      return null;
                    },
                  ),
                _AppTextField(
                  label: 'Contact on Leave',
                  controller: _contactController,
                  hintText: 'Input Number',
                  keyboardType: TextInputType.phone,
                ),
                if (selectedLeaveType?.requiresAttachment == true)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: _InlineErrorText(
                      message:
                          'This leave type requires a PDF attachment. Submit it from the web portal for now.',
                    ),
                  ),
                _AppDropdownField(
                  label: 'Representative',
                  value: _representativeId,
                  hintText: 'Input Name',
                  items: state.representatives,
                  onChanged: (value) =>
                      setState(() => _representativeId = value),
                ),
                _AppTextField(
                  label: 'Place To Travel',
                  controller: _placeToTravelController,
                  hintText: 'Optional',
                  validator: (_) => null,
                ),
                _AppTextField(
                  label: 'Reason for Leave',
                  controller: _reasonController,
                  hintText: 'Optional',
                  maxLines: 5,
                  validator: (_) => null,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _InlineErrorText(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: state.isSubmitting ? null : _submit,
                    child: Text(
                      state.isSubmitting
                          ? 'Submitting...'
                          : 'Submit Leave Request',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      _showError('Choose a start date.');
      return;
    }

    final state = ref.read(staffRequestsViewModelProvider);
    final leaveType = state.leaveTypes.firstWhereOrNull(
      (item) => item.id == _leaveTypeId,
    );
    if (leaveType == null) {
      _showError('Leave types are unavailable. Refresh and try again.');
      return;
    }
    if (leaveType.requiresAttachment) {
      _showError(
        'This leave type requires a PDF attachment. Submit it from the web portal for now.',
      );
      return;
    }

    int? numberOfDays;
    if (leaveType.requiresDayCount) {
      numberOfDays = int.tryParse(_numberOfDaysController.text.trim());
      if (numberOfDays == null || numberOfDays <= 0) {
        _showError('Enter a valid number of days.');
        return;
      }
    }

    final representative = state.representatives.firstWhereOrNull(
      (item) => item.id == _representativeId,
    );
    final placeToTravel = _placeToTravelController.text.trim();

    try {
      final record = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .submitLeaveRequest(
            LeaveRequestDraft(
              leaveTypeId: leaveType.id,
              leaveTypeLabel: leaveType.label,
              startDate: _startDate!,
              contactOnLeave: _contactController.text.trim(),
              reason: _reasonController.text.trim(),
              numberOfDays: numberOfDays,
              representativeId: representative?.id,
              representativeLabel: representative?.label,
              placeToTravel: placeToTravel.isEmpty ? null : placeToTravel,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RequestSubmissionSuccessScreen(request: record),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class TransferRequestFormScreen extends ConsumerStatefulWidget {
  const TransferRequestFormScreen({super.key});

  @override
  ConsumerState<TransferRequestFormScreen> createState() =>
      _TransferRequestFormScreenState();
}

class _TransferRequestFormScreenState
    extends ConsumerState<TransferRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonTextController = TextEditingController();
  String? _facilityId;
  String? _departmentId;
  String? _reasonId;
  DateTime? _preferredDate;

  @override
  void dispose() {
    _reasonTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final departments = state.departmentsByFacilityId[_facilityId] ?? const [];

    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Request Transfer',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _AppDropdownField(
                  label: 'Preferred Facility',
                  value: _facilityId,
                  hintText: 'Select',
                  items: state.facilities,
                  onChanged: (value) {
                    setState(() {
                      _facilityId = value;
                      _departmentId = null;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a facility' : null,
                ),
                _AppDropdownField(
                  label: 'Preferred Department',
                  value: _departmentId,
                  hintText: 'Select',
                  items: departments,
                  onChanged: (value) => setState(() => _departmentId = value),
                ),
                _AppDropdownField(
                  label: 'Reason for Transfer',
                  value: _reasonId,
                  hintText: 'Select',
                  items: state.transferReasons,
                  onChanged: (value) => setState(() => _reasonId = value),
                  validator: (value) =>
                      value == null ? 'Select a transfer reason' : null,
                ),
                _AppTextField(
                  label: 'Reason for Transfer',
                  controller: _reasonTextController,
                  hintText: 'Input',
                  maxLines: 5,
                ),
                _DateInputField(
                  label: 'Preferred Transfer Date',
                  value: _preferredDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _preferredDate,
                    );
                    if (picked != null) {
                      setState(() => _preferredDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 10),
                const _UploadPlaceholder(),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _InlineErrorText(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: state.isSubmitting ? null : _submit,
                    child: Text(
                      state.isSubmitting
                          ? 'Submitting...'
                          : 'Submit Transfer Request',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a preferred transfer date.')),
      );
      return;
    }

    final state = ref.read(staffRequestsViewModelProvider);
    final facility = state.facilities.firstWhereOrNull(
      (item) => item.id == _facilityId,
    );
    final reason = state.transferReasons.firstWhereOrNull(
      (item) => item.id == _reasonId,
    );
    if (facility == null || reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transfer options are unavailable. Refresh and try again.',
          ),
        ),
      );
      return;
    }
    final department = state.departmentsByFacilityId[_facilityId]
        ?.firstWhereOrNull((item) => item.id == _departmentId);

    try {
      final record = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .submitTransferRequest(
            TransferRequestDraft(
              facilityId: facility.id,
              facilityLabel: facility.label,
              reasonId: reason.id,
              reasonLabel: reason.label,
              reasonText: _reasonTextController.text.trim(),
              preferredTransferDate: _preferredDate!,
              departmentId: department?.id,
              departmentLabel: department?.label,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RequestSubmissionSuccessScreen(request: record),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    }
  }
}

class ActivityRequestFormScreen extends ConsumerStatefulWidget {
  const ActivityRequestFormScreen({super.key});

  @override
  ConsumerState<ActivityRequestFormScreen> createState() =>
      _ActivityRequestFormScreenState();
}

class _ActivityRequestFormScreenState
    extends ConsumerState<ActivityRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _category;
  String? _scope;
  String _participants = 'Individual Activity';

  static const _categories = ['Travel', 'Workshop', 'Outreach', 'Meeting'];

  static const _scopes = [
    'Within Facility',
    'Within District',
    'Within Zanzibar',
    'Mainland Tanzania',
    'International',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Register Activity',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _AppTextField(
                  label: 'Activity Title',
                  controller: _titleController,
                  hintText: 'Input',
                ),
                _SimpleDropdownField(
                  label: 'Activity Category',
                  value: _category,
                  hintText: 'Select',
                  items: _categories,
                  onChanged: (value) => setState(() => _category = value),
                ),
                _SimpleDropdownField(
                  label: 'Activity Scope',
                  value: _scope,
                  hintText: 'Select',
                  items: _scopes,
                  onChanged: (value) => setState(() => _scope = value),
                ),
                _AppTextField(
                  label: 'Activity Location',
                  controller: _locationController,
                  hintText: 'Input',
                ),
                _DateInputField(
                  label: 'Start Date',
                  value: _startDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _startDate,
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                _DateInputField(
                  label: 'End Date',
                  value: _endDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _endDate ?? _startDate,
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                ),
                _ParticipantsSelector(
                  value: _participants,
                  onChanged: (value) => setState(() => _participants = value),
                ),
                _AppTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  hintText: 'Input',
                  maxLines: 5,
                ),
                const SizedBox(height: 10),
                const _UploadPlaceholder(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: state.isSubmitting ? null : _submit,
                    child: Text(
                      state.isSubmitting ? 'Submitting...' : 'Submit Activity',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null ||
        _endDate == null ||
        _category == null ||
        _scope == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields.')),
      );
      return;
    }

    final record = await ref
        .read(staffRequestsViewModelProvider.notifier)
        .submitActivityRequest(
          ActivityRequestDraft(
            activityTitle: _titleController.text.trim(),
            category: _category!,
            scope: _scope!,
            location: _locationController.text.trim(),
            startDate: _startDate!,
            endDate: _endDate!,
            participants: _participants,
            description: _descriptionController.text.trim(),
          ),
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RequestSubmissionSuccessScreen(request: record),
      ),
    );
  }
}

class LoanRequestFormScreen extends ConsumerStatefulWidget {
  const LoanRequestFormScreen({super.key});

  @override
  ConsumerState<LoanRequestFormScreen> createState() =>
      _LoanRequestFormScreenState();
}

class _LoanRequestFormScreenState extends ConsumerState<LoanRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _salaryController = TextEditingController();
  final _purposeController = TextEditingController();
  String? _loanType;
  String? _employerStatus;
  String? _repaymentPeriod;

  static const _loanTypes = [
    'Soft Development Loan',
    'Emergency Loan',
    'School Fees Loan',
  ];

  static const _employerStatuses = [
    'Permanent Staff',
    'Contract Staff',
    'Probation',
  ];

  static const _repaymentOptions = [
    '6 Months',
    '12 Months',
    '18 Months',
    '24 Months',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _salaryController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Apply for Loan',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _SimpleDropdownField(
                  label: 'Loan Type',
                  value: _loanType,
                  hintText: 'Select',
                  items: _loanTypes,
                  onChanged: (value) => setState(() => _loanType = value),
                ),
                _AppTextField(
                  label: 'Requested Amount',
                  controller: _amountController,
                  hintText: 'Input Number',
                  keyboardType: TextInputType.number,
                ),
                _SimpleDropdownField(
                  label: 'Employer Status',
                  value: _employerStatus,
                  hintText: 'Select',
                  items: _employerStatuses,
                  onChanged: (value) => setState(() => _employerStatus = value),
                ),
                _AppTextField(
                  label: 'Monthly Salary',
                  controller: _salaryController,
                  hintText: 'Input Number',
                  keyboardType: TextInputType.number,
                ),
                _SimpleDropdownField(
                  label: 'Repayment Period',
                  value: _repaymentPeriod,
                  hintText: 'Select',
                  items: _repaymentOptions,
                  onChanged: (value) =>
                      setState(() => _repaymentPeriod = value),
                ),
                _AppTextField(
                  label: 'Purpose of Loan',
                  controller: _purposeController,
                  hintText: 'Input',
                  maxLines: 5,
                ),
                const SizedBox(height: 10),
                const _UploadPlaceholder(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: state.isSubmitting ? null : _submit,
                    child: Text(
                      state.isSubmitting
                          ? 'Submitting...'
                          : 'Submit Loan Application',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loanType == null ||
        _employerStatus == null ||
        _repaymentPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields.')),
      );
      return;
    }

    final record = await ref
        .read(staffRequestsViewModelProvider.notifier)
        .submitLoanRequest(
          LoanRequestDraft(
            loanType: _loanType!,
            requestedAmount: _amountController.text.trim(),
            employerStatus: _employerStatus!,
            monthlySalary: _salaryController.text.trim(),
            repaymentMonths: _repaymentPeriod!,
            purpose: _purposeController.text.trim(),
          ),
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RequestSubmissionSuccessScreen(request: record),
      ),
    );
  }
}

class _NewRequestSheet extends StatelessWidget {
  const _NewRequestSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            _ComposerOptionTile(
              title: 'Apply Leave',
              onTap: () {
                Navigator.of(context).pop();
                openRequestFormScreen(parentContext, StaffRequestType.leave);
              },
            ),
            const SizedBox(height: 10),
            _ComposerOptionTile(
              title: 'Request Transfer',
              onTap: () {
                Navigator.of(context).pop();
                openRequestFormScreen(parentContext, StaffRequestType.transfer);
              },
            ),
            const SizedBox(height: 10),
            _ComposerOptionTile(
              title: 'Register Activity',
              onTap: () {
                Navigator.of(context).pop();
                openRequestFormScreen(parentContext, StaffRequestType.activity);
              },
            ),
            const SizedBox(height: 10),
            _ComposerOptionTile(
              title: 'Apply Loan',
              onTap: () {
                Navigator.of(context).pop();
                openRequestFormScreen(parentContext, StaffRequestType.loan);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestOverviewSection extends StatelessWidget {
  const _RequestOverviewSection({
    required this.type,
    required this.count,
    required this.approvedCount,
    required this.pendingCount,
    required this.onTap,
  });

  final StaffRequestType type;
  final int count;
  final int approvedCount;
  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _requestCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SquareIcon(icon: _iconFor(type), background: _softFor(type)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type.pluralLabel,
                  style: _requestTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onTap,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _requestMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RequestStatTile(
                  label: 'Total Requests',
                  value: '$count',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RequestStatTile(
                  label: 'Approved',
                  value: '$approvedCount',
                  accent: const Color(0xFF12B76A),
                  soft: const Color(0xFFEAFBF1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RequestStatTile(
                  label: 'Pending',
                  value: '$pendingCount',
                  accent: const Color(0xFF3BA1FF),
                  soft: const Color(0xFFEAF4FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onTap,
              child: Text(
                _viewLabelFor(type),
                style: _requestTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _requestBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestStatTile extends StatelessWidget {
  const _RequestStatTile({
    required this.label,
    required this.value,
    this.accent = _requestBlue,
    this.soft = const Color(0xFFEAF2FF),
  });

  final String label;
  final String value;
  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: _requestTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _requestTextStyle(fontSize: 10, color: _requestMuted),
          ),
        ],
      ),
    );
  }
}

class _RequestListCard extends StatelessWidget {
  const _RequestListCard({required this.request, required this.onTap});

  final StaffRequestRecord request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _requestCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _requestTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: _requestMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _requestDateRange(request),
                style: _requestTextStyle(fontSize: 12, color: _requestMuted),
              ),
            ],
          ),
          if (request.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _requestTextStyle(
                fontSize: 12,
                color: _requestText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 88,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _requestMuted,
                  side: const BorderSide(color: _requestBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'View',
                  style: _requestTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _requestMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: _requestTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF98A2B3),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TimelineItem {
  const _TimelineItem({
    required this.label,
    required this.value,
    required this.status,
    this.subtitle,
  });

  final String label;
  final String value;
  final StaffRequestStatus status;
  final String? subtitle;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item});

  final _TimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: _statusColor(item.status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: _requestTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: _requestTextStyle(fontSize: 12, color: _requestMuted),
              ),
              if ((item.subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.subtitle!,
                  style: _requestTextStyle(fontSize: 12, color: _requestMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.field});

  final RequestDetailField field;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            field.label,
            style: _requestTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _requestMuted,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: field.status == null
              ? Text(
                  field.value,
                  textAlign: TextAlign.right,
                  style: _requestTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Align(
                  alignment: Alignment.centerRight,
                  child: _StatusBadge(status: field.status!),
                ),
        ),
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _requestBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded, color: _requestBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: _requestTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final StaffRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusSoft(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: _requestTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _statusColor(status),
        ),
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon, required this.background});

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: _requestBlue, size: 20),
    );
  }
}

class _ComposerOptionTile extends StatelessWidget {
  const _ComposerOptionTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _requestBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: _requestTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _requestMuted),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsSelector extends StatelessWidget {
  const _ParticipantsSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: _requestTextStyle(fontSize: 12, color: _requestMuted),
            ),
            const SizedBox(height: 8),
            _ParticipantOption(
              label: 'Individual Activity',
              selected: value == 'Individual Activity',
              onTap: () => onChanged('Individual Activity'),
            ),
            const SizedBox(height: 8),
            _ParticipantOption(
              label: 'Group Activity',
              selected: value == 'Group Activity',
              onTap: () => onChanged('Group Activity'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: _requestMuted),
          const SizedBox(height: 10),
          Text(
            'Upload Documents',
            style: _requestTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '.JPEG, PNG, PDF and MP4 formats, up to 50 MB.',
            textAlign: TextAlign.center,
            style: _requestTextStyle(fontSize: 11, color: _requestMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _requestMuted,
              side: const BorderSide(color: _requestBorder),
            ),
            child: const Text('Browse File'),
          ),
        ],
      ),
    );
  }
}

class _ParticipantOption extends StatelessWidget {
  const _ParticipantOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? _requestBlue : _requestMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: _requestTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _requestTextStyle(fontSize: 12, color: _requestMuted),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator:
                validator ??
                (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
            style: _requestTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(hintText),
          ),
        ],
      ),
    );
  }
}

class _AppDropdownField extends StatelessWidget {
  const _AppDropdownField({
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String? value;
  final String hintText;
  final List<RequestLookupOption> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _requestTextStyle(fontSize: 12, color: _requestMuted),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('$label::$value'),
            initialValue: value,
            isExpanded: true,
            decoration: _inputDecoration(hintText),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      item.label,
                      style: _requestTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }
}

class _SimpleDropdownField extends StatelessWidget {
  const _SimpleDropdownField({
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _requestTextStyle(fontSize: 12, color: _requestMuted),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('$label::$value'),
            initialValue: value,
            isExpanded: true,
            decoration: _inputDecoration(hintText),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: _requestTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: (selected) =>
                selected == null ? 'This field is required' : null,
          ),
        ],
      ),
    );
  }
}

class _DateInputField extends StatelessWidget {
  const _DateInputField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _requestTextStyle(fontSize: 12, color: _requestMuted),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: _inputDecoration('DD / MM / YYYY').copyWith(
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: _requestMuted,
                ),
              ),
              child: Text(
                value == null ? 'DD / MM / YYYY' : _formatInputDate(value!),
                style: _requestTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value == null ? const Color(0xFF9CA3AF) : _requestText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE67E22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: _requestTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9A5518),
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorText extends StatelessWidget {
  const _InlineErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: _requestTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFD14343),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: _requestTextStyle(fontSize: 13, color: const Color(0xFF9CA3AF)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _requestBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _requestBlue),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD14343)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD14343)),
    ),
  );
}

ButtonStyle _filledStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _requestBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: _requestTextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );
}

ButtonStyle _outlinedDangerStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFFF04438),
    side: const BorderSide(color: Color(0xFFFDA29B)),
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: _requestTextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );
}

TextStyle _requestTextStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = _requestText,
  double? height,
}) {
  return GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

Future<DateTime?> _pickDate(BuildContext context, {DateTime? initial}) async {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
  );
}

String _formatInputDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')} / ${value.month.toString().padLeft(2, '0')} / ${value.year.toString().padLeft(4, '0')}';
}

String _formatShortDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')} ${_monthShort(value.month)} ${value.year}';
}

String _monthShort(int month) {
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
  return months[month - 1];
}

String _viewLabelFor(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.activity:
      return 'View Activities';
    case StaffRequestType.leave:
      return 'View Leave';
    case StaffRequestType.transfer:
      return 'View Transfers';
    case StaffRequestType.loan:
      return 'View Loans';
    case StaffRequestType.sickLeave:
      return 'View Sick Leave';
  }
}

String _requestDateRange(StaffRequestRecord request) {
  if (request.startDate != null && request.endDate != null) {
    return '${_formatShortDate(request.startDate!)} - ${_formatShortDate(request.endDate!)}';
  }
  if (request.startDate != null) {
    return _formatShortDate(request.startDate!);
  }
  return _formatShortDate(request.submittedAt);
}

String _sectionTitleFor(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.activity:
      return 'Activity Information';
    case StaffRequestType.leave:
      return 'Request Information';
    case StaffRequestType.transfer:
      return 'Transfer Information';
    case StaffRequestType.loan:
      return 'Loan Information';
    case StaffRequestType.sickLeave:
      return 'Submission Information';
  }
}

String _staffSectionTitleFor(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.activity:
      return 'Staff Information';
    case StaffRequestType.leave:
      return 'Staff Information';
    case StaffRequestType.transfer:
      return 'Staff Information';
    case StaffRequestType.loan:
      return 'Staff Information';
    case StaffRequestType.sickLeave:
      return 'Staff Information';
  }
}

List<RequestDetailField> _detailRowsForRequest(StaffRequestRecord request) {
  final fields = [...request.detailFields];
  if (request.startDate != null &&
      !fields.any((field) => field.label.toLowerCase().contains('start'))) {
    fields.insert(
      0,
      RequestDetailField(
        label: 'Start Date',
        value: _formatShortDate(request.startDate!),
      ),
    );
  }
  if (request.endDate != null &&
      !fields.any((field) => field.label.toLowerCase().contains('end'))) {
    fields.insert(
      fields.isEmpty ? 0 : 1,
      RequestDetailField(
        label: 'End Date',
        value: _formatShortDate(request.endDate!),
      ),
    );
  }
  if (!fields.any((field) => field.label.toLowerCase() == 'status')) {
    fields.add(
      RequestDetailField(
        label: 'Status',
        value: request.status.label,
        status: request.status,
      ),
    );
  }
  return fields;
}

List<_TimelineItem> _timelineItemsForRequest(StaffRequestRecord request) {
  final items = <_TimelineItem>[
    _TimelineItem(
      label: 'Application Submitted',
      value: _formatShortDate(request.submittedAt),
      status: StaffRequestStatus.approved,
      subtitle: request.referenceNumber ?? 'Reference pending',
    ),
  ];

  items.add(
    _TimelineItem(
      label: request.stageLabel?.trim().isNotEmpty == true
          ? request.stageLabel!
          : 'Supervisor Review',
      value: request.startDate != null
          ? _formatShortDate(request.startDate!)
          : _formatShortDate(request.submittedAt),
      status: request.status == StaffRequestStatus.rejected
          ? StaffRequestStatus.rejected
          : StaffRequestStatus.pending,
    ),
  );

  items.add(
    _TimelineItem(
      label: 'Final Decision',
      value: request.endDate != null
          ? _formatShortDate(request.endDate!)
          : _formatShortDate(request.submittedAt),
      status: request.status,
    ),
  );

  return items;
}

String _initials(String value) {
  final parts = value
      .split(' ')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'S';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

List<ApproverAction> _approvalActionsFor(
  StaffPortalAccess access,
  ApprovalTask task,
) {
  final isOpen = task.status.isOpen;
  switch (task.type) {
    case ApproverRequestType.leave:
      return [
        if (isOpen && access.canForwardLeave && !task.isFinalStage)
          ApproverAction.forward,
        if (isOpen && access.canApproveLeave && task.isFinalStage)
          ApproverAction.approve,
        if (isOpen && access.canDenyLeave && task.isFinalStage)
          ApproverAction.deny,
      ];
    case ApproverRequestType.transfer:
      return [
        if (isOpen && access.canForwardTransfer && !task.isFinalStage)
          ApproverAction.forward,
        if (isOpen && access.canApproveTransfer && task.isFinalStage)
          ApproverAction.approve,
        if (isOpen && access.canDenyTransfer && task.isFinalStage)
          ApproverAction.deny,
      ];
  }
}

List<ApproverAction> _approvalDetailActionsFor(
  StaffPortalAccess access,
  ApprovalTask task,
) {
  final isOpen = task.status.isOpen;
  switch (task.type) {
    case ApproverRequestType.leave:
      final canApprove = access.canApproveLeave || access.canForwardLeave;
      final canDeny = access.canDenyLeave || access.canForwardLeave;
      return [
        if (isOpen && canDeny) ApproverAction.deny,
        if (isOpen && canApprove) ApproverAction.approve,
      ];
    case ApproverRequestType.transfer:
      return _approvalActionsFor(access, task);
  }
}

IconData _approvalIconFor(ApproverRequestType type) {
  switch (type) {
    case ApproverRequestType.leave:
      return Icons.event_available_rounded;
    case ApproverRequestType.transfer:
      return Icons.compare_arrows_rounded;
  }
}

Color _approvalSoftFor(ApproverRequestType type) {
  switch (type) {
    case ApproverRequestType.leave:
      return const Color(0xFFEAFBF1);
    case ApproverRequestType.transfer:
      return const Color(0xFFFFF2E8);
  }
}

bool _canWithdrawRequest(StaffRequestRecord request) {
  return request.status.isOpen &&
      request.type != StaffRequestType.activity &&
      request.type != StaffRequestType.sickLeave;
}

String _detailActionLabel(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.leave:
      return 'Withdraw Request and Re-submit Leave Request';
    case StaffRequestType.transfer:
      return 'Withdraw Request and Re-submit Transfer Request';
    case StaffRequestType.loan:
      return 'Withdraw Loan Application';
    case StaffRequestType.activity:
      return 'Download Activity Report';
    case StaffRequestType.sickLeave:
      return 'View Submission';
  }
}

String _withdrawPromptFor(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.leave:
      return 'This will mark the leave request as withdrawn so you can submit a new leave request later.';
    case StaffRequestType.transfer:
      return 'This will mark the transfer request as withdrawn so you can submit a new transfer request later.';
    case StaffRequestType.loan:
      return 'This will mark the loan application as withdrawn.';
    case StaffRequestType.activity:
    case StaffRequestType.sickLeave:
      return 'This request cannot be withdrawn.';
  }
}

IconData _iconFor(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.activity:
      return Icons.assignment_turned_in_outlined;
    case StaffRequestType.leave:
      return Icons.event_available_rounded;
    case StaffRequestType.transfer:
      return Icons.compare_arrows_rounded;
    case StaffRequestType.loan:
      return Icons.account_balance_wallet_outlined;
    case StaffRequestType.sickLeave:
      return Icons.medical_services_outlined;
  }
}

Color _softFor(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.activity:
      return const Color(0xFFEAF2FF);
    case StaffRequestType.leave:
      return const Color(0xFFEAFBF1);
    case StaffRequestType.transfer:
      return const Color(0xFFFFF2E8);
    case StaffRequestType.loan:
      return const Color(0xFFF3ECFF);
    case StaffRequestType.sickLeave:
      return const Color(0xFFFFEEF1);
  }
}

Color _statusColor(StaffRequestStatus status) {
  switch (status) {
    case StaffRequestStatus.pending:
      return const Color(0xFFE67E22);
    case StaffRequestStatus.approved:
      return const Color(0xFF12B76A);
    case StaffRequestStatus.rejected:
      return const Color(0xFFD14343);
    case StaffRequestStatus.withdrawn:
      return const Color(0xFF64748B);
    case StaffRequestStatus.submitted:
      return _requestBlue;
  }
}

Color _statusSoft(StaffRequestStatus status) {
  switch (status) {
    case StaffRequestStatus.pending:
      return const Color(0xFFFFF2E8);
    case StaffRequestStatus.approved:
      return const Color(0xFFEAFBF1);
    case StaffRequestStatus.rejected:
      return const Color(0xFFFFEEF1);
    case StaffRequestStatus.withdrawn:
      return const Color(0xFFF1F5F9);
    case StaffRequestStatus.submitted:
      return const Color(0xFFEAF2FF);
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
