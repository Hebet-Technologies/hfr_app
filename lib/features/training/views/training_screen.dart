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
import 'package:staffportal/core/widgets/responsive_layout.dart';

part '../widgets/training_widgets.dart';

const _trainingBlue = Color(0xFF1F6BFF);
const _trainingSurface = Colors.white;
const _trainingCard = Colors.white;
const _trainingBorder = Color(0xFFE7ECF3);
const _trainingText = Color(0xFF101828);
const _trainingMuted = Color(0xFF6B7280);
const _trainingSoftBlue = Color(0xFFF4F8FF);
const _trainingAdmissionLetterMaxBytes = 1024 * 1024;
const _trainingPageSize = 12;
const _trainingLoadMoreThreshold = 420.0;
const _trainingStickyHeaderHeight = 144.0;

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

enum _EmployeeTrainingTab { available, applications, training, resources }

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen>
    with _TrainingApplicationFlow<TrainingScreen> {
  _EmployeeTrainingTab _selectedTab = _EmployeeTrainingTab.available;
  String _query = '';
  TrainingParticipationStatus? _selectedStatus;
  DateTimeRange? _dateRange;
  int _visibleAvailableTrainings = _trainingPageSize;
  int _visibleApplications = _trainingPageSize;
  int _visibleMyTrainings = _trainingPageSize;
  int _visibleResources = _trainingPageSize;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffPortalAccessProvider);
    final canOpenTrainingApprovals =
        access.canViewTrainingRequests ||
        access.canForwardTrainingRequests ||
        access.canApproveTrainingRequests ||
        access.canDenyTrainingRequests ||
        access.canCreateTrainingResult;
    if (!access.hasEmployeeProfile && canOpenTrainingApprovals) {
      return _ApproverTrainingHub(standalone: widget.standalone);
    }

    final state = ref.watch(trainingViewModelProvider);
    final sharedState = ref.watch(staffRequestsViewModelProvider);
    final trainingResources = _mergeTrainingResources(
      state.resources,
      _resourcesFromHomeResources(sharedState.resources),
    );
    final availableTrainingSource = state.latestTrainings
        .where(_isRequestableAvailableTraining)
        .toList();
    final availableTrainings = _filterPrograms(
      availableTrainingSource,
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
    final showTrainingFilters = _selectedTab != _EmployeeTrainingTab.resources;
    final pagePadding = AppBreakpoints.pagePadding(context);

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
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) => _handleEmployeeScroll(
            notification,
            availableCount: availableTrainings.length,
            applicationCount: myApplications.length,
            trainingCount: myTrainings.length,
            resourceCount: resources.length,
          ),
          child: RefreshIndicator(
            color: _trainingBlue,
            onRefresh: () =>
                ref.read(trainingViewModelProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: ResponsiveWidth(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding.left,
                        pagePadding.top,
                        pagePadding.right,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Trainings',
                              style: _trainingTextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (canOpenTrainingApprovals)
                            IconButton(
                              tooltip: 'Training approvals',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const _ApproverTrainingHub(
                                      standalone: true,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.assignment_turned_in_outlined,
                                color: _trainingBlue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TrainingStickyHeaderDelegate(
                    height: _trainingStickyHeaderHeight,
                    child: ResponsiveWidth(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          pagePadding.left,
                          12,
                          pagePadding.right,
                          12,
                        ),
                        child: Column(
                          children: [
                            _SearchToolbar(
                              hintText: _employeeTrainingSearchHint(
                                _selectedTab,
                              ),
                              onChanged: (value) => setState(() {
                                _query = value;
                                _resetEmployeePaging();
                              }),
                              filterCount: showTrainingFilters
                                  ? _trainingFilterCount(
                                      status: _selectedStatus,
                                      dateRange: _dateRange,
                                    )
                                  : 0,
                              onFilterPressed: showTrainingFilters
                                  ? _openStatusFilter
                                  : null,
                              onCalendarPressed: showTrainingFilters
                                  ? _openDateFilter
                                  : null,
                              showFilterActions: showTrainingFilters,
                            ),
                            const SizedBox(height: 14),
                            _EmployeeTrainingTabSelector(
                              selectedTab: _selectedTab,
                              onSelected: _selectEmployeeTab,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ResponsiveWidth(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding.left,
                        16,
                        pagePadding.right,
                        pagePadding.bottom,
                      ),
                      child: _selectedTab == _EmployeeTrainingTab.available
                          ? _buildAvailableTrainings(
                              availableTrainings,
                              visibleCount: _visibleAvailableTrainings,
                              isLoading: state.isLoading,
                              sourceIsEmpty: availableTrainingSource.isEmpty,
                            )
                          : _selectedTab == _EmployeeTrainingTab.applications
                          ? _buildMyApplications(
                              myApplications,
                              visibleCount: _visibleApplications,
                            )
                          : _selectedTab == _EmployeeTrainingTab.training
                          ? _buildMyTraining(
                              myTrainings,
                              visibleCount: _visibleMyTrainings,
                            )
                          : _buildTrainingResources(
                              resources,
                              visibleCount: _visibleResources,
                              isLoading: isLoading,
                              sourceIsEmpty: trainingResources.isEmpty,
                            ),
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

  Widget _buildAvailableTrainings(
    List<TrainingProgram> items, {
    required int visibleCount,
    required bool isLoading,
    required bool sourceIsEmpty,
  }) {
    if (isLoading && sourceIsEmpty) {
      return const _TrainingListShimmer();
    }
    if (items.isEmpty) {
      return const _EmptyCard(message: 'No available trainings found');
    }
    final visibleItems = _pagedItems(items, visibleCount);
    return Column(
      children: [
        ...visibleItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AvailableTrainingCard(
              program: item,
              onView: () => _openTrainingDetails(context, item),
            ),
          ),
        ),
        if (visibleItems.length < items.length)
          _TrainingPagingFooter(
            visibleCount: visibleItems.length,
            totalCount: items.length,
            label: 'trainings',
          ),
      ],
    );
  }

  Widget _buildMyApplications(
    List<TrainingProgram> items, {
    required int visibleCount,
  }) {
    if (items.isEmpty) {
      return const _EmptyCard(message: 'No training applications found');
    }
    final visibleItems = _pagedItems(items, visibleCount);
    return Column(
      children: [
        ...visibleItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TrainingStatusTile(
              program: item,
              onTap: () => _openTrainingDetails(context, item),
            ),
          ),
        ),
        if (visibleItems.length < items.length)
          _TrainingPagingFooter(
            visibleCount: visibleItems.length,
            totalCount: items.length,
            label: 'applications',
          ),
      ],
    );
  }

  Widget _buildMyTraining(
    List<TrainingProgram> items, {
    required int visibleCount,
  }) {
    if (items.isEmpty) {
      return const _EmptyCard(message: 'No training history found');
    }
    final visibleItems = _pagedItems(items, visibleCount);
    return Column(
      children: [
        ...visibleItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TrainingStatusTile(
              program: item,
              onTap: () => _openTrainingDetails(context, item),
            ),
          ),
        ),
        if (visibleItems.length < items.length)
          _TrainingPagingFooter(
            visibleCount: visibleItems.length,
            totalCount: items.length,
            label: 'records',
          ),
      ],
    );
  }

  Widget _buildTrainingResources(
    List<TrainingResource> items, {
    required int visibleCount,
    required bool isLoading,
    required bool sourceIsEmpty,
  }) {
    if (isLoading && sourceIsEmpty) {
      return const _TrainingListShimmer();
    }
    if (items.isEmpty) {
      return const _EmptyCard(message: 'No resources available');
    }
    final visibleItems = _pagedItems(items, visibleCount);
    return Column(
      children: [
        ...visibleItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ResourceTile(
              resource: item,
              onTap: () => _openResource(context, item),
            ),
          ),
        ),
        if (visibleItems.length < items.length)
          _TrainingPagingFooter(
            visibleCount: visibleItems.length,
            totalCount: items.length,
            label: 'resources',
          ),
      ],
    );
  }

  void _selectEmployeeTab(_EmployeeTrainingTab tab) {
    if (_selectedTab == tab) return;
    setState(() {
      _selectedTab = tab;
      _resetEmployeePaging();
      if (tab == _EmployeeTrainingTab.resources) {
        _selectedStatus = null;
        _dateRange = null;
      }
    });
  }

  bool _handleEmployeeScroll(
    ScrollNotification notification, {
    required int availableCount,
    required int applicationCount,
    required int trainingCount,
    required int resourceCount,
  }) {
    if (notification.metrics.axis != Axis.vertical ||
        notification.metrics.extentAfter > _trainingLoadMoreThreshold) {
      return false;
    }

    switch (_selectedTab) {
      case _EmployeeTrainingTab.available:
        _increaseVisibleCount(
          totalCount: availableCount,
          currentCount: _visibleAvailableTrainings,
          update: (value) => _visibleAvailableTrainings = value,
        );
        break;
      case _EmployeeTrainingTab.applications:
        _increaseVisibleCount(
          totalCount: applicationCount,
          currentCount: _visibleApplications,
          update: (value) => _visibleApplications = value,
        );
        break;
      case _EmployeeTrainingTab.training:
        _increaseVisibleCount(
          totalCount: trainingCount,
          currentCount: _visibleMyTrainings,
          update: (value) => _visibleMyTrainings = value,
        );
        break;
      case _EmployeeTrainingTab.resources:
        _increaseVisibleCount(
          totalCount: resourceCount,
          currentCount: _visibleResources,
          update: (value) => _visibleResources = value,
        );
        break;
    }
    return false;
  }

  void _increaseVisibleCount({
    required int totalCount,
    required int currentCount,
    required ValueChanged<int> update,
  }) {
    if (currentCount >= totalCount) return;
    setState(() => update(_nextPageCount(currentCount, totalCount)));
  }

  void _resetEmployeePaging() {
    _visibleAvailableTrainings = _trainingPageSize;
    _visibleApplications = _trainingPageSize;
    _visibleMyTrainings = _trainingPageSize;
    _visibleResources = _trainingPageSize;
  }

  Future<void> _openStatusFilter() async {
    final result = await showModalBottomSheet<_TrainingStatusFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TrainingStatusFilterSheet(selectedStatus: _selectedStatus),
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedStatus = result.status;
      _resetEmployeePaging();
    });
  }

  Future<void> _openDateFilter() async {
    final range = await _pickTrainingDateRange(context, _dateRange);
    if (!mounted || range == _dateRange) return;
    setState(() {
      _dateRange = range;
      _resetEmployeePaging();
    });
  }
}

