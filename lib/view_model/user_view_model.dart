import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/dashboard.dart';
import '../model/working_station.dart';
import '../repository/auth_repository.dart';
import '../utils/routes/routes_name.dart';

class UserViewModel with ChangeNotifier {
  bool _isLoading = false;
  bool _isDashboardLoading = false;
  bool get isLoading => _isLoading;
  bool get isDashboardLoading => _isDashboardLoading;
  String _userToken = '';
  String get userToken => _userToken;
  String _msg = "";
  String _msgDashboard = "";
  String _msgStation = "";
  String get msg => _msg;
  String get msgDashboard => _msgDashboard;

  final TextEditingController searchLocationController =
      TextEditingController();

  String? _selectedStationId;
  String? _selectedStationName;

  String? get selectedStationId => _selectedStationId;
  String? get selectedStationName => _selectedStationName;

  void setSelectedStation(String? stationId, String stationName) {
    _selectedStationId = stationId;
    _selectedStationName = stationName;
    notifyListeners();
  }

  final List<EmployeeStats> _dashboard = [];
  List<EmployeeStats> get dashboard => _dashboard;

  final List<WorkingStation> _stations = [];
  List<WorkingStation> get stations => _stations;

  final AuthRepository _authRepository;

  UserViewModel(this._authRepository);

  Future<bool> saveUser(String token, String email, String password) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString("token", token);
    sp.setString("email", email);
    sp.setString("password", password);
    notifyListeners();
    return true;
  }

  Future<void> getUserToken() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.getString("token") == null) {
      _userToken = "";
    } else {
      _userToken = sp.getString("token")!;
    }
    notifyListeners();
  }

  Future<dynamic> loginApi(BuildContext context) async {
    _isLoading = true;
    _msg = "";
    notifyListeners();

    final SharedPreferences sp = await SharedPreferences.getInstance();
    Map data = {
      'email': sp.getString("email")!,
      'password': sp.getString("password")!,
    };

    _authRepository
        .loginApi(data)
        .then((value) async {
          _isLoading = false;
          notifyListeners();

          await saveUser(
            value["data"]['token'],
            value["data"]['email'],
            sp.getString("password")!,
          );

          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.home,
            (route) => false,
          );
        })
        .onError((error, stackTrace) {
          _isLoading = false;
          _msg = "error";
          notifyListeners();
        });
  }

  Future<dynamic> getDashboard(BuildContext context) async {
    _selectedStationId = null;
    _isDashboardLoading = true;
    _selectedStationName = null;
    _msgDashboard = "";
    _dashboard.clear();
    notifyListeners();

    _authRepository
        .defaultDashboard()
        .then((value) async {
          _dashboard.add(EmployeeStats.fromJson(value));
          _isDashboardLoading = false;
          notifyListeners();

          if (_msgStation == "error") {
            getStations(context);
          }
        })
        .onError((error, stackTrace) {
          _isDashboardLoading = false;
          _msgDashboard = "error";
          notifyListeners();
        });
  }

  Future<dynamic> getSelectedDashboard(BuildContext context, int id) async {
    _isDashboardLoading = true;
    _msgDashboard = "";
    _dashboard.clear();
    notifyListeners();

    _authRepository
        .selectedDashboard(id)
        .then((value) async {
          _dashboard.add(EmployeeStats.fromJson(value));
          _isDashboardLoading = false;
          notifyListeners();
        })
        .onError((error, stackTrace) {
          _isDashboardLoading = false;
          _msgDashboard = "error";
          notifyListeners();
        });
  }

  Future<dynamic> getStations(BuildContext context) async {
    if (_stations.isNotEmpty) return;

    _msgStation = "";
    notifyListeners();

    _authRepository
        .getWorkStation()
        .then((value) async {
          if (value["statusCode"] == 200) {
            for (var data in value["data"]) {
              if (data['deleted_at'] == null) {
                _stations.add(WorkingStation.fromJson(data));
              }
            }
            notifyListeners();
          }
        })
        .onError((error, stackTrace) {
          _msgStation = "error";
          notifyListeners();
        });
  }

  @override
  void dispose() {
    searchLocationController.dispose();
    super.dispose();
  }
}
