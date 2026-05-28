enum ActivityRequestScope {
  withinFacility(
    label: 'Within Facility',
    apiValue: 'WITHIN_WORKING_AREA',
    requiresAttachment: false,
    requiresOrganizer: false,
  ),
  withinDistrict(
    label: 'Within District',
    apiValue: 'WITHIN_WORKING_AREA',
    requiresAttachment: false,
    requiresOrganizer: true,
  ),
  zanzibar(
    label: 'Within Zanzibar',
    apiValue: 'ZANZIBAR',
    requiresAttachment: false,
    requiresOrganizer: true,
  ),
  mainland(
    label: 'Mainland Tanzania',
    apiValue: 'MAINLAND',
    requiresAttachment: true,
    requiresOrganizer: true,
  ),
  international(
    label: 'International',
    apiValue: 'INTERNATIONAL',
    requiresAttachment: true,
    requiresOrganizer: true,
  );

  const ActivityRequestScope({
    required this.label,
    required this.apiValue,
    required this.requiresAttachment,
    required this.requiresOrganizer,
  });

  final String label;
  final String apiValue;
  final bool requiresAttachment;
  final bool requiresOrganizer;

  static ActivityRequestScope? fromLabel(String? label) {
    final normalized = label?.trim() ?? '';
    if (normalized.isEmpty) return null;

    for (final scope in ActivityRequestScope.values) {
      if (scope.label == normalized) {
        return scope;
      }
    }

    return null;
  }
}

class ActivityRequestRules {
  const ActivityRequestRules();

  List<String> get scopeLabels {
    return ActivityRequestScope.values.map((scope) => scope.label).toList();
  }

  ActivityRequestScope? scopeFromLabel(String? label) {
    return ActivityRequestScope.fromLabel(label);
  }

  bool requiresAttachment(String? scopeLabel) {
    return scopeFromLabel(scopeLabel)?.requiresAttachment ?? false;
  }

  bool requiresOrganizer(String? scopeLabel) {
    return scopeFromLabel(scopeLabel)?.requiresOrganizer ?? false;
  }
}
