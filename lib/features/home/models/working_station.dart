class WorkingStation {
  final int workingStationId;
  final String workingStationName;

  WorkingStation({
    required this.workingStationId,
    required this.workingStationName,
  });

  factory WorkingStation.fromJson(Map<String, dynamic> json) {
    return WorkingStation(
      workingStationId: json['working_station_id'],
      workingStationName: json['working_station_name'],
    );
  }
}
