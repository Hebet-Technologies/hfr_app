import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staffportal/features/profile/models/profile_record_models.dart';
import 'package:staffportal/core/providers/app_providers.dart';

final profileRecordListProvider = FutureProvider.autoDispose
    .family<List<ProfileRecord>, ProfileRecordModule>((ref, module) async {
      final user = ref.watch(authViewModelProvider).user;
      final personalInformationId = user?.personalInformationId.trim() ?? '';
      if (personalInformationId.isEmpty) {
        throw Exception('Your employee profile is not linked to this session.');
      }

      return ref
          .watch(profileRecordsRepositoryProvider)
          .fetchRecords(
            module: module,
            personalInformationId: personalInformationId,
          );
    });

final profileLookupProvider = FutureProvider.autoDispose
    .family<List<ProfileLookupOption>, ProfileLookupConfig>((ref, config) {
      return ref.watch(profileRecordsRepositoryProvider).fetchLookup(config);
    });

final profileRecordActionsProvider = Provider<ProfileRecordActions>(
  (ref) => ProfileRecordActions(ref),
);

class ProfileRecordActions {
  const ProfileRecordActions(this._ref);

  final Ref _ref;

  Future<String> saveRecord({
    required ProfileRecordModule module,
    required Map<String, String> values,
    ProfileRecord? existing,
    String? filePath,
    String? fileName,
  }) async {
    final user = _ref.read(authViewModelProvider).user;
    final personalInformationId = user?.personalInformationId.trim() ?? '';
    if (personalInformationId.isEmpty) {
      throw Exception('Your employee profile is not linked to this session.');
    }

    final message = await _ref
        .read(profileRecordsRepositoryProvider)
        .saveRecord(
          module: module,
          personalInformationId: personalInformationId,
          values: values,
          existing: existing,
          filePath: filePath,
          fileName: fileName,
        );
    _ref.invalidate(profileRecordListProvider(module));
    return message;
  }

  Future<String> deleteRecord({
    required ProfileRecordModule module,
    required ProfileRecord record,
  }) async {
    final message = await _ref
        .read(profileRecordsRepositoryProvider)
        .deleteRecord(module: module, record: record);
    _ref.invalidate(profileRecordListProvider(module));
    return message;
  }
}
