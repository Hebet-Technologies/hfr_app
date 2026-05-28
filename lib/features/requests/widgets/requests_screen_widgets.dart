part of '../views/requests_screen.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
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
        _error = listLoadErrorMessage(error);
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
      final message = friendlyErrorMessage(error);
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
                  _InlineBanner(
                    message: _error!,
                    onClose: () => setState(() => _error = null),
                    actionLabel: 'Retry',
                    onAction: _loadDetail,
                  ),
                ],
                const SizedBox(height: 18),
                for (final field in _task.detailFields) ...[
                  _DetailRow(field: field),
                  const Divider(height: 24, color: _requestBorder),
                ],
                if (_documentUrlFromAttachment(_task.attachmentName) != null)
                  _AttachmentCard(
                    url: _documentUrlFromAttachment(_task.attachmentName)!,
                  ),
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
        actions: [
          if (widget.type == StaffRequestType.leave)
            IconButton(
              tooltip: 'Leave history',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LeaveHistoryScreen(),
                ),
              ),
              icon: const Icon(Icons.history_rounded),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'request-list-${widget.type.name}-fab',
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

class LeaveHistoryScreen extends ConsumerStatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  ConsumerState<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends ConsumerState<LeaveHistoryScreen> {
  List<StaffRequestRecord> _items = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .fetchLeaveHistory();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = listLoadErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Leave History',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: _requestBlue,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_error != null) ...[
              _InlineBanner(
                message: _error!,
                onClose: () => setState(() => _error = null),
                actionLabel: 'Retry',
                onAction: _load,
              ),
              const SizedBox(height: 14),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 72),
                child: Center(
                  child: CircularProgressIndicator(color: _requestBlue),
                ),
              )
            else if (_items.isEmpty)
              const _ApprovalEmptyState(message: 'No leave history found.')
            else
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RequestListCard(
                    request: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RequestDetailScreen(request: item),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
          if (_documentUrlFromAttachment(currentRequest.attachmentName) !=
              null) ...[
            const SizedBox(height: 14),
            _DetailSectionCard(
              title: 'Attachments',
              child: _AttachmentCard(
                url: _documentUrlFromAttachment(currentRequest.attachmentName)!,
              ),
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
          if (currentRequest.type == StaffRequestType.leave) ...[
            const SizedBox(height: 18),
            _LeaveDetailActions(request: currentRequest),
          ],
          if (currentRequest.type == StaffRequestType.transfer &&
              currentRequest.status ==
                  StaffRequestStatus.attachmentReturned) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: _filledStyle(),
                onPressed: requestState.isSubmitting
                    ? null
                    : () => _openTransferCorrectionSheet(
                        context,
                        ref,
                        currentRequest,
                      ),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(
                  requestState.isSubmitting
                      ? 'Uploading...'
                      : 'Upload Attachments and Resubmit',
                ),
              ),
            ),
          ],
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
                            title: Text(
                              currentRequest.type == StaffRequestType.transfer
                                  ? 'Delete transfer request'
                                  : 'Withdraw request',
                            ),
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
                                child: Text(
                                  currentRequest.type ==
                                          StaffRequestType.transfer
                                      ? 'Delete'
                                      : 'Withdraw',
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true || !context.mounted) return;

                        StaffRequestRecord updated;
                        try {
                          updated = await ref
                              .read(staffRequestsViewModelProvider.notifier)
                              .withdrawRequest(currentRequest);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(friendlyErrorMessage(error)),
                            ),
                          );
                          return;
                        }
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              currentRequest.type == StaffRequestType.transfer
                                  ? 'Transfer request deleted successfully.'
                                  : '${updated.type.label} request marked as withdrawn.',
                            ),
                          ),
                        );
                        if (currentRequest.type == StaffRequestType.transfer &&
                            context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(
                  requestState.isSubmitting
                      ? currentRequest.type == StaffRequestType.transfer
                            ? 'Deleting...'
                            : 'Withdrawing...'
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

Future<void> _openTransferCorrectionSheet(
  BuildContext context,
  WidgetRef ref,
  StaffRequestRecord request,
) async {
  final labelController = TextEditingController(text: 'supporting_document');
  final selectedFiles = <PlatformFile>[];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final isSubmitting = ref.watch(
            staffRequestsViewModelProvider.select(
              (state) => state.isSubmitting,
            ),
          );

          return Container(
            margin: const EdgeInsets.all(14),
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              MediaQuery.of(sheetContext).viewInsets.bottom + 18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer Attachments',
                  style: _requestTextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload the missing documents, then the request will be resubmitted.',
                  style: _requestTextStyle(
                    fontSize: 12,
                    color: _requestMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Attachment Label',
                  controller: labelController,
                  hintText: 'supporting_document',
                ),
                FileUploadField(
                  title: 'Upload Documents',
                  description: 'PDF, Word, Excel, PowerPoint or image files.',
                  fileName: selectedFiles.isEmpty
                      ? null
                      : '${selectedFiles.length} file${selectedFiles.length == 1 ? '' : 's'} selected',
                  onBrowse: () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      type: FileType.custom,
                      allowedExtensions: const [
                        'pdf',
                        'doc',
                        'docx',
                        'xls',
                        'xlsx',
                        'ppt',
                        'pptx',
                        'txt',
                        'csv',
                        'png',
                        'jpg',
                        'jpeg',
                      ],
                      withData: false,
                    );
                    if (result == null || result.files.isEmpty) return;
                    setModalState(() {
                      selectedFiles
                        ..clear()
                        ..addAll(result.files);
                    });
                  },
                ),
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...selectedFiles.map(
                    (file) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        file.name,
                        style: _requestTextStyle(
                          fontSize: 12,
                          color: _requestMuted,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final usableFiles = selectedFiles
                                .where(
                                  (file) =>
                                      file.path != null &&
                                      file.path!.trim().isNotEmpty,
                                )
                                .toList();
                            if (usableFiles.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Select at least one file.'),
                                ),
                              );
                              return;
                            }
                            final label = labelController.text.trim();
                            try {
                              await ref
                                  .read(staffRequestsViewModelProvider.notifier)
                                  .uploadTransferCorrectionAttachments(
                                    request: request,
                                    filePaths: usableFiles
                                        .map((file) => file.path!)
                                        .toList(),
                                    fileNames: usableFiles
                                        .map((file) => file.name)
                                        .toList(),
                                    labels: label.isEmpty
                                        ? const []
                                        : List.filled(
                                            usableFiles.length,
                                            label,
                                          ),
                                  );
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(friendlyErrorMessage(error)),
                                ),
                              );
                              return;
                            }
                            if (!context.mounted || !sheetContext.mounted) {
                              return;
                            }
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Transfer request resubmitted successfully.',
                                ),
                              ),
                            );
                          },
                    child: Text(isSubmitting ? 'Submitting...' : 'Submit'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class MissingActivityAttachmentsReportScreen extends ConsumerWidget {
  const MissingActivityAttachmentsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref
        .watch(staffRequestsRepositoryProvider)
        .fetchMissingActivityAttachmentsReport();

    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Missing Attachments',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _requestBlue),
            );
          }
          if (snapshot.hasError) {
            return _ReportEmptyMessage(
              message: friendlyErrorMessage(snapshot.error!),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const _ReportEmptyMessage(
              message: 'No missing activity attachments found.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = items[index];
              final title = _reportValue(item, const [
                'group_label',
                'activity_area_type',
                'department_name',
                'location_name',
                'user_name',
                'working_station_name',
              ], fallback: 'Missing attachment group');
              final count = _reportValue(item, const [
                'missing_count',
                'total',
                'count',
              ], fallback: '0');
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _requestBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_late_outlined,
                      color: Color(0xFFB54708),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: _requestTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      count,
                      style: _requestTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFB54708),
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

class _ReportEmptyMessage extends StatelessWidget {
  const _ReportEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: _requestTextStyle(fontSize: 13, color: _requestMuted),
        ),
      ),
    );
  }
}

