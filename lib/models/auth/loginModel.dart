// To parse this JSON data, do
//
//     final login = loginFromJson(jsonString);

import 'dart:convert';

Login loginFromJson(String str) => Login.fromJson(json.decode(str));

String loginToJson(Login data) => json.encode(data.toJson());

class Login {
  Login({
    this.statusCode,
    this.data,
    this.message,
    this.success,
  });

  int? statusCode;
  LoginData? data;
  String? message;
  bool? success;

  factory Login.fromJson(Map<String, dynamic> json) => Login(
        statusCode: json["statusCode"],
        data: json["data"] != null ? LoginData.fromJson(json["data"]) : null,
        message: json["message"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "data": data?.toJson(),
        "message": message,
        "success": success,
      };
}

class LoginData {
  LoginData({
    this.accessToken,
    this.refreshToken,
    this.loggedInUser,
  });

  String? accessToken;
  String? refreshToken;
  User? loggedInUser;

  factory LoginData.fromJson(Map<String, dynamic> json) => LoginData(
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
        loggedInUser: json["loggedInUser"] != null
            ? User.fromJson(json["loggedInUser"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "loggedInUser": loggedInUser?.toJson(),
      };
}

class User {
  User({
    this.preferences,
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.role,
    this.isVerified,
    this.specialization,
    this.notifications,
    this.createdAt,
    this.updatedAt,
    this.v,
    // Legacy fields for backward compatibility
    this.uid,
    this.username,
    this.name,
    this.hospital,
    this.contact,
    this.gender,
    this.address,
    this.age,
    this.maritalStatus,
    this.income,
    this.religion,
    this.education,
    this.occupation,
    this.habitat,
    this.durationOfIllness,
    this.ageOfOnset,
    this.handedness,
    this.bloodGroup,
    this.bloodPressure,
    this.relatedTo,
    this.patientPastHistoryPsychiatricIllness,
    this.patientPastHistoryMedicalIllness,
    this.familyHistoryPsychiatricIllness,
    this.familyHistoryMedicalIllness,
    this.registrationId,
  });

  Preferences? preferences;
  String? id;
  String? email;
  String? firstName;
  String? lastName;
  String? avatar;
  String? role;
  bool? isVerified;
  String? specialization;
  List<Notification>? notifications;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  // Legacy fields for backward compatibility
  String? uid;
  String? username;
  String? name;
  dynamic hospital;
  dynamic contact;
  dynamic gender;
  dynamic address;
  int? age;
  dynamic maritalStatus;
  dynamic income;
  dynamic religion;
  dynamic education;
  dynamic occupation;
  dynamic habitat;
  dynamic durationOfIllness;
  dynamic ageOfOnset;
  dynamic handedness;
  dynamic bloodGroup;
  dynamic bloodPressure;
  List<dynamic>? relatedTo;
  dynamic patientPastHistoryPsychiatricIllness;
  dynamic patientPastHistoryMedicalIllness;
  dynamic familyHistoryPsychiatricIllness;
  dynamic familyHistoryMedicalIllness;
  dynamic registrationId;

  factory User.fromJson(Map<String, dynamic> json) => User(
        preferences: json["preferences"] != null
            ? Preferences.fromJson(json["preferences"])
            : null,
        id: json["_id"],
        email: json["email"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        avatar: json["avatar"],
        role: json["role"],
        isVerified: json["isVerified"],
        specialization: json["specialization"],
        notifications: json["notifications"] != null
            ? List<Notification>.from(json["notifications"].map((x) {
                if (x is String) {
                  return Notification(); // Return empty notification for string values
                }
                return Notification.fromJson(x);
              }))
            : null,
        createdAt: json["createdAt"] != null
            ? DateTime.parse(json["createdAt"])
            : null,
        updatedAt: json["updatedAt"] != null
            ? DateTime.parse(json["updatedAt"])
            : null,
        v: json["__v"],

        // Legacy fields mapping for backward compatibility
        uid: json["_id"] ?? json["uid"],
        username: json["email"] ?? json["username"], // Use email as username
        name: json["firstName"] != null && json["lastName"] != null
            ? "${json["firstName"]} ${json["lastName"]}"
            : json["name"],
        hospital: json["hospital"],
        contact: json["contact"],
        gender: json["gender"],
        address: json["address"],
        age: json["age"],
        maritalStatus: json["marital_status"] ?? json["maritalStatus"],
        income: json["income"],
        religion: json["religion"],
        education: json["education"],
        occupation: json["occupation"],
        habitat: json["habitat"],
        durationOfIllness:
            json["duration_of_illness"] ?? json["durationOfIllness"],
        ageOfOnset: json["age_of_onset"] ?? json["ageOfOnset"],
        handedness: json["handedness"],
        bloodGroup: json["blood_group"] ?? json["bloodGroup"],
        bloodPressure: json["blood_pressure"] ?? json["bloodPressure"],
        relatedTo: json["related_to"] != null
            ? List<dynamic>.from(json["related_to"].map((x) => x))
            : json["relatedTo"] != null
                ? List<dynamic>.from(json["relatedTo"].map((x) => x))
                : null,
        patientPastHistoryPsychiatricIllness:
            json["patient_past_history_psychiatric_illness"] ??
                json["patientPastHistoryPsychiatricIllness"],
        patientPastHistoryMedicalIllness:
            json["patient_past_history_medical_illness"] ??
                json["patientPastHistoryMedicalIllness"],
        familyHistoryPsychiatricIllness:
            json["family_history_psychiatric_illness"] ??
                json["familyHistoryPsychiatricIllness"],
        familyHistoryMedicalIllness: json["family_history_medical_illness"] ??
            json["familyHistoryMedicalIllness"],
        registrationId: json["registration_id"] ?? json["registrationId"],
      );

  Map<String, dynamic> toJson() => {
        "preferences": preferences?.toJson(),
        "_id": id,
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
        "avatar": avatar,
        "role": role,
        "isVerified": isVerified,
        "specialization": specialization,
        "notifications": notifications != null
            ? List<dynamic>.from(notifications!.map((x) => x.toJson()))
            : null,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,

        // Legacy fields
        "uid": uid,
        "username": username,
        "name": name,
        "hospital": hospital,
        "contact": contact,
        "gender": gender,
        "address": address,
        "age": age,
        "marital_status": maritalStatus,
        "income": income,
        "religion": religion,
        "education": education,
        "occupation": occupation,
        "habitat": habitat,
        "duration_of_illness": durationOfIllness,
        "age_of_onset": ageOfOnset,
        "handedness": handedness,
        "blood_group": bloodGroup,
        "blood_pressure": bloodPressure,
        "related_to": relatedTo != null
            ? List<dynamic>.from(relatedTo!.map((x) => x))
            : null,
        "patient_past_history_psychiatric_illness":
            patientPastHistoryPsychiatricIllness,
        "patient_past_history_medical_illness":
            patientPastHistoryMedicalIllness,
        "family_history_psychiatric_illness": familyHistoryPsychiatricIllness,
        "family_history_medical_illness": familyHistoryMedicalIllness,
        "registration_id": registrationId,
      };
}

class Preferences {
  Preferences({
    this.email,
    this.inApp,
    this.isOnline,
  });

  bool? email;
  bool? inApp;
  bool? isOnline;

  factory Preferences.fromJson(Map<String, dynamic> json) => Preferences(
        email: json["email"],
        inApp: json["inApp"],
        isOnline: json["isOnline"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "inApp": inApp,
        "isOnline": isOnline,
      };
}

class Notification {
  Notification({
    this.message,
    this.date,
    this.read,
    this.id,
  });

  String? message;
  DateTime? date;
  bool? read;
  String? id;

  factory Notification.fromJson(Map<String, dynamic> json) {
    // Handle empty string case
    if (json is String && json.isEmpty) {
      return Notification();
    }

    return Notification(
      message: json["message"],
      date: json["date"] != null ? DateTime.parse(json["date"]) : null,
      read: json["read"],
      id: json["_id"],
    );
  }

  Map<String, dynamic> toJson() => {
        "message": message,
        "date": date?.toIso8601String(),
        "read": read,
        "_id": id,
      };
}
