import 'package:staffportal/core/network/api_service.dart';

String resolveApiFileUrl(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }

  final uri = Uri.tryParse(normalized);
  if (uri != null && uri.hasScheme) {
    return normalized;
  }

  final apiUri = Uri.parse(ApiService.baseUrl);
  if (normalized.startsWith('//')) {
    return '${apiUri.scheme}:$normalized';
  }

  final publicBase = '${apiUri.scheme}://${apiUri.authority}';
  final relativePath = normalized.replaceFirst(RegExp(r'^/+'), '');

  return '$publicBase/$relativePath';
}
