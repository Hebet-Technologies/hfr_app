

class ApiCall{

  static String baseUrl = "http://102.214.45.136:8081/api";

  static String loginApi = '$baseUrl/login';
  static String defaultDashboard = '$baseUrl/getDefaultHeadCount';
  static String selectedDashboard = '$baseUrl/getSelectedHeadCount';
  static String getWorkStation = '$baseUrl/workStations';
}