class Validators {
  static const List<String> _governmentEmailDomains = [
    '@mohz.go.tz',
    '@mmh.go.tz',
    '@zhhtlsmz.go.tz',
    '@cms.go.tz',
    '@zahri.go.tz',
    '@zamep.go.tz',
    '@cgcla.go.tz',
    '@zfda.go.tz',
  ];

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  static String? validateGovernmentEmail(String? value) {
    final basicValidation = validateEmail(value);
    if (basicValidation != null) {
      return basicValidation;
    }

    final normalized = value!.trim().toLowerCase();
    final isAllowed = _governmentEmailDomains.any(normalized.endsWith);
    if (!isAllowed) {
      return 'Use an approved government email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }

    return null;
  }
}
