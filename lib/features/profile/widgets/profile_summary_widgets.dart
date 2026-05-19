import 'package:flutter/material.dart';

import 'package:staffportal/features/profile/models/profile_details.dart';

class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.profile,
    required this.roleLabel,
  });

  final ProfileDetails profile;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFFFE9B8),
            child: Text(
              _initials(profile.fullName),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF592E00),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            profile.fullName.isEmpty ? 'Profile' : profile.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            roleLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
          if (profile.facility.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.facility.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroMetaCard(
                  label: 'Employee ID',
                  value: profile.employeeId.trim().isEmpty
                      ? 'Not set'
                      : profile.employeeId.trim(),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _HeroMetaCard(
                  label: 'Status',
                  value: 'Active',
                  accent: Color(0xFF12B76A),
                  background: Color(0xFFE8FFF1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF98A2B3),
        letterSpacing: 0.4,
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.items});

  final List<ProfileInfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      items[index].label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[index].value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (index != items.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF2F4F7)),
          ],
        ],
      ),
    );
  }
}

class ProfileInlineMessage extends StatelessWidget {
  const ProfileInlineMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB54708),
        ),
      ),
    );
  }
}

class ProfileInfoItem {
  const ProfileInfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class ProfileRecordsEntryCard extends StatelessWidget {
  const ProfileRecordsEntryCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: const Row(
          children: [
            Icon(Icons.folder_shared_outlined, color: Color(0xFF1F6BFF)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Education, work, family, skills and attachments',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }
}

class _HeroMetaCard extends StatelessWidget {
  const _HeroMetaCard({
    required this.label,
    required this.value,
    this.accent = const Color(0xFF1F6BFF),
    this.background = const Color(0xFFEAF2FF),
  });

  final String label;
  final String value;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .split(' ')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'P';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
