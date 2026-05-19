part of '../views/training_screen.dart';

class _TrainingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TrainingAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _trainingSurface,
      foregroundColor: _trainingText,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: _trainingText),
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
  const _SearchToolbar({
    required this.hintText,
    required this.onChanged,
    this.filterCount = 0,
    this.onFilterPressed,
    this.onCalendarPressed,
    this.showFilterActions = true,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final int filterCount;
  final VoidCallback? onFilterPressed;
  final VoidCallback? onCalendarPressed;
  final bool showFilterActions;

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
        if (showFilterActions) ...[
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.tune_rounded,
            onPressed: onFilterPressed,
            isActive: filterCount > 0,
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.calendar_month_outlined,
            onPressed: onCalendarPressed,
            isActive: filterCount > 0,
          ),
        ],
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.onPressed,
    required this.isActive,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: 42,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isActive
              ? const Color(0xFFE9F2FF)
              : const Color(0xFFF8FAFC),
          side: BorderSide(color: isActive ? _trainingBlue : _trainingBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 19,
          color: isActive ? _trainingBlue : _trainingMuted,
        ),
      ),
    );
  }
}

class _TrainingCarouselShimmer extends StatelessWidget {
  const _TrainingCarouselShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const SizedBox(
          width: 280,
          child: _TrainingSkeletonCard(tall: true),
        ),
      ),
    );
  }
}

class _TrainingListShimmer extends StatelessWidget {
  const _TrainingListShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 14),
          child: const _TrainingSkeletonCard(),
        ),
      ),
    );
  }
}

class _TrainingApprovalShimmer extends StatelessWidget {
  const _TrainingApprovalShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          child: const _TrainingSkeletonCard(compact: true),
        ),
      ),
    );
  }
}

class _TrainingSkeletonCard extends StatelessWidget {
  const _TrainingSkeletonCard({this.tall = false, this.compact = false});

  final bool tall;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _TrainingShimmer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _trainingCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _trainingBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tall) ...[
              const _TrainingSkeletonBox(height: 104, radius: 18),
              const SizedBox(height: 12),
            ],
            const _TrainingSkeletonBox(width: 86, height: 22, radius: 999),
            const SizedBox(height: 12),
            const _TrainingSkeletonBox(height: 16, radius: 8),
            const SizedBox(height: 8),
            const _TrainingSkeletonBox(width: 190, height: 14, radius: 8),
            if (!compact) ...[
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(child: _TrainingSkeletonBox(height: 12, radius: 8)),
                  SizedBox(width: 18),
                  _TrainingSkeletonBox(width: 82, height: 32, radius: 12),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainingShimmer extends StatefulWidget {
  const _TrainingShimmer({required this.child});

  final Widget child;

  @override
  State<_TrainingShimmer> createState() => _TrainingShimmerState();
}

class _TrainingShimmerState extends State<_TrainingShimmer>
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
                Color(0xFFE7ECF3),
                Color(0xFFF7FAFE),
                Color(0xFFE7ECF3),
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

class _TrainingSkeletonBox extends StatelessWidget {
  const _TrainingSkeletonBox({
    this.width,
    required this.height,
    required this.radius,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECF3),
        borderRadius: BorderRadius.circular(radius),
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

class _TrainingPickerSheet extends StatelessWidget {
  const _TrainingPickerSheet({
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.onSearchChanged,
    required this.emptyMessage,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String title;
  final String subtitle;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final String emptyMessage;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.76,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _trainingBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _trainingTextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: _trainingTextStyle(fontSize: 12, color: _trainingMuted),
          ),
          const SizedBox(height: 14),
          TextField(
            autofocus: true,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _trainingBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _trainingBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _trainingBlue),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: itemCount == 0
                ? Center(
                    child: Text(
                      emptyMessage,
                      style: _trainingTextStyle(
                        fontSize: 13,
                        color: _trainingMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: itemCount,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: itemBuilder,
                  ),
          ),
        ],
      ),
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
  const _TrainingStatusTile({
    required this.program,
    required this.onTap,
    this.onDelete,
  });

  final TrainingProgram program;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

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
            if (onDelete != null) ...[
              IconButton(
                tooltip: 'Delete application',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD14343),
                ),
              ),
            ] else
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD0D5DD)),
          ],
        ),
      ),
    );
  }
}

