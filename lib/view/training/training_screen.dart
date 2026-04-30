import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/staff_portal_access.dart';
import '../../model/training_models.dart';
import '../../view_model/providers.dart';

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
    final latest = _filterPrograms(state.latestTrainings, _query);
    final myTrainings = _filterPrograms(state.myTrainings, _query);
    final resources = _filterResources(state.resources, _query);

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
              if (state.errorMessage != null) ...[
                _InlineBanner(
                  message: state.errorMessage!,
                  onClose: () =>
                      ref.read(trainingViewModelProvider.notifier).clearError(),
                ),
                const SizedBox(height: 14),
              ],
              _SearchToolbar(
                hintText: 'Search...',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Latest Trainings',
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
              if (state.isLoading && state.latestTrainings.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      latest.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: index == _currentPage ? 18 : 6,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? _trainingBlue
                              : const Color(0xFFD6DFEB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'My Trainings',
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
                const _EmptyCard(message: 'No training applications yet')
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
              if (resources.isEmpty)
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

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffPortalAccessProvider);
    final state = ref.watch(trainingViewModelProvider);
    final trainings = _filterPrograms(state.latestTrainings, _query);
    final requestRecords = state.trainingRequests.isNotEmpty
        ? state.trainingRequests
        : state.approvalQueue;
    final approvals = _filterApprovalRecords(requestRecords, _query);
    final actionableCount = approvals
        .where(
          (record) =>
              _findActionableApproval(state.approvalQueue, record) != null,
        )
        .length;
    final resources = _filterResources(state.resources, _query);
    final actionLabel = _trainingApprovalActionLabel(access);
    final resolvedActionLabel = actionLabel ?? 'Approve';

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
                ),
                const SizedBox(height: 14),
              ],
              _ApproverTabSelector(
                selectedTab: _selectedTab,
                onSelected: (tab) => setState(() => _selectedTab = tab),
              ),
              const SizedBox(height: 16),
              _SearchToolbar(
                hintText: 'Search...',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 18),
              if (_selectedTab == _ApproverTrainingTab.allTrainings) ...[
                if (state.isLoading && state.latestTrainings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
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
                        actionLabel: actionLabel,
                        isSubmitting: state.isSubmittingApproval,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                _TrainingApprovalDetailsScreen(record: record),
                          ),
                        ),
                        onPrimaryAction:
                            actionLabel != null && actionableRecord != null
                            ? () => _submitAction(
                                actionableRecord,
                                resolvedActionLabel,
                              )
                            : null,
                      ),
                    );
                  }),
              ] else ...[
                if (resources.isEmpty)
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
          .submitApprovalAction(record: record, comment: result.comment);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {}
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
    final actionLabel = _trainingApprovalActionLabel(access);
    final resolvedActionLabel = actionLabel ?? 'Approve';
    final canSubmitAction = actionLabel != null && actionableRecord != null;
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
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _trainingBlue,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: state.isSubmittingApproval
                      ? null
                      : () => _handleAction(reviewRecord, resolvedActionLabel),
                  child: state.isSubmittingApproval
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text('$resolvedActionLabel Application'),
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
          .submitApprovalAction(record: record, comment: result.comment);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingViewModelProvider);
    final items = _filterPrograms(state.latestTrainings, _query);

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: _TrainingAppBar(title: 'Latest Trainings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _SearchToolbar(
            hintText: 'Search...',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (state.isLoading && state.latestTrainings.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            const _EmptyCard(message: 'No trainings match your search')
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
}

class MyTrainingsScreen extends ConsumerStatefulWidget {
  const MyTrainingsScreen({super.key});

  @override
  ConsumerState<MyTrainingsScreen> createState() => _MyTrainingsScreenState();
}

class _MyTrainingsScreenState extends ConsumerState<MyTrainingsScreen> {
  String _query = '';
  TrainingParticipationStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingViewModelProvider);
    final searched = _filterPrograms(state.myTrainings, _query);
    final items = _selectedStatus == null
        ? searched
        : searched.where((item) => item.status == _selectedStatus).toList();

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: _TrainingAppBar(title: 'My Trainings'),
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
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
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
    final items = _filterResources(state.resources, _query);

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: _TrainingAppBar(title: 'Resources'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _SearchToolbar(
            hintText: 'Search...',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
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
            onPressed: canApply
                ? () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref
                          .read(trainingViewModelProvider.notifier)
                          .applyForTraining(program);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Training request submitted successfully.',
                          ),
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
                : null,
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

class _TrainingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TrainingAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _trainingSurface,
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: _trainingTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchToolbar extends StatelessWidget {
  const _SearchToolbar({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _trainingBorder),
            ),
            child: TextField(
              onChanged: onChanged,
              style: _trainingTextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: _trainingTextStyle(
                  fontSize: 13,
                  color: const Color(0xFF98A2B3),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF98A2B3),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ToolbarButton(icon: Icons.tune_rounded),
        const SizedBox(width: 8),
        _ToolbarButton(icon: Icons.calendar_month_outlined),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: 42,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFF8FAFC),
          side: const BorderSide(color: _trainingBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {},
        child: Icon(icon, size: 19, color: _trainingMuted),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: _trainingTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: _trainingMuted,
          ),
          child: Text(
            actionLabel,
            style: _trainingTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _trainingMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _LatestTrainingCard extends StatelessWidget {
  const _LatestTrainingCard({required this.program, required this.onPressed});

  final TrainingProgram program;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _trainingCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _trainingBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight =
              constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: hasBoundedHeight
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrainingArtwork(seed: program.id.hashCode, height: 104),
                const SizedBox(height: 12),
                _BadgePill(label: program.badge),
                const SizedBox(height: 8),
                Text(
                  program.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _trainingTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: _trainingMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatShortDate(program.startDate),
                        style: _trainingTextStyle(
                          fontSize: 11,
                          color: _trainingMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: _trainingMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        program.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _trainingTextStyle(
                          fontSize: 11,
                          color: _trainingMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasBoundedHeight)
                  const Spacer()
                else
                  const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _trainingBlue,
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onPressed,
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrainingStatusTile extends StatelessWidget {
  const _TrainingStatusTile({required this.program, required this.onTap});

  final TrainingProgram program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _trainingCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _trainingBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          program.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _trainingTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusChip(status: program.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date',
                    style: _trainingTextStyle(
                      fontSize: 11,
                      color: _trainingMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatShortDate(program.startDate),
                    style: _trainingTextStyle(
                      fontSize: 12,
                      color: const Color(0xFF475467),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD0D5DD)),
          ],
        ),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({required this.resource, required this.onTap});

  final TrainingResource resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _trainingCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _trainingBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                size: 18,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _trainingTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.sizeLabel,
                    style: _trainingTextStyle(
                      fontSize: 11,
                      color: _trainingMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.remove_red_eye_outlined,
              size: 18,
              color: _trainingMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.compact = false});

  final TrainingParticipationStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 8,
        vertical: compact ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: _trainingTextStyle(
          fontSize: compact ? 10 : 9,
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: _trainingTextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF97316),
        ),
      ),
    );
  }
}

class _TrainingArtwork extends StatelessWidget {
  const _TrainingArtwork({required this.seed, required this.height});

  final int seed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = _artPalette(seed);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: palette,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -8,
              top: 14,
              child: _artFigure(
                const Color(0xFFFFD0DD),
                const Color(0xFF8B5CF6),
              ),
            ),
            Positioned(
              left: 68,
              top: 8,
              child: _artFigure(
                const Color(0xFFFCE7F3),
                const Color(0xFFF97316),
              ),
            ),
            Positioned(
              right: 74,
              top: 14,
              child: _artFigure(
                const Color(0xFFFFD0DD),
                const Color(0xFF1F3C88),
              ),
            ),
            Positioned(
              right: -4,
              top: 10,
              child: _artFigure(
                const Color(0xFFFDE68A),
                const Color(0xFFEA580C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artFigure(Color bodyColor, Color hairColor) {
    return SizedBox(
      width: 84,
      height: 120,
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 8,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bodyColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 0,
            child: Container(
              width: 42,
              height: 26,
              decoration: BoxDecoration(
                color: hairColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 42,
            child: Transform.rotate(
              angle: -0.16,
              child: Container(
                width: 54,
                height: 72,
                decoration: BoxDecoration(
                  color: bodyColor,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _trainingTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _trainingMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: _trainingTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: _trainingTextStyle(
              fontSize: 13,
              color: const Color(0xFF475467),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: _trainingTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF7D27B)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFB54708),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: _trainingTextStyle(
                fontSize: 12,
                color: const Color(0xFF7A2E0E),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFFB54708),
            ),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _trainingBorder),
      ),
      child: Text(
        message,
        style: _trainingTextStyle(fontSize: 13, color: _trainingMuted),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE9F2FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _trainingBlue : _trainingBorder,
          ),
        ),
        child: Text(
          label,
          style: _trainingTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? _trainingBlue : _trainingMuted,
          ),
        ),
      ),
    );
  }
}

class _ApproverTabSelector extends StatelessWidget {
  const _ApproverTabSelector({
    required this.selectedTab,
    required this.onSelected,
  });

  final _ApproverTrainingTab selectedTab;
  final ValueChanged<_ApproverTrainingTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _trainingBorder),
      ),
      child: Row(
        children: [
          _ApproverTabButton(
            label: 'All Trainings',
            isSelected: selectedTab == _ApproverTrainingTab.allTrainings,
            onTap: () => onSelected(_ApproverTrainingTab.allTrainings),
          ),
          const SizedBox(width: 6),
          _ApproverTabButton(
            label: 'Applications',
            isSelected: selectedTab == _ApproverTrainingTab.applications,
            onTap: () => onSelected(_ApproverTrainingTab.applications),
          ),
          const SizedBox(width: 6),
          _ApproverTabButton(
            label: 'Resources',
            isSelected: selectedTab == _ApproverTrainingTab.resources,
            onTap: () => onSelected(_ApproverTrainingTab.resources),
          ),
        ],
      ),
    );
  }
}

