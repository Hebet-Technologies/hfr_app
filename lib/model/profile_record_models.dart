class ProfileRecordField {
  const ProfileRecordField({
    required this.key,
    required this.label,
    this.required = false,
    this.isDate = false,
    this.isFile = false,
    this.lookup,
  });

  final String key;
  final String label;
  final bool required;
  final bool isDate;
  final bool isFile;
  final ProfileLookupConfig? lookup;
}

class ProfileLookupConfig {
  const ProfileLookupConfig({
    required this.path,
    required this.idKey,
    required this.labelKey,
  });

  final String path;
  final String idKey;
  final String labelKey;
}

class ProfileLookupOption {
  const ProfileLookupOption({required this.id, required this.label});

  final String id;
  final String label;
}

class ProfileRecordModule {
  const ProfileRecordModule({
    required this.key,
    required this.title,
    required this.route,
    required this.idKey,
    required this.viewPermission,
    required this.createPermission,
    required this.updatePermission,
    required this.deletePermission,
    required this.fields,
    required this.summaryKeys,
  });

  final String key;
  final String title;
  final String route;
  final String idKey;
  final String viewPermission;
  final String createPermission;
  final String updatePermission;
  final String deletePermission;
  final List<ProfileRecordField> fields;
  final List<String> summaryKeys;
}

class ProfileRecord {
  const ProfileRecord({required this.id, required this.values});

  final String id;
  final Map<String, dynamic> values;

  String valueOf(String key) => values[key]?.toString().trim() ?? '';
}
