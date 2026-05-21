class UserDeviceSession {
  const UserDeviceSession({
    required this.id,
    required this.title,
    required this.subtitle,
    this.deviceUuid,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? deviceUuid;
}
