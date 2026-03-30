class ApiCall {
  static String baseUrl = " https://hris-staff-portal.hezo.co.tz/api";

  static String loginApi = '$baseUrl/login';
  static String defaultDashboard = '$baseUrl/getDefaultHeadCount';
  static String selectedDashboard = '$baseUrl/getSelectedHeadCount';
  static String getWorkStation = '$baseUrl/workStations';
}
