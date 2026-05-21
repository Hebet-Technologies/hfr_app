import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staffportal/features/profile/models/profile_details.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/routing/routes_name.dart';
import 'package:staffportal/core/providers/app_providers.dart';
import 'package:staffportal/core/widgets/responsive_layout.dart';
import '../providers/profile_view_model.dart';
import 'edit_profile_screen.dart';
import 'profile_records_screen.dart';
import '../widgets/profile_summary_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _refreshProfile() async {
    ref.invalidate(profileDetailsProvider);
    try {
      await ref.read(profileDetailsProvider.future);
    } catch (_) {
      // The provider error is rendered by the screen.
    }
  }

  Future<void> _openEditProfile(ProfileDetails profile) async {
    final updated = await Navigator.of(context).push<ProfileDetails>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initialDetails: profile),
      ),
    );

    if (updated == null || !mounted) return;
    ref.invalidate(profileDetailsProvider);
  }

  Future<void> _logout() async {
    await ref.read(authViewModelProvider.notifier).logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RoutesName.login);
  }

  Future<void> _openDeviceSessions() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DeviceSessionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final profileAsync = ref.watch(profileDetailsProvider);
    final fallbackProfile = user != null ? ProfileDetails.fromUser(user) : null;
    final profile = profileAsync.value ?? fallbackProfile;
    final isLoading = profileAsync.isLoading;
    final error = profileAsync.hasError
        ? listLoadErrorMessage(profileAsync.error!)
        : null;
    final roleLabel = profile?.cadre.trim().isNotEmpty == true
        ? profile!.cadre.trim()
        : user != null && user.roles.isNotEmpty
        ? _formatRole(user.roles.first)
        : 'Staff member';
    final access = ref.watch(staffPortalAccessProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: const Color(0xFF1F6BFF),
          child: ResponsiveListView(
            padding: AppBreakpoints.pagePadding(context),
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
                    onPressed: isLoading || profile == null
                        ? null
                        : () => _openEditProfile(profile),
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
              if (isLoading && profile != null) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF1F6BFF),
                  backgroundColor: Color(0xFFEAF2FF),
                ),
              ],
              const SizedBox(height: 12),
              if (error != null) ...[
                ProfileInlineMessage(message: error),
                const SizedBox(height: 12),
              ],
              if (isLoading && profile == null)
                const Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1F6BFF)),
                  ),
                )
              else if (profile != null) ...[
                ProfileHeroCard(profile: profile, roleLabel: roleLabel),
                if (access.hasEmployeeProfile) ...[
                  const SizedBox(height: 14),
                  ProfileRecordsEntryCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileRecordsScreen(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ProfileSectionLabel(title: 'PERSONAL DETAILS'),
                const SizedBox(height: 8),
                ProfileInfoCard(
                  items: [
                    ProfileInfoItem(
                      label: 'First Name',
                      value: _display(profile.firstName),
                    ),
                    ProfileInfoItem(
                      label: 'Middle Name',
                      value: _display(profile.middleName),
                    ),
                    ProfileInfoItem(
                      label: 'Last Name',
                      value: _display(profile.lastName),
                    ),
                    ProfileInfoItem(
                      label: 'Gender',
                      value: _display(profile.gender),
                    ),
                    ProfileInfoItem(
                      label: 'Date of Birth',
                      value: _display(_formatDate(profile.dateOfBirth)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ProfileSectionLabel(title: 'CONTACT'),
                const SizedBox(height: 8),
                ProfileInfoCard(
                  items: [
                    ProfileInfoItem(
                      label: 'Phone Number',
                      value: _display(profile.phoneNo),
                    ),
                    ProfileInfoItem(
                      label: 'Email Address',
                      value: _display(profile.email),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ProfileSectionLabel(title: 'WORK DETAILS'),
                const SizedBox(height: 8),
                ProfileInfoCard(
                  items: [
                    ProfileInfoItem(
                      label: 'Employee ID',
                      value: _display(profile.employeeId),
                    ),
                    ProfileInfoItem(
                      label: 'Cadre',
                      value: _display(profile.cadre),
                    ),
                    ProfileInfoItem(
                      label: 'Department',
                      value: _display(profile.department),
                    ),
                    ProfileInfoItem(
                      label: 'Facility',
                      value: _display(profile.facility),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _openDeviceSessions,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF344054),
                    side: const BorderSide(color: Color(0xFFE4E7EC)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.devices_rounded, size: 18),
                  label: const Text(
                    'Manage Devices',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
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

class DeviceSessionsScreen extends ConsumerWidget {
  const DeviceSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(userDeviceSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Devices',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101828),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userDeviceSessionsProvider);
          await ref.read(userDeviceSessionsProvider.future);
        },
        child: sessionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1F6BFF)),
          ),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ProfileInlineMessage(message: friendlyErrorMessage(error)),
            ],
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  ProfileInlineMessage(message: 'No active devices found.'),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.smartphone_rounded,
                        color: Color(0xFF1F6BFF),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF101828),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              session.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(deviceSessionActionsProvider)
                                .revoke(session);
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(friendlyErrorMessage(error)),
                              ),
                            );
                          }
                        },
                        child: const Text('Revoke'),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemCount: sessions.length,
            );
          },
        ),
      ),
    );
  }
}
