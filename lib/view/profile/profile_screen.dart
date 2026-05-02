import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/profile_details.dart';
import '../../utils/routes/routes_name.dart';
import '../../view_model/providers.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ProfileDetails? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadProfile);
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _profile ??= ProfileDetails.fromUser(user);
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await ref
          .read(authRepositoryProvider)
          .fetchProfileDetails(user);
      if (!mounted) return;
      setState(() {
        _profile = details;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profile = ProfileDetails.fromUser(user);
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditProfile() async {
    final user = ref.read(authViewModelProvider).user;
    final profile = _profile;
    if (user == null || profile == null) return;

    final updated = await Navigator.of(context).push<ProfileDetails>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initialDetails: profile),
      ),
    );

    if (updated == null || !mounted) return;

    await ref
        .read(authViewModelProvider.notifier)
        .updateUser(updated.applyToUser(user));

    setState(() {
      _profile = updated;
      _error = null;
    });
  }

  Future<void> _logout() async {
    await ref.read(authViewModelProvider.notifier).logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RoutesName.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final profile =
        _profile ?? (user != null ? ProfileDetails.fromUser(user) : null);
    final roleLabel = profile?.cadre.trim().isNotEmpty == true
        ? profile!.cadre.trim()
        : user != null && user.roles.isNotEmpty
        ? _formatRole(user.roles.first)
        : 'Staff member';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: const Color(0xFF1F6BFF),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading || profile == null
                        ? null
                        : _openEditProfile,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF344054),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE4E7EC)),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading && profile != null) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF1F6BFF),
                  backgroundColor: Color(0xFFEAF2FF),
                ),
              ],
              const SizedBox(height: 12),
              if (_error != null) ...[
                _InlineMessage(message: _error!),
                const SizedBox(height: 12),
              ],
              if (_isLoading && profile == null)
                const Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1F6BFF)),
                  ),
                )
              else if (profile != null) ...[
                _ProfileHeroCard(profile: profile, roleLabel: roleLabel),
                const SizedBox(height: 14),
                _SectionLabel(title: 'PERSONAL DETAILS'),
                const SizedBox(height: 8),
                _ProfileInfoCard(
                  items: [
                    _ProfileItem(
                      label: 'First Name',
                      value: _display(profile.firstName),
                    ),
                    _ProfileItem(
                      label: 'Middle Name',
                      value: _display(profile.middleName),
                    ),
                    _ProfileItem(
                      label: 'Last Name',
                      value: _display(profile.lastName),
                    ),
                    _ProfileItem(
                      label: 'Gender',
                      value: _display(profile.gender),
                    ),
                    _ProfileItem(
                      label: 'Date of Birth',
                      value: _display(_formatDate(profile.dateOfBirth)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionLabel(title: 'CONTACT'),
                const SizedBox(height: 8),
                _ProfileInfoCard(
                  items: [
                    _ProfileItem(
                      label: 'Phone Number',
                      value: _display(profile.phoneNo),
                    ),
                    _ProfileItem(
                      label: 'Email Address',
                      value: _display(profile.email),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionLabel(title: 'WORK DETAILS'),
                const SizedBox(height: 8),
                _ProfileInfoCard(
                  items: [
                    _ProfileItem(
                      label: 'Employee ID',
                      value: _display(profile.employeeId),
                    ),
                    _ProfileItem(
                      label: 'Cadre',
                      value: _display(profile.cadre),
                    ),
                    _ProfileItem(
                      label: 'Department',
                      value: _display(profile.department),
                    ),
                    _ProfileItem(
                      label: 'Facility',
                      value: _display(profile.facility),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF04438),
                    side: const BorderSide(color: Color(0xFFFDA29B)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: Center(
                    child: Text(
                      'No profile available.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _display(String value) {
    return value.trim().isEmpty ? 'Not available' : value.trim();
  }

  String _formatRole(String raw) {
    final normalized = raw.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return 'Staff member';
    return normalized
        .split(' ')
        .map((part) {
          if (part.isEmpty) return '';
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  String _formatDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return '';

    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return normalized;

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parsed.day} ${monthNames[parsed.month - 1]} ${parsed.year}';
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.profile, required this.roleLabel});

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
              Expanded(
                child: _HeroMetaCard(
                  label: 'Status',
                  value: 'Active',
                  accent: const Color(0xFF12B76A),
                  background: const Color(0xFFE8FFF1),
                ),
              ),
            ],
          ),
        ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

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

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.items});

  final List<_ProfileItem> items;

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

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

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

class _ProfileItem {
  const _ProfileItem({required this.label, required this.value});

  final String label;
  final String value;
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