mixin _TrainingApplicationFlow<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  Future<void> _submitApplication(TrainingProgram program) async {
    final messenger = ScaffoldMessenger.of(context);
    var application = program;
    String? admissionLetterPath;
    String? admissionLetterName;

    final needsInstitute =
        (application.shortCourseDescriptionId ?? '').trim().isEmpty &&
        (application.instituteId ?? '').trim().isEmpty;
    if (needsInstitute) {
      final request = await showModalBottomSheet<_TrainingRequestFormResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _TrainingRequestSheet(
          program: application,
          requiresAdmissionLetter: _requiresAdmissionLetter(application),
          onLoadCountries: (forceRefresh) =>
              _loadTrainingCountries(forceRefresh: forceRefresh),
          onLoadInstitutes: (country, forceRefresh) => _loadTrainingInstitutes(
            application,
            country,
            forceRefresh: forceRefresh,
          ),
          onPickAdmissionLetter: () => _pickTrainingPdf(
            context: context,
            maxBytes: _trainingAdmissionLetterMaxBytes,
          ),
        ),
      );
      if (!mounted || request == null) return;
      application = application.copyWith(
        instituteId: request.institute.id,
        location: request.institute.name,
        startDate: request.startDate,
        endDate: request.endDate,
      );
      admissionLetterPath = request.admissionLetterPath;
      admissionLetterName = request.admissionLetterName;
    }

    if (_requiresAdmissionLetter(application) &&
        (admissionLetterPath ?? '').trim().isEmpty) {
      final file = await _pickTrainingPdf(
        context: context,
        maxBytes: _trainingAdmissionLetterMaxBytes,
      );
      if (!mounted || file == null) return;
      admissionLetterPath = file.$1;
      admissionLetterName = file.$2;
    }

    try {
      await ref
          .read(trainingViewModelProvider.notifier)
          .applyForTraining(
            application,
            admissionLetterPath: admissionLetterPath,
            admissionLetterName: admissionLetterName,
          );
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

  Future<List<TrainingCountry>> _loadTrainingCountries({
    bool forceRefresh = false,
  }) {
    return ref
        .read(trainingRepositoryProvider)
        .fetchTrainingCountries(forceRefresh: forceRefresh);
  }

  Future<List<TrainingInstitute>> _loadTrainingInstitutes(
    TrainingProgram program,
    TrainingCountry country, {
    bool forceRefresh = false,
  }) {
    final educationLevelId = (program.educationLevelId ?? '').trim();
    if (educationLevelId.isEmpty) {
      throw Exception('This training is missing an education level.');
    }

    return ref
        .read(trainingRepositoryProvider)
        .fetchInstitutes(
          countryCode: country.code,
          educationLevelId: educationLevelId,
          forceRefresh: forceRefresh,
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
  TrainingParticipationStatus? _selectedStatus;
  DateTimeRange? _dateRange;
  int _visibleApproverTrainings = _trainingPageSize;
  int _visibleApprovals = _trainingPageSize;
  int _visibleApproverResources = _trainingPageSize;

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
    final visibleTrainings = _pagedItems(trainings, _visibleApproverTrainings);
    final visibleApprovals = _pagedItems(approvals, _visibleApprovals);
    final visibleResources = _pagedItems(resources, _visibleApproverResources);
    final isLoading = state.isLoading || sharedState.isLoading;
    final actionLabels = _trainingApprovalActions(access);
    final pagePadding = AppBreakpoints.pagePadding(context);

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
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) => _handleApproverScroll(
            notification,
            trainingCount: trainings.length,
            approvalCount: approvals.length,
            resourceCount: resources.length,
          ),
          child: RefreshIndicator(
            color: _trainingBlue,
            onRefresh: () =>
                ref.read(trainingViewModelProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: ResponsiveWidth(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding.left,
                        pagePadding.top,
                        pagePadding.right,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Training',
                            style: _trainingTextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            _InlineBanner(
                              message: state.errorMessage!,
                              onClose: () => ref
                                  .read(trainingViewModelProvider.notifier)
                                  .clearError(),
                              actionLabel: 'Retry',
                              onAction: () => ref
                                  .read(trainingViewModelProvider.notifier)
                                  .refreshApprovalRequests(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TrainingStickyHeaderDelegate(
                    height: _trainingStickyHeaderHeight,
                    child: ResponsiveWidth(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          pagePadding.left,
                          12,
                          pagePadding.right,
                          12,
                        ),
                        child: Column(
                          children: [
                            _ApproverTabSelector(
                              selectedTab: _selectedTab,
                              onSelected: _selectApproverTab,
                            ),
                            const SizedBox(height: 14),
                            _SearchToolbar(
                              hintText: 'Search...',
                              onChanged: (value) => setState(() {
                                _query = value;
                                _resetApproverPaging();
                              }),
                              filterCount: _trainingFilterCount(
                                status: _selectedStatus,
                                dateRange: _dateRange,
                              ),
                              onFilterPressed: _openStatusFilter,
                              onCalendarPressed: _openDateFilter,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ResponsiveWidth(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding.left,
                        18,
                        pagePadding.right,
                        pagePadding.bottom,
                      ),
                      child: _selectedTab == _ApproverTrainingTab.allTrainings
                          ? _buildApproverTrainings(
                              trainings: trainings,
                              visibleTrainings: visibleTrainings,
                              isLoading: isLoading,
                              sourceIsEmpty: latestTrainings.isEmpty,
                            )
                          : _selectedTab == _ApproverTrainingTab.applications
                          ? _buildApproverApplications(
                              approvals: approvals,
                              visibleApprovals: visibleApprovals,
                              actionableCount: actionableCount,
                              actionLabels: actionLabels,
                              approvalQueue: state.approvalQueue,
                              isLoading: state.isLoading,
                              isSubmitting: state.isSubmittingApproval,
                              sourceIsEmpty:
                                  state.approvalQueue.isEmpty &&
                                  state.trainingRequests.isEmpty,
                            )
                          : _buildApproverResources(
                              resources: resources,
                              visibleResources: visibleResources,
                              isLoading: isLoading,
                              sourceIsEmpty: trainingResources.isEmpty,
                            ),
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

  Widget _buildApproverTrainings({
    required List<TrainingProgram> trainings,
    required List<TrainingProgram> visibleTrainings,
    required bool isLoading,
    required bool sourceIsEmpty,
  }) {
    if (isLoading && sourceIsEmpty) {
      return const _TrainingListShimmer();
    }
    if (trainings.isEmpty) {
      return const _EmptyCard(message: 'No trainings found');
    }

    return Column(
      children: [
        ...visibleTrainings.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _LatestTrainingCard(
              program: item,
              onPressed: () => _openTrainingDetails(context, item),
            ),
          ),
        ),
        if (visibleTrainings.length < trainings.length)
          _TrainingPagingFooter(
            visibleCount: visibleTrainings.length,
            totalCount: trainings.length,
            label: 'trainings',
          ),
      ],
    );
  }

  Widget _buildApproverApplications({
    required List<TrainingApprovalRecord> approvals,
    required List<TrainingApprovalRecord> visibleApprovals,
    required int actionableCount,
    required List<String> actionLabels,
    required List<TrainingApprovalRecord> approvalQueue,
    required bool isLoading,
    required bool isSubmitting,
    required bool sourceIsEmpty,
  }) {
    return Column(
      children: [
        _QueueSummaryCard(
          count: approvals.length,
          actionableCount: actionableCount,
        ),
        const SizedBox(height: 14),
        if (isLoading && sourceIsEmpty)
          const _TrainingApprovalShimmer()
        else if (approvals.isEmpty)
          const _EmptyCard(
            message: 'No training applications are waiting for review.',
          )
        else ...[
          ...visibleApprovals.map((record) {
            final actionableRecord = _findActionableApproval(
              approvalQueue,
              record,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TrainingApprovalCard(
                record: record,
                actionLabels: actionLabels,
                isSubmitting: isSubmitting,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        _TrainingApprovalDetailsScreen(record: record),
                  ),
                ),
                onAction: actionLabels.isNotEmpty && actionableRecord != null
                    ? (action) => _submitAction(actionableRecord, action)
                    : null,
              ),
            );
          }),
          if (visibleApprovals.length < approvals.length)
            _TrainingPagingFooter(
              visibleCount: visibleApprovals.length,
              totalCount: approvals.length,
              label: 'applications',
            ),
        ],
      ],
    );
  }

  Widget _buildApproverResources({
    required List<TrainingResource> resources,
    required List<TrainingResource> visibleResources,
    required bool isLoading,
    required bool sourceIsEmpty,
  }) {
    if (isLoading && sourceIsEmpty) {
      return const _TrainingListShimmer();
    }
    if (resources.isEmpty) {
      return const _EmptyCard(message: 'No resources found');
    }

    return Column(
      children: [
        ...visibleResources.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ResourceTile(
              resource: item,
              onTap: () => _openResource(context, item),
            ),
          ),
        ),
        if (visibleResources.length < resources.length)
          _TrainingPagingFooter(
            visibleCount: visibleResources.length,
            totalCount: resources.length,
            label: 'resources',
          ),
      ],
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
    setState(() {
      _selectedTab = tab;
      _resetApproverPaging();
    });

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
    setState(() {
      _selectedStatus = result.status;
      _resetApproverPaging();
    });
  }

  Future<void> _openDateFilter() async {
    final range = await _pickTrainingDateRange(context, _dateRange);
    if (!mounted || range == _dateRange) return;
    setState(() {
      _dateRange = range;
      _resetApproverPaging();
    });
  }

  bool _handleApproverScroll(
    ScrollNotification notification, {
    required int trainingCount,
    required int approvalCount,
    required int resourceCount,
  }) {
    if (notification.metrics.axis != Axis.vertical ||
        notification.metrics.extentAfter > _trainingLoadMoreThreshold) {
      return false;
    }

    switch (_selectedTab) {
      case _ApproverTrainingTab.allTrainings:
        _increaseVisibleCount(
          totalCount: trainingCount,
          currentCount: _visibleApproverTrainings,
          update: (value) => _visibleApproverTrainings = value,
        );
        break;
      case _ApproverTrainingTab.applications:
        _increaseVisibleCount(
          totalCount: approvalCount,
          currentCount: _visibleApprovals,
          update: (value) => _visibleApprovals = value,
        );
        break;
      case _ApproverTrainingTab.resources:
        _increaseVisibleCount(
          totalCount: resourceCount,
          currentCount: _visibleApproverResources,
          update: (value) => _visibleApproverResources = value,
        );
        break;
    }
    return false;
  }

  void _increaseVisibleCount({
    required int totalCount,
    required int currentCount,
    required ValueChanged<int> update,
  }) {
    if (currentCount >= totalCount) return;
    setState(() => update(_nextPageCount(currentCount, totalCount)));
  }

  void _resetApproverPaging() {
    _visibleApproverTrainings = _trainingPageSize;
    _visibleApprovals = _trainingPageSize;
    _visibleApproverResources = _trainingPageSize;
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

class _LatestTrainingsScreenState extends ConsumerState<LatestTrainingsScreen>
    with _TrainingApplicationFlow<LatestTrainingsScreen> {
  String _query = '';
  TrainingParticipationStatus? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingViewModelProvider);
    final items = _filterPrograms(
      state.latestTrainings.where(_isRequestableAvailableTraining).toList(),
      _query,
      status: _selectedStatus,
      dateRange: _dateRange,
    );

    return Scaffold(
      backgroundColor: _trainingSurface,
      appBar: _TrainingAppBar(title: 'Available Trainings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _SearchToolbar(
            hintText: 'Search available trainings',
            onChanged: (value) => setState(() => _query = value),
            filterCount: _trainingFilterCount(
              status: _selectedStatus,
              dateRange: _dateRange,
            ),
            onFilterPressed: _openStatusFilter,
            onCalendarPressed: _openDateFilter,
          ),
          const SizedBox(height: 16),
          if (state.isLoading && state.latestTrainings.isEmpty)
            const _TrainingListShimmer()
          else if (items.isEmpty)
            const _EmptyCard(
              message: 'No available trainings match your search',
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AvailableTrainingCard(
                  program: item,
                  onView: () => _openTrainingDetails(context, item),
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
                      onDelete: _canDeleteTrainingApplication(item)
                          ? () => _deleteTrainingApplication(item)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _TrainingEmployeeActions(
                      program: item,
                      onEdit: _canEditTrainingApplication(item)
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
            ...items.map((item) {
              final attachment = item.resources.isNotEmpty
                  ? item.resources.first
                  : null;
              final canEdit = _canEditTrainingApplication(item);
              final canDelete = _canDeleteTrainingApplication(item);
              final canPrintLetter = _canPrintTrainingLetter(item);
              final hasActions =
                  canEdit || canDelete || attachment != null || canPrintLetter;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    _TrainingStatusTile(
                      program: item,
                      onTap: () => _openTrainingDetails(context, item),
                      onDelete: canDelete
                          ? () => _deleteTrainingApplication(item)
                          : null,
                    ),
                    if (hasActions) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (canEdit)
                              _TrainingActionChip(
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                onTap: () => _editTrainingApplication(item),
                              ),
                            if (attachment != null)
                              _TrainingActionChip(
                                icon: Icons.attach_file_rounded,
                                label: 'Admission',
                                onTap: () => _openResource(context, attachment),
                              ),
                            if (canPrintLetter)
                              _TrainingActionChip(
                                icon: Icons.description_outlined,
                                label: 'Letter',
                                onTap: () => _openTrainingLetter(item),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
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

  Future<void> _openTrainingLetter(TrainingProgram program) async {
    final url = ref.read(trainingRepositoryProvider).trainingLetterUrl(program);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    var opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

class _TrainingDetailsScreenState extends ConsumerState<TrainingDetailsScreen>
    with _TrainingApplicationFlow<TrainingDetailsScreen> {
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