class _TrainingEmployeeActions extends StatelessWidget {
  const _TrainingEmployeeActions({
    required this.program,
    required this.onUploadContract,
    required this.onGenerateContract,
    required this.onUploadResult,
    required this.onLetter,
    this.onEdit,
  });

  final TrainingProgram program;
  final VoidCallback? onEdit;
  final VoidCallback onUploadContract;
  final VoidCallback onGenerateContract;
  final VoidCallback onUploadResult;
  final VoidCallback onLetter;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onEdit != null)
          _TrainingActionChip(
            icon: Icons.edit_outlined,
            label: 'Edit',
            onTap: onEdit!,
          ),
        _TrainingActionChip(
          icon: Icons.upload_file_outlined,
          label: 'Contract',
          onTap: onUploadContract,
        ),
        _TrainingActionChip(
          icon: Icons.receipt_long_outlined,
          label: 'Generate',
          onTap: onGenerateContract,
        ),
        _TrainingActionChip(
          icon: Icons.school_outlined,
          label: 'Result',
          onTap: onUploadResult,
        ),
        _TrainingActionChip(
          icon: Icons.description_outlined,
          label: 'Letter',
          onTap: onLetter,
        ),
      ],
    );
  }
}

class _TrainingActionChip extends StatelessWidget {
  const _TrainingActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: _trainingBlue),
      label: Text(
        label,
        style: _trainingTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _trainingBlue,
        ),
      ),
      onPressed: onTap,
      backgroundColor: _trainingSoftBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD8E6FF)),
      ),
    );
  }
}

class _TrainingEditSheet extends StatefulWidget {
  const _TrainingEditSheet({required this.program});

  final TrainingProgram program;

  @override
  State<_TrainingEditSheet> createState() => _TrainingEditSheetState();
}

class _TrainingEditSheetState extends State<_TrainingEditSheet> {
  late DateTime _startDate = widget.program.startDate ?? DateTime.now();
  late DateTime _endDate =
      widget.program.endDate ?? DateTime.now().add(const Duration(days: 1));
  String? _filePath;
  String? _fileName;

