import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staffportal/features/profile/models/profile_record_models.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import '../providers/profile_records_view_model.dart';
import 'package:staffportal/core/providers/app_providers.dart';
import '../widgets/profile_record_widgets.dart';

const _profileBlue = Color(0xFF1F6BFF);
const _profileSurface = Color(0xFFF7F8FA);

class ProfileRecordsScreen extends ConsumerStatefulWidget {
  const ProfileRecordsScreen({super.key});

  @override
  ConsumerState<ProfileRecordsScreen> createState() =>
      _ProfileRecordsScreenState();
}

class _ProfileRecordsScreenState extends ConsumerState<ProfileRecordsScreen> {
  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffPortalAccessProvider);
    final modules = _profileModules
        .where((module) => access.allows(module.viewPermission))
        .toList();

    return Scaffold(
      backgroundColor: _profileSurface,
      appBar: AppBar(
        backgroundColor: _profileSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile Records',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          if (modules.isEmpty)
            const EmptyProfileRecords(
              message: 'No profile record permissions are available.',
            )
          else
            ...modules.map(
              (module) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProfileRecordModuleCard(
                  module: module,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileRecordListScreen(module: module),
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

class ProfileRecordListScreen extends ConsumerStatefulWidget {
  const ProfileRecordListScreen({super.key, required this.module});

  final ProfileRecordModule module;

  @override
  ConsumerState<ProfileRecordListScreen> createState() =>
      _ProfileRecordListScreenState();
}

class _ProfileRecordListScreenState
    extends ConsumerState<ProfileRecordListScreen> {
  bool _isSubmitting = false;

  Future<void> _openForm([ProfileRecord? record]) async {
    final result = await showModalBottomSheet<_ProfileRecordFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ProfileRecordFormSheet(module: widget.module, record: record),
    );
    if (result == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final message = await ref
          .read(profileRecordActionsProvider)
          .saveRecord(
            module: widget.module,
            values: result.values,
            existing: record,
            filePath: result.filePath,
            fileName: result.fileName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      final message = friendlyErrorMessage(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete(ProfileRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${widget.module.title}'),
        content: const Text('This record will be removed from your profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final message = await ref
          .read(profileRecordActionsProvider)
          .deleteRecord(module: widget.module, record: record);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      final message = friendlyErrorMessage(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffPortalAccessProvider);
    final canCreate = access.allows(widget.module.createPermission);
    final canUpdate = access.allows(widget.module.updatePermission);
    final canDelete = access.allows(widget.module.deletePermission);
    final recordsAsync = ref.watch(profileRecordListProvider(widget.module));

    return Scaffold(
      backgroundColor: _profileSurface,
      appBar: AppBar(
        backgroundColor: _profileSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.module.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              backgroundColor: _profileBlue,
              onPressed: _isSubmitting ? null : () => _openForm(),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        color: _profileBlue,
        onRefresh: () async {
          ref.invalidate(profileRecordListProvider(widget.module));
          await ref.read(profileRecordListProvider(widget.module).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
          children: [
            if (_isSubmitting) ...[
              const LinearProgressIndicator(color: _profileBlue),
              const SizedBox(height: 12),
            ],
            ...recordsAsync.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: Center(
                    child: CircularProgressIndicator(color: _profileBlue),
                  ),
                ),
              ],
              error: (error, _) => [
                ProfileRecordInlineMessage(
                  message: listLoadErrorMessage(error),
                  onRetry: () =>
                      ref.invalidate(profileRecordListProvider(widget.module)),
                ),
              ],
              data: (records) => records.isEmpty
                  ? const [EmptyProfileRecords(message: 'No records found.')]
                  : records
                        .map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ProfileRecordCard(
                              module: widget.module,
                              record: record,
                              canUpdate: canUpdate,
                              canDelete: canDelete,
                              onEdit: () => _openForm(record),
                              onDelete: () => _delete(record),
                            ),
                          ),
                        )
                        .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRecordFormSheet extends StatefulWidget {
  const _ProfileRecordFormSheet({required this.module, this.record});

  final ProfileRecordModule module;
  final ProfileRecord? record;

  @override
  State<_ProfileRecordFormSheet> createState() =>
      _ProfileRecordFormSheetState();
}

class _ProfileRecordFormSheetState extends State<_ProfileRecordFormSheet> {
  late final Map<String, TextEditingController> _controllers;
  final Map<String, List<ProfileLookupOption>> _lookups = {};
  String? _filePath;
  String? _fileName;
  bool _isLoadingLookups = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.module.fields.where((item) => !item.isFile))
        field.key: TextEditingController(
          text: widget.record?.valueOf(field.key) ?? '',
        ),
    };
    Future<void>.microtask(_loadLookups);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null) return;
    setState(() {
      _filePath = file.path;
      _fileName = file.name;
    });
  }

  Future<void> _loadLookups() async {
    final fields = widget.module.fields
        .where((field) => field.lookup != null)
        .toList();
    if (fields.isEmpty) return;

    setState(() => _isLoadingLookups = true);
    final container = ProviderScope.containerOf(context);

    for (final field in fields) {
      try {
        _lookups[field.key] = await container.read(
          profileLookupProvider(field.lookup!).future,
        );
      } catch (_) {
        _lookups[field.key] = const [];
      }
    }
    if (mounted) setState(() => _isLoadingLookups = false);
  }

  void _submit() {
    final values = <String, String>{};
    for (final field in widget.module.fields.where((item) => !item.isFile)) {
      final value = _controllers[field.key]?.text.trim() ?? '';
      if (field.required && value.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${field.label} is required.')));
        return;
      }
      if (value.isNotEmpty) values[field.key] = value;
    }

    final fileField = widget.module.fields.where((item) => item.isFile);
    if (fileField.isNotEmpty &&
        fileField.first.required &&
        widget.record == null &&
        (_filePath == null || _filePath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${fileField.first.label} is required.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _ProfileRecordFormResult(
        values: values,
        filePath: _filePath,
        fileName: _fileName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          children: [
            Text(
              widget.record == null
                  ? 'Add ${widget.module.title}'
                  : 'Edit ${widget.module.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (_isLoadingLookups) ...[
              const LinearProgressIndicator(color: _profileBlue),
              const SizedBox(height: 12),
            ],
            for (final field in widget.module.fields) ...[
              if (field.isFile)
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                  label: Text(_fileName ?? field.label),
                )
              else if (field.lookup != null &&
                  (_lookups[field.key] ?? const []).isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _dropdownValue(field),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: field.required
                        ? '${field.label} *'
                        : field.label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _lookups[field.key]!
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(
                            option.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _controllers[field.key]?.text = value;
                  },
                )
              else
                TextField(
                  controller: _controllers[field.key],
                  keyboardType: field.isDate
                      ? TextInputType.datetime
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: field.required
                        ? '${field.label} *'
                        : field.label,
                    hintText: field.isDate ? 'YYYY-MM-DD' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _profileBlue,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _submit,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String? _dropdownValue(ProfileRecordField field) {
    final value = _controllers[field.key]?.text.trim() ?? '';
    if (value.isEmpty) return null;
    final options = _lookups[field.key] ?? const [];
    return options.any((option) => option.id == value) ? value : null;
  }
}

class _ProfileRecordFormResult {
  const _ProfileRecordFormResult({
    required this.values,
    this.filePath,
    this.fileName,
  });

  final Map<String, String> values;
  final String? filePath;
  final String? fileName;
}

const _profileModules = <ProfileRecordModule>[
  ProfileRecordModule(
    key: 'educations',
    title: 'Education',
    route: 'personalEducations',
    idKey: 'education_details_id',
    viewPermission: 'View Personal Education',
    createPermission: 'Create Personal Education',
    updatePermission: 'Update Personal Education',
    deletePermission: 'Delete Personal Education',
    summaryKeys: ['education_level_name', 'institute_name', 'program_name'],
    fields: [
      ProfileRecordField(
        key: 'education_level_id',
        label: 'Education Level ID',
        required: true,
        lookup: ProfileLookupConfig(
          path: '/getEducationLevels',
          idKey: 'education_level_id',
          labelKey: 'education_level_name',
        ),
      ),
      ProfileRecordField(
        key: 'institute_id',
        label: 'Institute ID',
        required: true,
        lookup: ProfileLookupConfig(
          path: '/institutes',
          idKey: 'institute_id',
          labelKey: 'institute_name',
        ),
      ),
      ProfileRecordField(
        key: 'country_id',
        label: 'Country ID',
        required: true,
        lookup: ProfileLookupConfig(
          path: '/getCountries',
          idKey: 'country_id',
          labelKey: 'country_name',
        ),
      ),
      ProfileRecordField(
        key: 'program_id',
        label: 'Program ID',
        required: true,
        lookup: ProfileLookupConfig(
          path: '/programs',
          idKey: 'program_id',
          labelKey: 'program_name',
        ),
      ),
      ProfileRecordField(key: 'from_year', label: 'From Year'),
      ProfileRecordField(key: 'to_year', label: 'To Year'),
      ProfileRecordField(key: 'gpa', label: 'GPA'),
    ],
  ),
  ProfileRecordModule(
    key: 'experiences',
    title: 'Work Experience',
    route: 'personalExperiences',
    idKey: 'experience_id',
    viewPermission: 'View Personal Experience',
    createPermission: 'Create Personal Experience',
    updatePermission: 'Update Personal Experience',
    deletePermission: 'Delete Personal Experience',
    summaryKeys: ['employer_name', 'experience_position'],
    fields: [
      ProfileRecordField(
        key: 'employer_name',
        label: 'Employer Name',
        required: true,
      ),
      ProfileRecordField(
        key: 'experience_position',
        label: 'Position',
        required: true,
      ),
      ProfileRecordField(key: 'start_date', label: 'Start Date', isDate: true),
      ProfileRecordField(key: 'end_date', label: 'End Date', isDate: true),
      ProfileRecordField(
        key: 'upload_file_name',
        label: 'Attachment',
        isFile: true,
      ),
    ],
  ),
  ProfileRecordModule(
    key: 'hobbies',
    title: 'Hobbies',
    route: 'personalHobbies',
    idKey: 'personal_hobby_id',
    viewPermission: 'View Personal Hobbies',
    createPermission: 'Create Personal Hobbies',
    updatePermission: 'Update Personal Hobbies',
    deletePermission: 'Delete Personal Hobbies',
    summaryKeys: ['hobby_name', 'hobby_id'],
    fields: [
      ProfileRecordField(
        key: 'hobby_id',
        label: 'Hobby ID',
        required: true,
        lookup: ProfileLookupConfig(
          path: '/hobbies',
          idKey: 'hobby_id',
          labelKey: 'hobby_name',
        ),
      ),
    ],
  ),
  ProfileRecordModule(
    key: 'skills',
    title: 'Skills',
    route: 'personalSkills',
    idKey: 'personal_skill_id',
    viewPermission: 'View Personal Skills',
    createPermission: 'Create Personal Skills',
    updatePermission: 'Update Personal Skills',
    deletePermission: 'Delete Personal Skills',
    summaryKeys: ['skill_name', 'skill_id'],
    fields: [
      ProfileRecordField(
        key: 'skill_id',
        label: 'Skill ID',
        required: true,
        lookup: ProfileLookupConfig(
          path: '/skills',
          idKey: 'skill_id',
          labelKey: 'skill_name',
        ),
      ),
      ProfileRecordField(
        key: 'upload_file_name',
        label: 'Certificate',
        isFile: true,
        required: true,
      ),
    ],
  ),
  ProfileRecordModule(
    key: 'languages',
    title: 'Languages',
    route: 'personalLanguages',
    idKey: 'personal_language_id',
    viewPermission: 'View Personal Language',
    createPermission: 'Create Personal Language',
    updatePermission: 'Update Personal Language',
    deletePermission: 'Delete Personal Language',
    summaryKeys: ['language_name', 'language_id'],
    fields: [
      ProfileRecordField(
        key: 'language_id',
        label: 'Language ID',
        required: true,
        lookup: ProfileLookupConfig(
          path: '/languages',
          idKey: 'language_id',
          labelKey: 'language_name',
        ),
      ),
      ProfileRecordField(key: 'speaking', label: 'Speaking'),
      ProfileRecordField(key: 'reading', label: 'Reading'),
      ProfileRecordField(key: 'writting', label: 'Writing'),
    ],
  ),
  ProfileRecordModule(
    key: 'nextOfKin',
    title: 'Next of Kin',
    route: 'personalNextKins',
    idKey: 'next_of_kin_id',
    viewPermission: 'View Personal Next Of Kin',
    createPermission: 'Create Personal Next Of Kin',
    updatePermission: 'Update Personal Next Of Kin',
    deletePermission: 'Delete Personal Next Of Kin',
    summaryKeys: ['first_name', 'last_name', 'relation_name'],
    fields: [
      ProfileRecordField(
        key: 'first_name',
        label: 'First Name',
        required: true,
      ),
      ProfileRecordField(key: 'middle_name', label: 'Middle Name'),
      ProfileRecordField(key: 'last_name', label: 'Last Name', required: true),
      ProfileRecordField(
        key: 'phone_no',
        label: 'Phone Number',
        required: true,
      ),
      ProfileRecordField(key: 'email', label: 'Email'),
      ProfileRecordField(key: 'gender', label: 'Gender'),
      ProfileRecordField(
        key: 'relation_id',
        label: 'Relation ID',
        required: true,
        lookup: ProfileLookupConfig(
          path: '/relations',
          idKey: 'relation_id',
          labelKey: 'relation_name',
        ),
      ),
    ],
  ),
  ProfileRecordModule(
    key: 'refferees',
    title: 'Referees',
    route: 'personalRefferees',
    idKey: 'refferee_id',
    viewPermission: 'View Personal Refferee',
    createPermission: 'Create Personal Refferee',
    updatePermission: 'Update Personal Refferee',
    deletePermission: 'Delete Personal Refferee',
    summaryKeys: ['first_name', 'last_name', 'refferee_position'],
    fields: [
      ProfileRecordField(
        key: 'first_name',
        label: 'First Name',
        required: true,
      ),
      ProfileRecordField(key: 'middle_name', label: 'Middle Name'),
      ProfileRecordField(key: 'last_name', label: 'Last Name', required: true),
      ProfileRecordField(
        key: 'refferee_phone',
        label: 'Phone Number',
        required: true,
      ),
      ProfileRecordField(key: 'refferee_position', label: 'Position'),
      ProfileRecordField(key: 'working_area', label: 'Working Area'),
      ProfileRecordField(key: 'email', label: 'Email'),
      ProfileRecordField(
        key: 'date_of_birth',
        label: 'Date of Birth',
        isDate: true,
      ),
      ProfileRecordField(key: 'location_id', label: 'Location ID'),
      ProfileRecordField(
        key: 'identification_id',
        label: 'Identification Type ID',
        lookup: ProfileLookupConfig(
          path: '/identifications',
          idKey: 'identification_id',
          labelKey: 'identification_name',
        ),
      ),
      ProfileRecordField(key: 'id_number', label: 'ID Number'),
      ProfileRecordField(
        key: 'upload_file_name',
        label: 'Attachment',
        isFile: true,
      ),
    ],
  ),
  ProfileRecordModule(
    key: 'attachments',
    title: 'Personal Attachments',
    route: 'personalAttachments',
    idKey: 'employee_attachment_id',
    viewPermission: 'View Personal Attachement',
    createPermission: 'Create Personal Attachement',
    updatePermission: 'Update Personal Attachement',
    deletePermission: 'Delete Personal Attachement',
    summaryKeys: ['upload_name', 'upload_file_name'],
    fields: [
      ProfileRecordField(
        key: 'upload_type_id',
        label: 'Upload Type ID',
        required: true,
        lookup: ProfileLookupConfig(
          path: '/uploadTypes',
          idKey: 'upload_type_id',
          labelKey: 'upload_name',
        ),
      ),
      ProfileRecordField(
        key: 'upload_file_name',
        label: 'Attachment',
        isFile: true,
        required: true,
      ),
    ],
  ),
];
