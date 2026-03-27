class RegistrationModel {
  final String firstName;
  final String middleName;
  final String lastName;
  final String locationId;
  final String gender;
  final String phoneNo;
  final String dateOfBirth;
  final String email;
  final String password;
  final String workingStationId;
  final String personalInformationId;
  final String pathId;

  RegistrationModel({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.locationId,
    required this.gender,
    required this.phoneNo,
    required this.dateOfBirth,
    required this.email,
    required this.password,
    required this.workingStationId,
    required this.personalInformationId,
    required this.pathId,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'location_id': locationId,
      'gender': gender,
      'phone_no': phoneNo,
      'date_of_birth': dateOfBirth,
      'email': email,
      'password': password,
      'working_station_id': workingStationId,
      'personal_information_id': personalInformationId,
      'path_id': pathId,
    };
  }
}