  Future<void> _pickDate(bool start) async {
    final current = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickFile() async {
    final file = await _pickTrainingPdf();
    if (file == null) return;
    setState(() {
      _filePath = file.$1;
      _fileName = file.$2;
    });
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
              'Edit Training Request',
              style: _trainingTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.event_rounded, size: 18),
                    label: Text(_formatShortDate(_startDate)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.event_available_rounded, size: 18),
                    label: Text(_formatShortDate(_endDate)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: Text(_fileName ?? 'Admission Letter'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _trainingBlue),
                onPressed: () => Navigator.of(context).pop(
                  _TrainingEditResult(
                    startDate: _startDate,
                    endDate: _endDate,
                    filePath: _filePath,
                    fileName: _fileName,
                  ),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingEditResult {
  const _TrainingEditResult({
    required this.startDate,
    required this.endDate,
    this.filePath,
    this.fileName,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String? filePath;
  final String? fileName;
}

class _TrainingResultUploadSheet extends StatefulWidget {
  const _TrainingResultUploadSheet({required this.options});

  final List<RequestLookupOption> options;

  @override
  State<_TrainingResultUploadSheet> createState() =>
      _TrainingResultUploadSheetState();
}

class _TrainingResultUploadSheetState
    extends State<_TrainingResultUploadSheet> {
  final _idController = TextEditingController();
  String? _filePath;
  String? _fileName;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await _pickTrainingPdf();
    if (file == null) return;
    setState(() {
      _filePath = file.$1;
      _fileName = file.$2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _TrainingSimpleSheet(
      title: 'Upload Training Result',
      children: [
        if (widget.options.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _idController.text.trim().isEmpty
                ? null
                : _idController.text.trim(),
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Training Result'),
            items: widget.options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.id,
                    child: Text(
                      option.subtitle?.trim().isNotEmpty == true
                          ? '${option.label} • ${option.subtitle}'
                          : option.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) _idController.text = value;
            },
          )
        else
          TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: 'Training Student Result ID',
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file_rounded, size: 18),
          label: Text(_fileName ?? 'Training Result File'),
        ),
      ],
      onSubmit: () {
        final id = _idController.text.trim();
        if (id.isEmpty || _filePath == null) return;
        Navigator.of(context).pop(
          _TrainingResultUploadResult(
            trainingStudentResultId: id,
            filePath: _filePath!,
            fileName: _fileName ?? 'training-result.pdf',
          ),
        );
      },
    );
  }
}

class _TrainingResultUploadResult {
  const _TrainingResultUploadResult({
    required this.trainingStudentResultId,
    required this.filePath,
    required this.fileName,
  });

  final String trainingStudentResultId;
  final String filePath;
  final String fileName;
}

class _TrainingContractSheet extends StatefulWidget {
  const _TrainingContractSheet({
    required this.referees,
    required this.directors,
    required this.costTypes,
  });

  final List<RequestLookupOption> referees;
  final List<RequestLookupOption> directors;
  final List<RequestLookupOption> costTypes;

  @override
  State<_TrainingContractSheet> createState() => _TrainingContractSheetState();
}

class _TrainingContractSheetState extends State<_TrainingContractSheet> {
  final _refereeController = TextEditingController();
  final _directorController = TextEditingController();
  final _costTypeController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitController = TextEditingController(text: 'TZS');

  @override
  void dispose() {
    _refereeController.dispose();
    _directorController.dispose();
    _costTypeController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TrainingSimpleSheet(
      title: 'Generate Training Contract',
      children: [
        _LookupOrTextField(
          controller: _refereeController,
          label: 'Referee',
          fallbackLabel: 'Referee ID',
          options: widget.referees,
        ),
        const SizedBox(height: 10),
        _LookupOrTextField(
          controller: _directorController,
          label: 'Director',
          fallbackLabel: 'Director ID',
          options: widget.directors,
        ),
        const SizedBox(height: 10),
        _LookupOrTextField(
          controller: _costTypeController,
          label: 'Cost Type',
          fallbackLabel: 'Cost Type ID',
          options: widget.costTypes,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: 'Cost Amount'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _unitController,
          decoration: const InputDecoration(labelText: 'Unit'),
        ),
      ],
      onSubmit: () {
        if (_refereeController.text.trim().isEmpty ||
            _directorController.text.trim().isEmpty ||
            _costTypeController.text.trim().isEmpty ||
            _amountController.text.trim().isEmpty) {
          return;
        }
        Navigator.of(context).pop(
          _TrainingContractResult(
            refereeId: _refereeController.text.trim(),
            directorId: _directorController.text.trim(),
            costTypeId: _costTypeController.text.trim(),
            costAmount: _amountController.text.trim(),
            unit: _unitController.text.trim().isEmpty
                ? 'TZS'
                : _unitController.text.trim(),
          ),
        );
      },
    );
  }
}

class _TrainingContractResult {
  const _TrainingContractResult({
    required this.refereeId,
    required this.directorId,
    required this.costTypeId,
    required this.costAmount,
    required this.unit,
  });

  final String refereeId;
  final String directorId;
  final String costTypeId;
  final String costAmount;
  final String unit;
}

class _LookupOrTextField extends StatelessWidget {
  const _LookupOrTextField({
    required this.controller,
    required this.label,
    required this.fallbackLabel,
    required this.options,
  });

  final TextEditingController controller;
  final String label;
  final String fallbackLabel;
  final List<RequestLookupOption> options;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(labelText: fallbackLabel),
      );
    }

    final value = controller.text.trim();
    return DropdownButtonFormField<String>(
      initialValue: options.any((option) => option.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.id,
              child: Text(
                option.subtitle?.trim().isNotEmpty == true
                    ? '${option.label} • ${option.subtitle}'
                    : option.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) controller.text = value;
      },
    );
  }
}

class _TrainingSimpleSheet extends StatelessWidget {
  const _TrainingSimpleSheet({
    required this.title,
    required this.children,
    required this.onSubmit,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSubmit;

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
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              title,
              style: _trainingTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _trainingBlue),
              onPressed: onSubmit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<(String, String)?> _pickTrainingPdf() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  if (file.path == null) return null;
  return (file.path!, file.name);
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
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

class _TrainingStatusFilterResult {
  const _TrainingStatusFilterResult(this.status);

  final TrainingParticipationStatus? status;
}

class _TrainingStatusFilterSheet extends StatefulWidget {
  const _TrainingStatusFilterSheet({required this.selectedStatus});

  final TrainingParticipationStatus? selectedStatus;

  @override
  State<_TrainingStatusFilterSheet> createState() =>
      _TrainingStatusFilterSheetState();
}

class _TrainingStatusFilterSheetState
    extends State<_TrainingStatusFilterSheet> {
  late TrainingParticipationStatus? _selectedStatus = widget.selectedStatus;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
              'Filter Training',
              style: _trainingTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Status',
              style: _trainingTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _trainingMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChipButton(
                  label: 'All',
                  isSelected: _selectedStatus == null,
                  onTap: () => setState(() => _selectedStatus = null),
                ),
                ...TrainingParticipationStatus.values.map(
                  (status) => _FilterChipButton(
                    label: status.label,
                    isSelected: _selectedStatus == status,
                    onTap: () => setState(() => _selectedStatus = status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const _TrainingStatusFilterResult(null)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _trainingMuted,
                      side: const BorderSide(color: _trainingBorder),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: _trainingBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_TrainingStatusFilterResult(_selectedStatus)),
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
    this.actionLabels = const [],
    this.onAction,
  });

  final TrainingApprovalRecord record;
  final List<String> actionLabels;
  final bool isSubmitting;
  final VoidCallback onOpen;
  final ValueChanged<String>? onAction;

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
          OutlinedButton(
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _trainingBorder),
              foregroundColor: _trainingText,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Center(child: Text('View Details')),
          ),
          if (actionLabels.isNotEmpty && onAction != null) ...[
            const SizedBox(height: 10),
            _TrainingApprovalActionButtons(
              actions: actionLabels,
              isSubmitting: isSubmitting,
              onAction: onAction!,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrainingApprovalActionButtons extends StatelessWidget {
  const _TrainingApprovalActionButtons({
    required this.actions,
    required this.isSubmitting,
    required this.onAction,
    this.compact = false,
  });

  final List<String> actions;
  final bool isSubmitting;
  final ValueChanged<String> onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    if (actions.length == 1) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _trainingBlue,
          minimumSize: Size.fromHeight(compact ? 42 : 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
          ),
        ),
        onPressed: isSubmitting ? null : () => onAction(actions.first),
        child: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text('${actions.first} Application'),
      );
    }

    return Row(
      children: actions.map((action) {
        final isDeny = action.trim().toLowerCase() == 'deny';
        final button = isDeny
            ? OutlinedButton(
                onPressed: isSubmitting ? null : () => onAction(action),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD92D20),
                  side: const BorderSide(color: Color(0xFFFDA29B)),
                  minimumSize: Size.fromHeight(compact ? 42 : 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(compact ? 12 : 14),
                  ),
                ),
                child: Text(isSubmitting ? 'Submitting...' : action),
              )
            : FilledButton(
                onPressed: isSubmitting ? null : () => onAction(action),
                style: FilledButton.styleFrom(
                  backgroundColor: _trainingBlue,
                  minimumSize: Size.fromHeight(compact ? 42 : 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(compact ? 12 : 14),
                  ),
                ),
                child: Text(isSubmitting ? 'Submitting...' : action),
              );
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: action == actions.last ? 0 : 10),
            child: button,
          ),
        );
      }).toList(),
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
  openTrainingDetailsScreen(context, program);
}

