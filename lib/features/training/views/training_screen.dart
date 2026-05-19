import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:staffportal/features/auth/models/staff_portal_access.dart';
import 'package:staffportal/features/requests/models/staff_request_models.dart';
import 'package:staffportal/features/training/models/training_models.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/utils/url_resolver.dart';
import 'package:staffportal/core/providers/app_providers.dart';

part '../widgets/training_widgets.dart';

const _trainingBlue = Color(0xFF1F6BFF);
const _trainingSurface = Colors.white;
const _trainingCard = Colors.white;
const _trainingBorder = Color(0xFFE7ECF3);
const _trainingText = Color(0xFF101828);
const _trainingMuted = Color(0xFF6B7280);
const _trainingSoftBlue = Color(0xFFF4F8FF);

void openTrainingHubScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const TrainingScreen(standalone: true),
    ),
  );
}

void openTrainingDetailsScreen(BuildContext context, TrainingProgram program) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TrainingDetailsScreen(training: program),
    ),
  );
}

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  String _query = '';
  TrainingParticipationStatus? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffPortalAccessProvider);
    if (access.canReviewTrainingRequests) {
      return _ApproverTrainingHub(standalone: widget.standalone);
    }

    final state = ref.watch(trainingViewModelProvider);
    final sharedState = ref.watch(staffRequestsViewModelProvider);
    final latestTrainings = _mergeTrainingPrograms(
      state.latestTrainings,
      _programsFromHomeAnnouncements(sharedState.announcements),
    );
    final trainingResources = _mergeTrainingResources(
      state.resources,
      _resourcesFromHomeResources(sharedState.resources),
    );
    final latest = _filterPrograms(
      latestTrainings,
      _query,
      status: _selectedStatus,
      dateRange: _dateRange,
    );
    final myApplications = _filterPrograms(
      state.myTrainingApplications,
      _query,
      status: _selectedStatus,
      dateRange: _dateRange,
    );
    final myTrainings = _filterPrograms(
      state.myTrainings,
      _query,
      status: _selectedStatus,
      dateRange: _dateRange,
    );
    final resources = _filterResources(trainingResources, _query);
    final isLoading = state.isLoading || sharedState.isLoading;

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: widget.standalone
          ? AppBar(
              backgroundColor: _trainingSurface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: _trainingText,
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        top: !widget.standalone,
        child: RefreshIndicator(
          color: _trainingBlue,
          onRefresh: () =>
              ref.read(trainingViewModelProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Text(
                'Trainings',
                style: _trainingTextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _SearchToolbar(
                hintText: 'Search...',
                onChanged: (value) => setState(() => _query = value),
                filterCount: _trainingFilterCount(
                  status: _selectedStatus,
                  dateRange: _dateRange,
                ),
                onFilterPressed: _openStatusFilter,
                onCalendarPressed: _openDateFilter,
              ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Announcements',
                actionLabel: 'See All',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LatestTrainingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (isLoading && latestTrainings.isEmpty)
                const _TrainingCarouselShimmer()
              else if (latest.isEmpty)
                const _EmptyCard(message: 'No trainings found')
              else ...[
                SizedBox(
                  height: 320,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: latest.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final item = latest[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _LatestTrainingCard(
                          program: item,
                          onPressed: () => _openTrainingDetails(context, item),
                        ),
                      );
                    },
                  ),
                ),
                if (latest.length > 1) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          latest.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width:
                                index ==
                                    _currentPage.clamp(0, latest.length - 1)
                                ? 18
                                : 6,
                            decoration: BoxDecoration(
                              color:
                                  index ==
                                      _currentPage.clamp(0, latest.length - 1)
                                  ? _trainingBlue
                                  : const Color(0xFFD6DFEB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'My Applications',
                actionLabel: 'See All',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyTrainingApplicationsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (myApplications.isEmpty)
                const _EmptyCard(message: 'No training applications yet')
              else
                ...myApplications
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TrainingStatusTile(
                          program: item,
                          onTap: () => _openTrainingDetails(context, item),
                        ),
                      ),
                    ),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'My Training',
                actionLabel: 'See All',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyTrainingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (myTrainings.isEmpty)
                const _EmptyCard(message: 'No training history found')
              else
                ...myTrainings
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TrainingStatusTile(
                          program: item,
                          onTap: () => _openTrainingDetails(context, item),
                        ),
                      ),
                    ),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Resources',
                actionLabel: 'See All',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TrainingResourcesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (isLoading && trainingResources.isEmpty)
                const _TrainingListShimmer()
              else if (resources.isEmpty)
                const _EmptyCard(message: 'No resources available')
              else
                ...resources
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ResourceTile(
                          resource: item,
                          onTap: () => _openResource(context, item),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStatusFilter() async {
    final result = await showModalBottomSheet<_TrainingStatusFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TrainingStatusFilterSheet(selectedStatus: _selectedStatus),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedStatus = result.status);
  }

  Future<void> _openDateFilter() async {
    final range = await _pickTrainingDateRange(context, _dateRange);
    if (!mounted || range == _dateRange) return;
    setState(() => _dateRange = range);
  }
}

enum _ApproverTrainingTab { allTrainings, applications, resources }

class _ApproverTrainingHub extends ConsumerStatefulWidget {
  const _ApproverTrainingHub({required this.standalone});

  final bool standalone;

  @override
  ConsumerState<_ApproverTrainingHub> createState() =>
      _ApproverTrainingHubState();
}

class _ApproverTrainingHubState extends ConsumerState<_ApproverTrainingHub> {
  _ApproverTrainingTab _selectedTab = _ApproverTrainingTab.applications;
  String _query = '';
  TrainingParticipationStatus? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffPortalAccessProvider);
    final state = ref.watch(trainingViewModelProvider);
    final sharedState = ref.watch(staffRequestsViewModelProvider);
    final latestTrainings = _mergeTrainingPrograms(
      state.latestTrainings,
      _programsFromHomeAnnouncements(sharedState.announcements),
    );
    final trainingResources = _mergeTrainingResources(
      state.resources,
      _resourcesFromHomeResources(sharedState.resources),
    );
    final trainings = _filterPrograms(
      latestTrainings,
      _query,
      status: _selectedStatus,
      dateRange: _dateRange,
    );
    final requestRecords = state.trainingRequests.isNotEmpty
        ? state.trainingRequests
        : state.approvalQueue;
    final approvals = _filterApprovalRecords(
      requestRecords,
      _query,
      status: _selectedStatus,
      dateRange: _dateRange,
    );
    final actionableCount = approvals
        .where(
          (record) =>
              _findActionableApproval(state.approvalQueue, record) != null,
        )
        .length;
    final resources = _filterResources(trainingResources, _query);
    final isLoading = state.isLoading || sharedState.isLoading;
    final actionLabels = _trainingApprovalActions(access);

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: widget.standalone
          ? AppBar(
              backgroundColor: _trainingSurface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: _trainingText,
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        top: !widget.standalone,
        child: RefreshIndicator(
          color: _trainingBlue,
          onRefresh: () =>
              ref.read(trainingViewModelProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Text(
                'Training',
                style: _trainingTextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              if (state.errorMessage != null) ...[
                _InlineBanner(
                  message: state.errorMessage!,
                  onClose: () =>
                      ref.read(trainingViewModelProvider.notifier).clearError(),
                  actionLabel: 'Retry',
                  onAction: () => ref
                      .read(trainingViewModelProvider.notifier)
                      .refreshApprovalRequests(),
                ),
                const SizedBox(height: 14),
              ],
              _ApproverTabSelector(
                selectedTab: _selectedTab,
                onSelected: _selectApproverTab,
              ),
              const SizedBox(height: 16),
              _SearchToolbar(
                hintText: 'Search...',
                onChanged: (value) => setState(() => _query = value),
                filterCount: _trainingFilterCount(
                  status: _selectedStatus,
                  dateRange: _dateRange,
                ),
                onFilterPressed: _openStatusFilter,
                onCalendarPressed: _openDateFilter,
              ),
              const SizedBox(height: 18),
              if (_selectedTab == _ApproverTrainingTab.allTrainings) ...[
                if (isLoading && latestTrainings.isEmpty)
                  const _TrainingListShimmer()
                else if (trainings.isEmpty)
                  const _EmptyCard(message: 'No trainings found')
                else
                  ...trainings.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _LatestTrainingCard(
                        program: item,
                        onPressed: () => _openTrainingDetails(context, item),
                      ),
                    ),
                  ),
              ] else if (_selectedTab == _ApproverTrainingTab.applications) ...[
                _QueueSummaryCard(
                  count: approvals.length,
                  actionableCount: actionableCount,
                ),
                const SizedBox(height: 14),
                if (state.isLoading &&
                    state.approvalQueue.isEmpty &&
                    state.trainingRequests.isEmpty)
                  const _TrainingApprovalShimmer()
                else if (approvals.isEmpty)
                  const _EmptyCard(
                    message: 'No training applications are waiting for review.',
                  )
                else
                  ...approvals.map((record) {
                    final actionableRecord = _findActionableApproval(
                      state.approvalQueue,
                      record,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TrainingApprovalCard(
                        record: record,
                        actionLabels: actionLabels,
                        isSubmitting: state.isSubmittingApproval,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                _TrainingApprovalDetailsScreen(record: record),
                          ),
                        ),
                        onAction:
                            actionLabels.isNotEmpty && actionableRecord != null
                            ? (action) =>
                                  _submitAction(actionableRecord, action)
                            : null,
                      ),
                    );
                  }),
              ] else ...[
                if (isLoading && trainingResources.isEmpty)
                  const _TrainingListShimmer()
                else if (resources.isEmpty)
                  const _EmptyCard(message: 'No resources found')
                else
                  ...resources.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ResourceTile(
                        resource: item,
                        onTap: () => _openResource(context, item),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAction(
    TrainingApprovalRecord record,
    String actionLabel,
  ) async {
    final result = await showModalBottomSheet<_TrainingApprovalActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrainingApprovalActionSheet(actionLabel: actionLabel),
    );

    if (result == null) return;

    try {
      final message = await ref
          .read(trainingViewModelProvider.notifier)
          .submitApprovalAction(
            record: record,
            comment: result.comment,
            action: actionLabel,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {}
  }

  void _selectApproverTab(_ApproverTrainingTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);

    final notifier = ref.read(trainingViewModelProvider.notifier);
    switch (tab) {
      case _ApproverTrainingTab.allTrainings:
        notifier.refreshLatestTrainings();
        break;
      case _ApproverTrainingTab.applications:
        notifier.refreshApprovalRequests();
        break;
      case _ApproverTrainingTab.resources:
        notifier.refreshResources();
        break;
    }
  }

  Future<void> _openStatusFilter() async {
    final result = await showModalBottomSheet<_TrainingStatusFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TrainingStatusFilterSheet(selectedStatus: _selectedStatus),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedStatus = result.status);
  }

  Future<void> _openDateFilter() async {
    final range = await _pickTrainingDateRange(context, _dateRange);
    if (!mounted || range == _dateRange) return;
    setState(() => _dateRange = range);
  }
}

class _TrainingApprovalDetailsScreen extends ConsumerStatefulWidget {
  const _TrainingApprovalDetailsScreen({required this.record});

  final TrainingApprovalRecord record;

  @override
  ConsumerState<_TrainingApprovalDetailsScreen> createState() =>
      _TrainingApprovalDetailsScreenState();
}

class _TrainingApprovalDetailsScreenState
    extends ConsumerState<_TrainingApprovalDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(trainingViewModelProvider.notifier)
          .loadApprovalDetail(widget.record);
    });
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffPortalAccessProvider);
    final state = ref.watch(trainingViewModelProvider);
    final record = state.resolveApproval(widget.record);
    final actionableRecord = _findActionableApproval(
      state.approvalQueue,
      record,
    );
    final actionLabels = _trainingApprovalActions(access);
    final canSubmitAction = actionLabels.isNotEmpty && actionableRecord != null;
    final TrainingApprovalRecord reviewRecord = canSubmitAction
        ? actionableRecord
        : record;

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: AppBar(
        backgroundColor: _trainingSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Training Application Details',
          style: _trainingTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        children: [
          if (state.errorMessage != null) ...[
            _InlineBanner(
              message: state.errorMessage!,
              onClose: () =>
                  ref.read(trainingViewModelProvider.notifier).clearError(),
              actionLabel: 'Retry',
              onAction: () {
                ref
                    .read(trainingViewModelProvider.notifier)
                    .loadApprovalDetail(widget.record);
              },
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _trainingCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _trainingBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: _trainingTextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(status: record.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  record.workflowLabel,
                  style: _trainingTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _trainingMuted,
                  ),
                ),
                const SizedBox(height: 14),
                _DetailMetric(label: 'Applicant', value: record.applicantName),
                const SizedBox(height: 12),
                _DetailMetric(
                  label: 'Facility',
                  value: _fallbackLabel(
                    record.workingStationName,
                    fallback: 'Not provided',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _TrainingSectionBlock(
            title: 'Applicant Information',
            children: [
              _InfoRow(label: 'Name', value: record.applicantName),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Phone',
                value: _fallbackLabel(record.applicantPhone),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Email',
                value: _fallbackLabel(record.applicantEmail),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Gender',
                value: _fallbackLabel(record.applicantGender),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Facility',
                value: _fallbackLabel(record.workingStationName),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TrainingSectionBlock(
            title: 'Training Information',
            children: [
              _InfoRow(label: 'Training Title', value: record.title),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Training Type',
                value: _fallbackLabel(record.educationLevelName),
              ),
              const SizedBox(height: 10),
              _InfoRow(label: 'Cadre', value: _fallbackLabel(record.cadreName)),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Vendor',
                value: _fallbackLabel(record.vendorName),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Location',
                value: _fallbackLabel(record.instituteName),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TrainingSectionBlock(
            title: 'Schedule',
            children: [
              _InfoRow(
                label: 'Start Date',
                value: _formatLongDate(record.startDate),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'End Date',
                value: _formatLongDate(record.endDate),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Batch Year',
                value: _fallbackLabel(record.batchYear),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TrainingSectionBlock(
            title: 'Supporting Documents',
            children: [
              if (record.resources.isEmpty)
                const _EmptyCard(message: 'No supporting documents found')
              else
                ...record.resources.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ResourceTile(
                      resource: resource,
                      onTap: () => _openResource(context, resource),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _TrainingSectionBlock(
            title: 'Approval Timeline',
            children: _buildApprovalTimeline(record),
          ),
        ],
      ),
      bottomNavigationBar: canSubmitAction
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _TrainingApprovalActionButtons(
                  actions: actionLabels,
                  isSubmitting: state.isSubmittingApproval,
                  onAction: (action) => _handleAction(reviewRecord, action),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _handleAction(
    TrainingApprovalRecord record,
    String actionLabel,
  ) async {
    final result = await showModalBottomSheet<_TrainingApprovalActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrainingApprovalActionSheet(actionLabel: actionLabel),
    );

    if (result == null) return;

    try {
      final message = await ref
          .read(trainingViewModelProvider.notifier)
          .submitApprovalAction(
            record: record,
            comment: result.comment,
            action: actionLabel,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } catch (_) {}
  }

  List<Widget> _buildApprovalTimeline(TrainingApprovalRecord record) {
    final steps = [
      _ApprovalTimelineStep(
        title: 'Application Submitted',
        subtitle: 'Submitted by ${record.applicantName}',
        isCompleted: true,
      ),
      _ApprovalTimelineStep(
        title: record.workflowLabel,
        subtitle: 'Current workflow stage',
        isCompleted: false,
      ),
      _ApprovalTimelineStep(
        title: 'Training Contract Stage',
        subtitle: 'Reached after approval in the current workflow',
        isCompleted: false,
      ),
    ];

    return steps
        .map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ApprovalTimelineTile(step: step),
          ),
        )
        .toList();
  }
}

class LatestTrainingsScreen extends ConsumerStatefulWidget {
  const LatestTrainingsScreen({super.key});

  @override
  ConsumerState<LatestTrainingsScreen> createState() =>
      _LatestTrainingsScreenState();
}

class _LatestTrainingsScreenState extends ConsumerState<LatestTrainingsScreen> {
  String _query = '';
  TrainingParticipationStatus? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingViewModelProvider);
    final sharedState = ref.watch(staffRequestsViewModelProvider);
    final latestTrainings = _mergeTrainingPrograms(
      state.latestTrainings,
      _programsFromHomeAnnouncements(sharedState.announcements),
    );
    final items = _filterPrograms(
      latestTrainings,
      _query,
      status: _selectedStatus,
      dateRange: _dateRange,
    );
    final isLoading = state.isLoading || sharedState.isLoading;

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: _TrainingAppBar(title: 'Announcements'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _SearchToolbar(
            hintText: 'Search...',
            onChanged: (value) => setState(() => _query = value),
            filterCount: _trainingFilterCount(
              status: _selectedStatus,
              dateRange: _dateRange,
            ),
            onFilterPressed: _openStatusFilter,
            onCalendarPressed: _openDateFilter,
          ),
          const SizedBox(height: 16),
          if (isLoading && latestTrainings.isEmpty)
            const _TrainingListShimmer()
          else if (items.isEmpty)
            const _EmptyCard(message: 'No announcements match your search')
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _LatestTrainingCard(
                  program: item,
                  onPressed: () => _openTrainingDetails(context, item),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openStatusFilter() async {
    final result = await showModalBottomSheet<_TrainingStatusFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TrainingStatusFilterSheet(selectedStatus: _selectedStatus),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedStatus = result.status);
  }

  Future<void> _openDateFilter() async {
    final range = await _pickTrainingDateRange(context, _dateRange);
    if (!mounted || range == _dateRange) return;
    setState(() => _dateRange = range);
  }
}

class MyTrainingsScreen extends ConsumerStatefulWidget {
  const MyTrainingsScreen({super.key});

  @override
  ConsumerState<MyTrainingsScreen> createState() => _MyTrainingsScreenState();
}

class _MyTrainingsScreenState extends ConsumerState<MyTrainingsScreen> {
  String _query = '';
  TrainingParticipationStatus? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingViewModelProvider);
    final searched = _filterPrograms(
      state.myTrainings,
      _query,
      status: _selectedStatus,
      dateRange: _dateRange,
    );
    final items = searched;

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: _TrainingAppBar(title: 'My Training'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _SearchToolbar(
            hintText: 'Search...',
            onChanged: (value) => setState(() => _query = value),
            filterCount: _trainingFilterCount(
              status: _selectedStatus,
              dateRange: _dateRange,
            ),
            onFilterPressed: _openStatusFilter,
            onCalendarPressed: _openDateFilter,
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const _EmptyCard(message: 'No training history found')
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    _TrainingStatusTile(
                      program: item,
                      onTap: () => _openTrainingDetails(context, item),
                      onDelete:
                          item.status == TrainingParticipationStatus.pending
                          ? () => _deleteTrainingApplication(item)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _TrainingEmployeeActions(
                      program: item,
                      onEdit: item.status == TrainingParticipationStatus.pending
                          ? () => _editTrainingApplication(item)
                          : null,
                      onUploadContract: () => _uploadContract(item),
                      onGenerateContract: () => _generateContract(item),
                      onUploadResult: () => _uploadResult(),
                      onLetter: () => _openTrainingLetter(item),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openStatusFilter() async {
    final result = await showModalBottomSheet<_TrainingStatusFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TrainingStatusFilterSheet(selectedStatus: _selectedStatus),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedStatus = result.status);
  }

  Future<void> _openDateFilter() async {
    final range = await _pickTrainingDateRange(context, _dateRange);
    if (!mounted || range == _dateRange) return;
    setState(() => _dateRange = range);
  }

  Future<void> _deleteTrainingApplication(TrainingProgram program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete training application'),
        content: const Text(
          'This will delete the training application if it is still editable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Application'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _trainingBlue),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final message = await ref
          .read(trainingViewModelProvider.notifier)
          .deleteTrainingRequest(program);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  Future<void> _editTrainingApplication(TrainingProgram program) async {
    final result = await showModalBottomSheet<_TrainingEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrainingEditSheet(program: program),
    );
    if (result == null || !mounted) return;
    try {
      final message = await ref
          .read(trainingViewModelProvider.notifier)
          .updateTrainingRequest(
            training: program,
            startDate: result.startDate,
            endDate: result.endDate,
            admissionLetterPath: result.filePath,
            admissionLetterName: result.fileName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  Future<void> _uploadContract(TrainingProgram program) async {
    final file = await _pickTrainingPdf();
    if (file == null || !mounted) return;
    try {
      final message = await ref
          .read(trainingViewModelProvider.notifier)
          .uploadTrainingContract(
            training: program,
            filePath: file.$1,
            fileName: file.$2,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  Future<void> _uploadResult() async {
    final options = await ref
        .read(trainingViewModelProvider.notifier)
        .fetchTrainingResultOptions();
    if (!mounted) return;
    final result = await showModalBottomSheet<_TrainingResultUploadResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrainingResultUploadSheet(options: options),
    );
    if (result == null || !mounted) return;
    try {
      final message = await ref
          .read(trainingViewModelProvider.notifier)
          .uploadTrainingResult(
            trainingStudentResultId: result.trainingStudentResultId,
            filePath: result.filePath,
            fileName: result.fileName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  Future<void> _generateContract(TrainingProgram program) async {
    final viewModel = ref.read(trainingViewModelProvider.notifier);
    final results = await Future.wait<List<RequestLookupOption>>([
      viewModel.fetchTrainingReferees(),
      viewModel.fetchTrainingDirectors(),
      viewModel.fetchTrainingCostTypes(),
    ]);
    if (!mounted) return;
    final result = await showModalBottomSheet<_TrainingContractResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrainingContractSheet(
        referees: results[0],
        directors: results[1],
        costTypes: results[2],
      ),
    );
    if (result == null || !mounted) return;
    try {
      final message = await ref
          .read(trainingViewModelProvider.notifier)
          .generateTrainingContract(
            training: program,
            refereeId: result.refereeId,
            directorId: result.directorId,
            costTypeId: result.costTypeId,
            costAmount: result.costAmount,
            unit: result.unit,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  Future<void> _openTrainingLetter(TrainingProgram program) async {
    final url = ref.read(trainingRepositoryProvider).trainingLetterUrl(program);
    final uri = Uri.tryParse(url);
    if (uri == null || uri.path.endsWith('/')) return;
    var opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class MyTrainingApplicationsScreen extends ConsumerStatefulWidget {
  const MyTrainingApplicationsScreen({super.key});

  @override
  ConsumerState<MyTrainingApplicationsScreen> createState() =>
      _MyTrainingApplicationsScreenState();
}

class _MyTrainingApplicationsScreenState
    extends ConsumerState<MyTrainingApplicationsScreen> {
  String _query = '';
  TrainingParticipationStatus? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingViewModelProvider);
    final items = _filterPrograms(
      state.myTrainingApplications,
      _query,
      status: _selectedStatus,
      dateRange: _dateRange,
    );
    final hasLoadError =
        state.errorMessage != null && state.myTrainingApplications.isEmpty;

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: _TrainingAppBar(title: 'My Applications'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: 'All',
                  isSelected: _selectedStatus == null,
                  onTap: () => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                _FilterChipButton(
                  label: 'Pending',
                  isSelected:
                      _selectedStatus == TrainingParticipationStatus.pending,
                  onTap: () => setState(
                    () => _selectedStatus = TrainingParticipationStatus.pending,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChipButton(
                  label: 'Approved',
                  isSelected:
                      _selectedStatus == TrainingParticipationStatus.approved,
                  onTap: () => setState(
                    () =>
                        _selectedStatus = TrainingParticipationStatus.approved,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChipButton(
                  label: 'Rejected',
                  isSelected:
                      _selectedStatus == TrainingParticipationStatus.rejected,
                  onTap: () => setState(
                    () =>
                        _selectedStatus = TrainingParticipationStatus.rejected,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SearchToolbar(
            hintText: 'Search...',
            onChanged: (value) => setState(() => _query = value),
            filterCount: _trainingFilterCount(
              status: _selectedStatus,
              dateRange: _dateRange,
            ),
            onFilterPressed: _openStatusFilter,
            onCalendarPressed: _openDateFilter,
          ),
          const SizedBox(height: 16),
          if (state.isLoading && state.myTrainingApplications.isEmpty)
            const _TrainingListShimmer()
          else if (hasLoadError) ...[
            _InlineBanner(
              message: state.errorMessage!,
              onClose: () =>
                  ref.read(trainingViewModelProvider.notifier).clearError(),
              actionLabel: 'Retry',
              onAction: () =>
                  ref.read(trainingViewModelProvider.notifier).refresh(),
            ),
            const SizedBox(height: 12),
            const _EmptyCard(message: 'No training applications loaded'),
          ] else if (items.isEmpty)
            const _EmptyCard(message: 'No training applications found')
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TrainingStatusTile(
                  program: item,
                  onTap: () => _openTrainingDetails(context, item),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openStatusFilter() async {
    final result = await showModalBottomSheet<_TrainingStatusFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TrainingStatusFilterSheet(selectedStatus: _selectedStatus),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedStatus = result.status);
  }

  Future<void> _openDateFilter() async {
    final range = await _pickTrainingDateRange(context, _dateRange);
    if (!mounted || range == _dateRange) return;
    setState(() => _dateRange = range);
  }
}

class TrainingResourcesScreen extends ConsumerStatefulWidget {
  const TrainingResourcesScreen({super.key});

  @override
  ConsumerState<TrainingResourcesScreen> createState() =>
      _TrainingResourcesScreenState();
}

class _TrainingResourcesScreenState
    extends ConsumerState<TrainingResourcesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingViewModelProvider);
    final sharedState = ref.watch(staffRequestsViewModelProvider);
    final trainingResources = _mergeTrainingResources(
      state.resources,
      _resourcesFromHomeResources(sharedState.resources),
    );
    final items = _filterResources(trainingResources, _query);
    final isLoading = state.isLoading || sharedState.isLoading;

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: _TrainingAppBar(title: 'Resources'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _SearchToolbar(
            hintText: 'Search...',
            onChanged: (value) => setState(() => _query = value),
            showFilterActions: false,
          ),
          const SizedBox(height: 16),
          if (isLoading && trainingResources.isEmpty)
            const _TrainingListShimmer()
          else if (items.isEmpty)
            const _EmptyCard(message: 'No resources found')
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ResourceTile(
                  resource: item,
                  onTap: () => _openResource(context, item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TrainingDetailsScreen extends ConsumerStatefulWidget {
  const TrainingDetailsScreen({super.key, required this.training});

  final TrainingProgram training;

  @override
  ConsumerState<TrainingDetailsScreen> createState() =>
      _TrainingDetailsScreenState();
}

class _TrainingDetailsScreenState extends ConsumerState<TrainingDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainingViewModelProvider.notifier).loadDetail(widget.training);
    });
  }

  Future<void> _submitApplication(TrainingProgram program) async {
    final messenger = ScaffoldMessenger.of(context);
    var application = program;

    final needsInstitute =
        (application.shortCourseDescriptionId ?? '').trim().isEmpty &&
        (application.instituteId ?? '').trim().isEmpty;
    if (needsInstitute) {
      final institute = await _pickTrainingInstitute(application);
      if (!mounted || institute == null) return;
      application = application.copyWith(
        instituteId: institute.id,
        location: institute.name,
      );
    }

    try {
      await ref
          .read(trainingViewModelProvider.notifier)
          .applyForTraining(application);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Training request submitted successfully.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ref.read(trainingViewModelProvider).errorMessage ??
                'Unable to submit the training request.',
          ),
        ),
      );
    }
  }

  Future<TrainingCountry?> _pickTrainingCountry() async {
    List<TrainingCountry> countries;
    try {
      countries = await ref
          .read(trainingRepositoryProvider)
          .fetchTrainingCountries();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load institute countries.')),
        );
      }
      return null;
    }

    if (!mounted) return null;
    if (countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No institute countries found.')),
      );
      return null;
    }

    return showModalBottomSheet<TrainingCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filtered = normalizedQuery.isEmpty
                ? countries
                : countries
                      .where(
                        (item) =>
                            item.name.toLowerCase().contains(normalizedQuery) ||
                            item.code.toLowerCase().contains(normalizedQuery),
                      )
                      .toList();

            return _TrainingPickerSheet(
              title: 'Select Institute Country',
              subtitle: 'Choose the country where the institute is registered.',
              searchHint: 'Search country',
              onSearchChanged: (value) => setModalState(() => query = value),
              emptyMessage: 'No country matches your search.',
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final country = filtered[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    country.name,
                    style: _trainingTextStyle(fontSize: 14),
                  ),
                  subtitle: Text(country.code),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(sheetContext).pop(country),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<TrainingInstitute?> _pickTrainingInstitute(
    TrainingProgram program,
  ) async {
    final country = await _pickTrainingCountry();
    if (!mounted || country == null) return null;

    final educationLevelId = (program.educationLevelId ?? '').trim();
    if (educationLevelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This training is missing an education level.'),
        ),
      );
      return null;
    }

    List<TrainingInstitute> institutes;
    try {
      institutes = await ref
          .read(trainingRepositoryProvider)
          .fetchInstitutes(
            countryCode: country.code,
            educationLevelId: educationLevelId,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load training institutes.')),
        );
      }
      return null;
    }

    if (!mounted) return null;
    if (institutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No training institutes found.')),
      );
      return null;
    }

    return showModalBottomSheet<TrainingInstitute>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filtered = normalizedQuery.isEmpty
                ? institutes
                : institutes
                      .where(
                        (item) =>
                            item.name.toLowerCase().contains(normalizedQuery) ||
                            (item.countryName ?? '').toLowerCase().contains(
                              normalizedQuery,
                            ),
                      )
                      .toList();

            return _TrainingPickerSheet(
              title: 'Select Training Institute',
              subtitle:
                  'Showing institutes for ${country.name} and this education level.',
              searchHint: 'Search institute',
              onSearchChanged: (value) => setModalState(() => query = value),
              emptyMessage: 'No institute matches your search.',
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final institute = filtered[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    institute.name,
                    style: _trainingTextStyle(fontSize: 14),
                  ),
                  subtitle: (institute.countryName ?? '').trim().isEmpty
                      ? null
                      : Text(institute.countryName!),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(sheetContext).pop(institute),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingViewModelProvider);
    final program = state.resolveProgram(widget.training);
    final targetCadres = program.targetCadres.isNotEmpty
        ? program.targetCadres
        : const ['Staff Members'];
    final actionLabel = switch (program.status) {
      TrainingParticipationStatus.notApplied => 'Apply for Training',
      TrainingParticipationStatus.pending => 'Application Submitted',
      TrainingParticipationStatus.approved => 'Training Approved',
      TrainingParticipationStatus.rejected => 'Application Rejected',
      TrainingParticipationStatus.completed => 'Training Completed',
    };
    final canApply =
        program.status == TrainingParticipationStatus.notApplied &&
        program.canApplyLive &&
        !state.isSubmitting;

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: AppBar(
        backgroundColor: _trainingSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Training Details',
          style: _trainingTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _StatusChip(status: program.status, compact: true),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TrainingArtwork(seed: program.id.hashCode, height: 182),
            const SizedBox(height: 16),
            Text(
              program.title,
              style: _trainingTextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DetailMetric(
                    label: 'Training Type',
                    value: program.trainingType,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DetailMetric(
                    label: 'Organizer',
                    value: program.organizer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailMetric(label: 'Location', value: program.location),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: _trainingTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _trainingMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              program.description,
              style: _trainingTextStyle(
                fontSize: 13,
                height: 1.5,
                color: const Color(0xFF475467),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SCHEDULE',
              style: _trainingTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _trainingMuted,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Start Date',
              value: _formatLongDate(program.startDate),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'End Date',
              value: _formatLongDate(program.endDate),
            ),
            if ((program.workingExperienceLabel ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Experience',
                value: program.workingExperienceLabel!,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'TARGET CADRE',
              style: _trainingTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _trainingMuted,
              ),
            ),
            const SizedBox(height: 12),
            ...targetCadres.map(
              (cadre) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: _trainingBlue),
                    const SizedBox(width: 10),
                    Text(
                      cadre,
                      style: _trainingTextStyle(
                        fontSize: 13,
                        color: const Color(0xFF475467),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _trainingSoftBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD8E6FF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    size: 18,
                    color: _trainingBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Available Slots: ${program.availableSlots}  •  ${program.participantCount} Participants',
                      style: _trainingTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _trainingBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (program.resources.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'RESOURCES',
                style: _trainingTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _trainingMuted,
                ),
              ),
              const SizedBox(height: 12),
              ...program.resources.map(
                (resource) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ResourceTile(
                    resource: resource,
                    onTap: () => _openResource(context, resource),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _trainingBlue,
              disabledBackgroundColor: const Color(0xFFD9E6FF),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: canApply ? () => _submitApplication(program) : null,
            child: state.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(actionLabel),
          ),
        ),
      ),
    );
  }
}