String _reportValue(
  Map<String, dynamic> item,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = item[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return fallback;
}

class _LeaveDetailActions extends ConsumerWidget {
  const _LeaveDetailActions({required this.request});

  final StaffRequestRecord request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffRequestsViewModelProvider);
    return Column(
      children: [
        // SizedBox(
        //   width: double.infinity,
        //   child: OutlinedButton.icon(
        //     onPressed: () async {
        //       final detail = await ref
        //           .read(staffRequestsViewModelProvider.notifier)
        //           .fetchLeaveDetail(request);
        //       if (!context.mounted) return;
        //       Navigator.of(context).pushReplacement(
        //         MaterialPageRoute<void>(
        //           builder: (_) => RequestDetailScreen(request: detail),
        //         ),
        //       );
        //     },
        //     icon: const Icon(Icons.refresh_rounded, size: 18),
        //     label: const Text('Refresh Detail'),
        //   ),
        // ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openLeaveDocument(
                  context,
                  ref
                      .read(staffRequestsRepositoryProvider)
                      .leaveLetterUrl(request),
                ),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Leave Letter'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openLeaveDocument(
                  context,
                  ref
                      .read(staffRequestsRepositoryProvider)
                      .returnToWorkLetterUrl(request),
                ),
                icon: const Icon(Icons.assignment_return_outlined, size: 18),
                label: const Text('Return Letter'),
              ),
            ),
          ],
        ),
        if (request.status == StaffRequestStatus.approved) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: _filledStyle(),
              onPressed: state.isSubmitting
                  ? null
                  : () => _openReturnToWorkSheet(context, ref, request),
              icon: const Icon(Icons.keyboard_return_rounded, size: 18),
              label: Text(
                state.isSubmitting ? 'Submitting...' : 'Submit Return To Work',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _openReturnToWorkSheet(
  BuildContext context,
  WidgetRef ref,
  StaffRequestRecord request,
) async {
  final result = await showModalBottomSheet<_ReturnToWorkResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ReturnToWorkSheet(),
  );
  if (result == null || !context.mounted) return;

  try {
    final message = await ref
        .read(staffRequestsViewModelProvider.notifier)
        .submitReturnToWork(
          request: request,
          returnedDate: result.returnedDate,
          description: result.description,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
  }
}

class _ReturnToWorkSheet extends StatefulWidget {
  const _ReturnToWorkSheet();

  @override
  State<_ReturnToWorkSheet> createState() => _ReturnToWorkSheetState();
}

class _ReturnToWorkSheetState extends State<_ReturnToWorkSheet> {
  final _descriptionController = TextEditingController();
  DateTime _returnedDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Return To Work',
              style: _requestTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _returnedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _returnedDate = picked);
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text('Returned ${_formatShortDate(_returnedDate)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: _filledStyle(),
                onPressed: () {
                  final description = _descriptionController.text.trim();
                  if (description.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Description is required.')),
                    );
                    return;
                  }
                  Navigator.of(context).pop(
                    _ReturnToWorkResult(
                      returnedDate: _returnedDate,
                      description: description,
                    ),
                  );
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnToWorkResult {
  const _ReturnToWorkResult({
    required this.returnedDate,
    required this.description,
  });

  final DateTime returnedDate;
  final String description;
}

Future<void> _openLeaveDocument(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.path.endsWith('/')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document is not available yet.')),
    );
    return;
  }
  var opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  if (!opened) {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open document.')));
  }
}