Future<void> _openResource(
  BuildContext context,
  TrainingResource resource,
) async {
  final resourceUrl = resolveApiFileUrl(resource.filePath);
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

  var didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!didLaunch) {
    didLaunch = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
  if (!didLaunch && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this resource.')),
    );
  }
}

List<TrainingProgram> _programsFromHomeAnnouncements(
  List<HomeAnnouncement> announcements,
) {
  return announcements
      .where((item) => _normalizedTrainingKey(item.type) == 'training')
      .map(
        (item) => TrainingProgram(
          id: 'announcement-${item.id ?? item.trainingAnnouncementId ?? item.title}',
          title: item.title,
          trainingType: 'Training Announcement',
          organizer: item.caption,
          location: '',
          description: item.subtitle,
          targetCadres: const ['Staff Members'],
          badge: 'Announcement',
          status: TrainingParticipationStatus.notApplied,
          availableSlots: 0,
          participantCount: 0,
          resources: const [],
          startDate: item.startsAt,
          endDate: item.endsAt,
          isLive: item.isLive,
          canApplyLive: false,
        ),
      )
      .toList();
}

List<TrainingResource> _resourcesFromHomeResources(
  List<HomeResource> resources,
) {
  final converted = <TrainingResource>[];
  for (final resource in resources) {
    if (resource.attachments.isEmpty) {
      converted.add(
        TrainingResource(
          id: 'resource-${resource.uuid}',
          title: resource.title,
          sizeLabel: resource.status,
          fileName: resource.subtitle,
          filePath: '',
          fileType: 'resource',
          isLive: resource.isLive,
        ),
      );
      continue;
    }

    for (final attachment in resource.attachments) {
      converted.add(
        TrainingResource(
          id: 'resource-${resource.uuid}-${attachment.uuid}',
          title: attachment.label.trim().isEmpty
              ? resource.title
              : attachment.label,
          sizeLabel: resource.status,
          fileName: attachment.originalFileName,
          filePath: attachment.attachmentUrl,
          fileType: _fileTypeFromName(attachment.originalFileName),
          isLive: resource.isLive,
        ),
      );
    }
  }
  return converted;
}

