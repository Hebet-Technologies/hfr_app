class UserModel {
  String? accessToken;
  Data? data;

  UserModel({this.accessToken, this.data});

  UserModel.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['access_token'] = accessToken;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? firstName;
  String? middleName;
  String? lastName;
  String? address;
  String? gender;
  String? phone;
  dynamic? loginStatus;
  String? email;

  Data(
      {
        this.firstName,
        this.middleName,
        this.lastName,
        this.address,
        this.gender,
        this.phone,
        this.loginStatus,
        this.email,
      }
  );

  Data.fromJson(Map<String, dynamic> json) {
    firstName = json['first_name'];
    middleName = json['middle_name'];
    lastName = json['last_name'];
    address = json['address'];
    gender = json['gender'];
    phone = json['phone'];
    loginStatus = json['login_status'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first_name'] = firstName;
    data['middle_name'] = middleName;
    data['last_name'] = lastName;
    data['address'] = address;
    data['gender'] = gender;
    data['phone'] = phone;
    data['login_status'] = loginStatus;
    data['email'] = email;
    return data;
  }
}