// Patient History Models matching API Documentation
import 'dart:convert';

// Patient History Response Model
class PatientHistoryResponse {
  final bool success;
  final int statusCode;
  final String message;
  final PatientHistoryData? data;

  PatientHistoryResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory PatientHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PatientHistoryResponse(
      success: json['success'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? PatientHistoryData.fromJson(json['data']) : null,
    );
  }
}

// Patient History Data Model (exact structure from API documentation)
class PatientHistoryData {
  final int age;
  final String sex;
  final String maritalStatus;
  final int income;
  final String religion;
  final String education;
  final String occupation;
  final String habitat;
  final String location;
  final String durationOfIllness;
  final int ageOfOnset;
  final int firstMDEAge;
  final bool pastMedicalIllness;
  final bool pastPsychiatricIllness;
  final bool familyMedicalIllness;
  final bool familyPsychiatricIllness;
  final String handedness;
  final int pulse;
  final int bloodPressureSystolic;
  final int bloodPressureDiastolic;
  final String cvs;
  final String rs;
  final String git;
  final String cns;
  final String? patientId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PatientHistoryData({
    required this.age,
    required this.sex,
    required this.maritalStatus,
    required this.income,
    required this.religion,
    required this.education,
    required this.occupation,
    required this.habitat,
    required this.location,
    required this.durationOfIllness,
    required this.ageOfOnset,
    required this.firstMDEAge,
    required this.pastMedicalIllness,
    required this.pastPsychiatricIllness,
    required this.familyMedicalIllness,
    required this.familyPsychiatricIllness,
    required this.handedness,
    required this.pulse,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
    required this.cvs,
    required this.rs,
    required this.git,
    required this.cns,
    this.patientId,
    this.createdAt,
    this.updatedAt,
  });

  factory PatientHistoryData.fromJson(Map<String, dynamic> json) {
    return PatientHistoryData(
      age: json['age'] ?? 0,
      sex: json['sex'] ?? '',
      maritalStatus: json['maritalStatus'] ?? '',
      income: json['income'] ?? 0,
      religion: json['religion'] ?? '',
      education: json['education'] ?? '',
      occupation: json['occupation'] ?? '',
      habitat: json['habitat'] ?? '',
      location: json['location'] ?? '',
      durationOfIllness: json['durationOfIllness'] ?? '',
      ageOfOnset: json['ageOfOnset'] ?? 0,
      firstMDEAge: json['firstMDEAge'] ?? 0,
      pastMedicalIllness: json['pastMedicalIllness'] ?? false,
      pastPsychiatricIllness: json['pastPsychiatricIllness'] ?? false,
      familyMedicalIllness: json['familyMedicalIllness'] ?? false,
      familyPsychiatricIllness: json['familyPsychiatricIllness'] ?? false,
      handedness: json['handedness'] ?? '',
      pulse: json['pulse'] ?? 0,
      bloodPressureSystolic: json['bloodPressureSystolic'] ?? 0,
      bloodPressureDiastolic: json['bloodPressureDiastolic'] ?? 0,
      cvs: json['cvs'] ?? '',
      rs: json['rs'] ?? '',
      git: json['git'] ?? '',
      cns: json['cns'] ?? '',
      patientId: json['patientId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'sex': sex,
      'maritalStatus': maritalStatus,
      'income': income,
      'religion': religion,
      'education': education,
      'occupation': occupation,
      'habitat': habitat,
      'location': location,
      'durationOfIllness': durationOfIllness,
      'ageOfOnset': ageOfOnset,
      'firstMDEAge': firstMDEAge,
      'pastMedicalIllness': pastMedicalIllness,
      'pastPsychiatricIllness': pastPsychiatricIllness,
      'familyMedicalIllness': familyMedicalIllness,
      'familyPsychiatricIllness': familyPsychiatricIllness,
      'handedness': handedness,
      'pulse': pulse,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'cvs': cvs,
      'rs': rs,
      'git': git,
      'cns': cns,
      if (patientId != null) 'patientId': patientId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

// Patient History Request Model (for creating/updating)
class PatientHistoryRequest {
  final int age;
  final String sex;
  final String maritalStatus;
  final int income;
  final String religion;
  final String education;
  final String occupation;
  final String habitat;
  final String location;
  final String durationOfIllness;
  final int ageOfOnset;
  final int firstMDEAge;
  final bool pastMedicalIllness;
  final bool pastPsychiatricIllness;
  final bool familyMedicalIllness;
  final bool familyPsychiatricIllness;
  final String handedness;
  final int pulse;
  final int bloodPressureSystolic;
  final int bloodPressureDiastolic;
  final String cvs;
  final String rs;
  final String git;
  final String cns;

  PatientHistoryRequest({
    required this.age,
    required this.sex,
    required this.maritalStatus,
    required this.income,
    required this.religion,
    required this.education,
    required this.occupation,
    required this.habitat,
    required this.location,
    required this.durationOfIllness,
    required this.ageOfOnset,
    required this.firstMDEAge,
    required this.pastMedicalIllness,
    required this.pastPsychiatricIllness,
    required this.familyMedicalIllness,
    required this.familyPsychiatricIllness,
    required this.handedness,
    required this.pulse,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
    required this.cvs,
    required this.rs,
    required this.git,
    required this.cns,
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'sex': sex,
      'maritalStatus': maritalStatus,
      'income': income,
      'religion': religion,
      'education': education,
      'occupation': occupation,
      'habitat': habitat,
      'location': location,
      'durationOfIllness': durationOfIllness,
      'ageOfOnset': ageOfOnset,
      'firstMDEAge': firstMDEAge,
      'pastMedicalIllness': pastMedicalIllness,
      'pastPsychiatricIllness': pastPsychiatricIllness,
      'familyMedicalIllness': familyMedicalIllness,
      'familyPsychiatricIllness': familyPsychiatricIllness,
      'handedness': handedness,
      'pulse': pulse,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'cvs': cvs,
      'rs': rs,
      'git': git,
      'cns': cns,
    };
  }
}