class _ApproverTabButton extends StatelessWidget {
  const _ApproverTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _trainingBlue : Colors.transparent,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: _trainingTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? _trainingBlue : _trainingMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueSummaryCard extends StatelessWidget {
  const _QueueSummaryCard({required this.count, required this.actionableCount});

  final int count;
  final int actionableCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _trainingSoftBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E6FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fact_check_outlined, color: _trainingBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applications Queue',
                  style: _trainingTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  actionableCount > 0
                      ? '$actionableCount of $count applications are waiting for your action.'
                      : '$count applications are available for review.',
                  style: _trainingTextStyle(
                    fontSize: 12,
                    color: _trainingMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingApprovalCard extends StatelessWidget {
  const _TrainingApprovalCard({
    required this.record,
    required this.isSubmitting,
    required this.onOpen,
    this.actionLabel,
    this.onPrimaryAction,
  });

  final TrainingApprovalRecord record;
  final String? actionLabel;
  final bool isSubmitting;
  final VoidCallback onOpen;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _trainingCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _trainingBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  record.title,
                  style: _trainingTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(status: record.status),
            ],
          ),
          const SizedBox(height: 10),
          _ApprovalMetaRow(
            icon: Icons.person_outline_rounded,
            value: record.applicantName,
          ),
          const SizedBox(height: 6),
          _ApprovalMetaRow(
            icon: Icons.calendar_today_outlined,
            value: _formatApprovalDateRange(record.startDate, record.endDate),
          ),
          const SizedBox(height: 6),
          _ApprovalMetaRow(
            icon: Icons.location_on_outlined,
            value: _fallbackLabel(
              record.workingStationName.isNotEmpty
                  ? record.workingStationName
                  : record.instituteName,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpen,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _trainingBorder),
                    foregroundColor: _trainingText,
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              if (actionLabel != null && onPrimaryAction != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: isSubmitting ? null : onPrimaryAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: _trainingBlue,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isSubmitting ? 'Submitting...' : actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovalMetaRow extends StatelessWidget {
  const _ApprovalMetaRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _trainingMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: _trainingTextStyle(fontSize: 12, color: _trainingMuted),
          ),
        ),
      ],
    );
  }
}

