import 'package:flutter/material.dart';

import 'package:staffportal/features/profile/models/profile_record_models.dart';

const _profileBlue = Color(0xFF1F6BFF);
const _profileBorder = Color(0xFFE4E7EC);
const _profileMuted = Color(0xFF667085);

class ProfileRecordModuleCard extends StatelessWidget {
  const ProfileRecordModuleCard({
    super.key,
    required this.module,
    required this.onTap,
  });

  final ProfileRecordModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _profileBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.folder_shared_outlined, color: _profileBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                module.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _profileMuted),
          ],
        ),
      ),
    );
  }
}

class ProfileRecordCard extends StatelessWidget {
  const ProfileRecordCard({
    super.key,
    required this.module,
    required this.record,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfileRecordModule module;
  final ProfileRecord record;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = module.summaryKeys
        .map(record.valueOf)
        .where((value) => value.isNotEmpty)
        .take(2)
        .join(' • ');
    final rows = record.values.entries
        .where(
          (entry) =>
              entry.value != null &&
              entry.value.toString().trim().isNotEmpty &&
              !entry.key.endsWith('_id') &&
              entry.key != 'created_at' &&
              entry.key != 'updated_at' &&
              entry.key != 'deleted_at',
        )
        .take(6)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _profileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.isEmpty ? module.title : title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canUpdate)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              if (canDelete)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Color(0xFFD14343),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${_labelize(row.key)}: ${row.value}',
                style: const TextStyle(fontSize: 12, color: _profileMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileRecordInlineMessage extends StatelessWidget {
  const ProfileRecordInlineMessage({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD7B0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class EmptyProfileRecords extends StatelessWidget {
  const EmptyProfileRecords({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _profileBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: _profileMuted),
      ),
    );
  }
}

String _labelize(String key) {
  return key
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
