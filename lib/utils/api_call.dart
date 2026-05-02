import '../data/network/api_service.dart';

class ApiCall {
  static String baseUrl = ApiService.baseUrl;

  static String loginApi = '$baseUrl/login';
  static String defaultDashboard = '$baseUrl/getDefaultHeadCount';
  static String selectedDashboard = '$baseUrl/getSelectedHeadCount';
  static String getWorkStation = '$baseUrl/workStations';
}
