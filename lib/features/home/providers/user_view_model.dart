import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staffportal/features/home/models/dashboard.dart';
import 'package:staffportal/features/home/models/working_station.dart';
import 'package:staffportal/features/auth/data/auth_repository.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/providers/app_providers.dart';

class UserDashboardState {
  const UserDashboardState({
    this.isDashboardLoading = false,
    this.errorMessage,
    this.dashboard = const [],
    this.stations = const [],
    this.selectedStationId,
    this.selectedStationName,
  });

  final bool isDashboardLoading;
  final String? errorMessage;
  final List<EmployeeStats> dashboard;
  final List<WorkingStation> stations;
  final String? selectedStationId;
  final String? selectedStationName;

  UserDashboardState copyWith({
    bool? isDashboardLoading,
    String? errorMessage,
    List<EmployeeStats>? dashboard,
    List<WorkingStation>? stations,
    String? selectedStationId,
    String? selectedStationName,
    bool clearSelectedStation = false,
  }) {
    return UserDashboardState(
      isDashboardLoading: isDashboardLoading ?? this.isDashboardLoading,
      errorMessage: errorMessage,
      dashboard: dashboard ?? this.dashboard,
      stations: stations ?? this.stations,
      selectedStationId: clearSelectedStation
          ? null
          : selectedStationId ?? this.selectedStationId,
      selectedStationName: clearSelectedStation
          ? null
          : selectedStationName ?? this.selectedStationName,
    );
  }
}

class UserViewModel extends Notifier<UserDashboardState> {
  late AuthRepository _authRepository;

  @override
  UserDashboardState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const UserDashboardState();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(
      isDashboardLoading: true,
      errorMessage: null,
      dashboard: const [],
      clearSelectedStation: true,
    );

    try {
      final response = await _authRepository.defaultDashboard();
      state = state.copyWith(
        isDashboardLoading: false,
        dashboard: [EmployeeStats.fromJson(response)],
      );
      if (state.stations.isEmpty) {
        await loadStations();
      }
    } catch (error) {
      state = state.copyWith(
        isDashboardLoading: false,
        errorMessage: friendlyErrorMessage(error),
      );
    }
  }

  Future<void> loadSelectedDashboard(WorkingStation station) async {
    state = state.copyWith(
      isDashboardLoading: true,
      errorMessage: null,
      dashboard: const [],
      selectedStationId: station.workingStationId.toString(),
      selectedStationName: station.workingStationName,
    );

    try {
      final response = await _authRepository.selectedDashboard(
        station.workingStationId,
      );
      state = state.copyWith(
        isDashboardLoading: false,
        dashboard: [EmployeeStats.fromJson(response)],
      );
    } catch (error) {
      state = state.copyWith(
        isDashboardLoading: false,
        errorMessage: friendlyErrorMessage(error),
      );
    }
  }

  Future<void> loadStations() async {
    if (state.stations.isNotEmpty) return;

    try {
      final response = await _authRepository.getWorkStation();
      final stations = <WorkingStation>[];
      if (response is Map && response['statusCode'] == 200) {
        final data = response['data'];
        if (data is List) {
          for (final item in data) {
            if (item is Map && item['deleted_at'] == null) {
              stations.add(
                WorkingStation.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              );
            }
          }
        }
      }
      state = state.copyWith(stations: stations);
    } catch (_) {
      state = state.copyWith(stations: const []);
    }
  }

  void setSelectedStation(WorkingStation station) {
    state = state.copyWith(
      selectedStationId: station.workingStationId.toString(),
      selectedStationName: station.workingStationName,
    );
  }
}