class _TrainingSectionBlock extends StatelessWidget {
  const _TrainingSectionBlock({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _trainingCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _trainingBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: _trainingTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _trainingMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ApprovalTimelineStep {
  const _ApprovalTimelineStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
}

class _ApprovalTimelineTile extends StatelessWidget {
  const _ApprovalTimelineTile({required this.step});

  final _ApprovalTimelineStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _trainingBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: step.isCompleted
                  ? const Color(0xFFE8FFF3)
                  : const Color(0xFFFFF7E5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.isCompleted
                  ? Icons.check_rounded
                  : Icons.hourglass_top_rounded,
              size: 14,
              color: step.isCompleted
                  ? const Color(0xFF12B76A)
                  : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: _trainingTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  style: _trainingTextStyle(
                    fontSize: 12,
                    color: _trainingMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingApprovalActionResult {
  const _TrainingApprovalActionResult({required this.comment});

  final String comment;
}

class _TrainingApprovalActionSheet extends StatefulWidget {
  const _TrainingApprovalActionSheet({required this.actionLabel});

  final String actionLabel;

  @override
  State<_TrainingApprovalActionSheet> createState() =>
      _TrainingApprovalActionSheetState();
}

class _TrainingApprovalActionSheetState
    extends State<_TrainingApprovalActionSheet> {
  final _commentController = TextEditingController();

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

    Navigator.of(context).pop(_TrainingApprovalActionResult(comment: comment));
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
                '${widget.actionLabel} Training Application',
                style: _trainingTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a workflow comment before submitting this action.',
                style: _trainingTextStyle(fontSize: 13, color: _trainingMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                minLines: 4,
                maxLines: 6,
                style: _trainingTextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Comment',
                  labelStyle: _trainingTextStyle(
                    fontSize: 13,
                    color: _trainingMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _trainingBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _trainingBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _trainingBlue),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _trainingBorder),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _trainingBlue,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(widget.actionLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openTrainingDetails(BuildContext context, TrainingProgram program) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TrainingDetailsScreen(training: program),
    ),
  );
}

Future<void> _openResource(
  BuildContext context,
  TrainingResource resource,
) async {
  final resourceUrl = resource.filePath.trim();
  if (resourceUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This resource does not have a linked file.'),
      ),
    );
    return;
  }

  final uri = Uri.tryParse(resourceUrl);
  if (uri == null || !uri.hasScheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This resource link is not valid.')),
    );
    return;
  }

  final didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!didLaunch && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this resource.')),
    );
  }
}

