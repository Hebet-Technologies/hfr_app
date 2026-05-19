class RegistrationModel {
  final String firstName;
  final String middleName;
  final String lastName;
  final String surName;
  final String email;
  final String password;
  final String confirmPassword;
  final String pathId;
  final String locationId;
  final String gender;
  final String phoneNo;
  final String dateOfBirth;
  final String transferPathId;
  final String trainingPathId;
  final String workingStationId;
  final String workingStationName;
  final String personalInformationId;

  RegistrationModel({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    this.surName = '',
    required this.email,
    required this.password,
    this.confirmPassword = '',
    required this.pathId,
    this.locationId = '',
    this.gender = '',
    this.phoneNo = '',
    this.dateOfBirth = '',
    this.transferPathId = '',
    this.trainingPathId = '',
    required this.workingStationId,
    this.workingStationName = '',
    required this.personalInformationId,
  });

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'path_id': pathId,
      'working_station_id': workingStationId,
      'personal_information_id': personalInformationId,
    };

    void addIfNotEmpty(String key, String value) {
      if (value.trim().isNotEmpty) {
        payload[key] = value.trim();
      }
    }

    addIfNotEmpty('sur_name', surName);
    addIfNotEmpty('confirm_password', confirmPassword);
    addIfNotEmpty('location_id', locationId);
    addIfNotEmpty('gender', gender);
    addIfNotEmpty('phone_no', phoneNo);
    addIfNotEmpty('date_of_birth', dateOfBirth);
    addIfNotEmpty('transfer_path_id', transferPathId);
    addIfNotEmpty('training_path_id', trainingPathId);
    addIfNotEmpty('working_station_name', workingStationName);

    return payload;
  }
}