List<TrainingProgram> _mergeTrainingPrograms(
  List<TrainingProgram> primary,
  List<TrainingProgram> secondary,
) {
  if (primary.isNotEmpty) {
    return [...primary]..sort(_sortTrainingProgramsByDate);
  }

  final byKey = <String, TrainingProgram>{};
  for (final item in [...secondary, ...primary]) {
    byKey[_normalizedTrainingKey(item.title)] = item;
  }
  return byKey.values.toList()..sort(_sortTrainingProgramsByDate);
}

List<TrainingResource> _mergeTrainingResources(
  List<TrainingResource> primary,
  List<TrainingResource> secondary,
) {
  final byKey = <String, TrainingResource>{};
  for (final item in [...secondary, ...primary]) {
    final key = item.filePath.trim().isNotEmpty
        ? item.filePath.trim().toLowerCase()
        : '${item.title}-${item.fileName}'.toLowerCase();
    byKey[key] = item;
  }
  return byKey.values.toList()
    ..sort((first, second) => first.title.compareTo(second.title));
}

int _sortTrainingProgramsByDate(TrainingProgram first, TrainingProgram second) {
  final firstDate = first.startDate ?? DateTime(1970);
  final secondDate = second.startDate ?? DateTime(1970);
  return secondDate.compareTo(firstDate);
}

String _normalizedTrainingKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _fileTypeFromName(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  if (extension == fileName.toLowerCase()) return 'file';
  return extension;
}

List<TrainingProgram> _filterPrograms(
  List<TrainingProgram> programs,
  String query, {
  TrainingParticipationStatus? status,
  DateTimeRange? dateRange,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return programs.where((item) {
    if (status != null && item.status != status) return false;
    if (!_isTrainingInDateRange(item.startDate, item.endDate, dateRange)) {
      return false;
    }
    if (normalizedQuery.isEmpty) return true;
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
  String query, {
  TrainingParticipationStatus? status,
  DateTimeRange? dateRange,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return records.where((item) {
    if (status != null && item.status != status) return false;
    if (!_isTrainingInDateRange(item.startDate, item.endDate, dateRange)) {
      return false;
    }
    if (normalizedQuery.isEmpty) return true;
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

bool _isTrainingInDateRange(
  DateTime? startDate,
  DateTime? endDate,
  DateTimeRange? range,
) {
  if (range == null) return true;
  final start = startDate;
  final end = endDate ?? startDate;
  if (start == null && end == null) return false;

  final rangeStart = DateUtils.dateOnly(range.start);
  final rangeEnd = DateUtils.dateOnly(range.end);
  final itemStart = DateUtils.dateOnly(start ?? end!);
  final itemEnd = DateUtils.dateOnly(end ?? start!);

  return !itemEnd.isBefore(rangeStart) && !itemStart.isAfter(rangeEnd);
}

int _trainingFilterCount({
  required TrainingParticipationStatus? status,
  required DateTimeRange? dateRange,
}) {
  var count = 0;
  if (status != null) count++;
  if (dateRange != null) count++;
  return count;
}

Future<DateTimeRange?> _pickTrainingDateRange(
  BuildContext context,
  DateTimeRange? currentRange,
) {
  final now = DateTime.now();
  return showDateRangePicker(
    context: context,
    initialDateRange: currentRange,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 5),
    helpText: 'Filter by training date',
    saveText: 'Apply',
  );
}

List<String> _trainingApprovalActions(StaffPortalAccess access) {
  if (access.canApproveTrainingRequests) {
    return ['Approve', if (access.canDenyTrainingRequests) 'Deny'];
  }
  if (access.canForwardTrainingRequests) return const ['Forward'];
  return const [];
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