List<TrainingProgram> _filterPrograms(
  List<TrainingProgram> programs,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return programs;

  return programs.where((item) {
    return [
      item.title,
      item.organizer,
      item.location,
      item.trainingType,
      item.status.label,
    ].any((value) => value.toLowerCase().contains(normalizedQuery));
  }).toList();
}

List<TrainingResource> _filterResources(
  List<TrainingResource> resources,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return resources;

  return resources.where((item) {
    return [
      item.title,
      item.fileName,
      item.fileType,
    ].any((value) => value.toLowerCase().contains(normalizedQuery));
  }).toList();
}

List<TrainingApprovalRecord> _filterApprovalRecords(
  List<TrainingApprovalRecord> records,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return records;

  return records.where((item) {
    return [
      item.title,
      item.applicantName,
      item.workingStationName,
      item.instituteName,
      item.workflowLabel,
      item.rawStatus,
    ].any((value) => value.toLowerCase().contains(normalizedQuery));
  }).toList();
}

String? _trainingApprovalActionLabel(StaffPortalAccess access) {
  if (access.canApproveTrainingRequests) return 'Approve';
  if (access.canForwardTrainingRequests) return 'Forward';
  return null;
}

TrainingApprovalRecord? _findActionableApproval(
  List<TrainingApprovalRecord> queue,
  TrainingApprovalRecord record,
) {
  for (final item in queue) {
    if (item.trainingApplicationId.trim().isNotEmpty &&
        item.trainingApplicationId.trim() ==
            record.trainingApplicationId.trim()) {
      return item;
    }
  }
  return null;
}

String _formatApprovalDateRange(DateTime? startDate, DateTime? endDate) {
  if (startDate == null && endDate == null) return 'Schedule pending';
  if (startDate != null && endDate != null) {
    return '${_formatShortDate(startDate)} - ${_formatShortDate(endDate)}';
  }
  return _formatShortDate(startDate ?? endDate);
}

String _fallbackLabel(String value, {String fallback = 'Not available'}) {
  final normalized = value.trim();
  return normalized.isEmpty ? fallback : normalized;
}

TextStyle _trainingTextStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = _trainingText,
  double? height,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

_ChipColors _statusColors(TrainingParticipationStatus status) {
  return switch (status) {
    TrainingParticipationStatus.notApplied => const _ChipColors(
      background: Color(0xFFFFF3E8),
      foreground: Color(0xFFF97316),
    ),
    TrainingParticipationStatus.pending => const _ChipColors(
      background: Color(0xFFFFF7E5),
      foreground: Color(0xFFF59E0B),
    ),
    TrainingParticipationStatus.approved => const _ChipColors(
      background: Color(0xFFE8FFF3),
      foreground: Color(0xFF12B76A),
    ),
    TrainingParticipationStatus.rejected => const _ChipColors(
      background: Color(0xFFFFE9EC),
      foreground: Color(0xFFE11D48),
    ),
    TrainingParticipationStatus.completed => const _ChipColors(
      background: Color(0xFFE8FFF3),
      foreground: Color(0xFF12B76A),
    ),
  };
}

List<Color> _artPalette(int seed) {
  switch (seed.abs() % 3) {
    case 0:
      return const [Color(0xFFFFD58C), Color(0xFFFFF0F4)];
    case 1:
      return const [Color(0xFFCDE9FF), Color(0xFFFFF1E8)];
    default:
      return const [Color(0xFFFCE7F3), Color(0xFFFFE2B8)];
  }
}

String _formatShortDate(DateTime? value) {
  if (value == null) return 'To be scheduled';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _formatLongDate(DateTime? value) {
  if (value == null) return 'To be scheduled';
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

class _ChipColors {
  const _ChipColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