Future<void> _openRequestDocument(BuildContext context, String value) async {
  final url = _documentUrlFromAttachment(value);
  if (url == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document is not available yet.')),
    );
    return;
  }

  final uri = Uri.parse(url);
  var opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  if (!opened) {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open document.')));
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

class _RequestOverviewShimmer extends StatelessWidget {
  const _RequestOverviewShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 14),
          child: const _RequestSkeletonCard(),
        ),
      ),
    );
  }
}

class _ApprovalInboxShimmer extends StatelessWidget {
  const _ApprovalInboxShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
          child: const _RequestSkeletonCard(compact: true),
        ),
      ),
    );
  }
}

class _RequestSkeletonCard extends StatelessWidget {
  const _RequestSkeletonCard({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _RequestShimmer(
      child: Container(
        width: double.infinity,
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
                _SkeletonBox(width: 42, height: 42, radius: 12),
                const SizedBox(width: 10),
                Expanded(child: _SkeletonBox(height: 16, radius: 8)),
                const SizedBox(width: 18),
                _SkeletonBox(width: 28, height: 28, radius: 999),
              ],
            ),
            const SizedBox(height: 14),
            _SkeletonBox(width: double.infinity, height: 12, radius: 8),
            if (!compact) ...[
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: _SkeletonBox(height: 54, radius: 14)),
                  SizedBox(width: 8),
                  Expanded(child: _SkeletonBox(height: 54, radius: 14)),
                  SizedBox(width: 8),
                  Expanded(child: _SkeletonBox(height: 54, radius: 14)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestShimmer extends StatefulWidget {
  const _RequestShimmer({required this.child});

  final Widget child;

  @override
  State<_RequestShimmer> createState() => _RequestShimmerState();
}

class _RequestShimmerState extends State<_RequestShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = -1.0 + (_controller.value * 2.0);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(position - 1, 0),
              end: Alignment(position + 1, 0),
              colors: const [
                Color(0xFFE8EEF6),
                Color(0xFFF7FAFE),
                Color(0xFFE8EEF6),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height, required this.radius});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF6),
        borderRadius: BorderRadius.circular(radius),
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
  const _AttachmentCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final name = _documentNameFromUrl(url);
    return InkWell(
      onTap: () => _openRequestDocument(context, url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _requestTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.open_in_new_rounded, color: _requestMuted),
          ],
        ),
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

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;

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
            maxLines: maxLines,
            validator: (value) {
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

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.message,
    required this.onClose,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final VoidCallback onClose;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
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
      return 'Delete Transfer Request';
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
      return 'This will delete the transfer request if it has not progressed past the first workflow step.';
    case StaffRequestType.loan:
      return 'This will mark the loan application as withdrawn.';
    case StaffRequestType.activity:
    case StaffRequestType.sickLeave:
      return 'This request cannot be withdrawn.';
  }
}

String? _documentUrlFromAttachment(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return null;

  final match = RegExp(
    r'https?://\S+',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (match == null) return null;

  final url = match.group(0)?.replaceFirst(RegExp(r'[)\],.]+$'), '') ?? '';
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
    return null;
  }
  return url;
}

String _documentNameFromUrl(String url) {
  final uri = Uri.tryParse(url);
  final path = uri?.pathSegments.isNotEmpty == true
      ? uri!.pathSegments.last
      : '';
  final decoded = Uri.decodeComponent(path).trim();
  return decoded.isEmpty ? 'Open Document' : decoded;
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
    case StaffRequestStatus.attachmentReturned:
      return const Color(0xFFB54708);
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
    case StaffRequestStatus.attachmentReturned:
      return const Color(0xFFFFF4E5);
  }
}
