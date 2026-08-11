import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../Constants/constants.dart';
import '../../models/doctor_model.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import 'package:get_storage/get_storage.dart';

class DoctorViewController extends GetxController {
  var docDetails = DoctorData().obs;
  var isLoading = false.obs;
  TextEditingController searchText = TextEditingController();
  TextEditingController droopDownController = TextEditingController();
  final NotificationService notificationService = Get.put(NotificationService());
  final GetStorage box = GetStorage();

  @override
  onInit() {
    super.onInit();
    fetchDocDetails();
  }

  fetchDocDetails() async {
    try {
      final loginDetails = GetStorage().read('loginDetails');
      final userId =
          loginDetails?['user']?['_id'] ?? loginDetails?['user']?['uid'];

      print('👨‍⚕️ [DOCTOR] Fetching doctor details for user: $userId');

      // Use new API endpoint from documentation
      final response = await apiService.get(
        Constants.doctorGetAllPatients,
        requiresAuth: true,
      );

      if (response.success) {
        print('👨‍⚕️ [DOCTOR] ✅ Doctor details fetched successfully!');
        print('👨‍⚕️ [DOCTOR] 🔍 Response structure: ${response.rawData?.runtimeType}');
        print('👨‍⚕️ [DOCTOR] 📋 Response data: ${response.rawData}');
        
        // Handle the actual API response structure
        if (response.rawData != null && response.rawData!['data'] is List) {
          final patientList = response.rawData!['data'] as List<dynamic>;
          print('👨‍⚕️ [DOCTOR] 📊 Found ${patientList.length} patients');
          
          // Create a proper doctor data structure with correct PatientInfo format
          final patientInfoList = patientList.map((patient) => {
            'patient': {
              ...patient,
              'uid': patient['_id'],
              'name': '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim(),
            },
            'relative': []
          }).toList();
          
          final doctorDataMap = {
            'data': {
              'doctor_info': null, // We'll fetch this separately if needed
              'patient_info': patientInfoList
            }
          };
          
          docDetails.value = doctorDataFromJson(jsonEncode(doctorDataMap));
          print('👨‍⚕️ [DOCTOR] ✅ Doctor data structure created successfully');
        } else {
          print('👨‍⚕️ [DOCTOR] ⚠️ Unexpected response structure');
        }
      } else {
        print(
            '👨‍⚕️ [DOCTOR] ❌ Failed to fetch doctor details: ${response.message}');
      }
    } catch (er) {
      print('❌ [DOCTOR] Error fetching doctor details: $er');
    }
  }

  // Get all doctors (for doctor selection)
  var allDoctors = <Map<String, dynamic>>[].obs;
  
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      print('👨‍⚕️ [DOCTOR] Fetching all doctors...');

      final response = await apiService.get(
        Constants.doctorGetAllDoctors,
        requiresAuth: true,
      );

      if (response.success) {
        print('👨‍⚕️ [DOCTOR] ✅ All doctors fetched successfully!');
        final doctors = List<Map<String, dynamic>>.from(response.rawData?['data'] ?? []);
        allDoctors.value = doctors;
        return doctors;
      } else {
        print(
            '👨‍⚕️ [DOCTOR] ❌ Failed to fetch all doctors: ${response.message}');
        return [];
      }
    } catch (er) {
      print('❌ [DOCTOR] Error fetching all doctors: $er');
      return [];
    }
  }

  // Get all patients
  var allPatients = <Map<String, dynamic>>[].obs;
  
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    try {
      print('👨‍⚕️ [DOCTOR] Fetching all patients...');

      final response = await apiService.get(
        Constants.doctorGetAllPatients,
        requiresAuth: true,
      );

      if (response.success) {
        print('👨‍⚕️ [DOCTOR] ✅ All patients fetched successfully!');
        final patients = List<Map<String, dynamic>>.from(response.rawData?['data'] ?? []);
        allPatients.value = patients;
        return patients;
      } else {
        print('👨‍⚕️ [DOCTOR] ❌ Failed to fetch all patients: ${response.message}');
        return [];
      }
    } catch (er) {
      print('❌ [DOCTOR] Error fetching all patients: $er');
      return [];
    }
  }

  // Assign quiz to patient using new backend API
  Future<bool> assignQuizToPatient(String patientId, String questionnaireType) async {
    try {
      // Use quiz type directly (HAM_D or BDI)
      String backendType = questionnaireType;
      print('👨‍⚕️ [DOCTOR] Assigning quiz to patient: $patientId, type: $backendType');

      final response = await apiService.post(
        Constants.quizAssign,
        body: {
          "patientId": patientId,
          "questionnaireType": backendType,
        },
        requiresAuth: true,
      );

      
      if (response.statusCode == 201 || response.success) {
        print('👨‍⚕️ [DOCTOR] ✅ Quiz assigned successfully!');
        
        // Send notification to patient about quiz assignment (with error handling)
        try {
          await _sendQuizAssignmentNotification(patientId, backendType);
        } catch (notificationError) {
          print('⚠️ [DOCTOR] Notification failed but quiz assignment succeeded: $notificationError');
        }
        
        return true;
      } else {
        print('👨‍⚕️ [DOCTOR] ❌ Failed to assign quiz: ${response.message}');
        return false;
      }
    } catch (er) {
      print('❌ [DOCTOR] Error assigning quiz: $er');
      return false;
    }
  }

  /// Send notification to patient when quiz is assigned
  Future<void> _sendQuizAssignmentNotification(String patientId, String questionnaireType) async {
    try {
      // Get current doctor info
      final loginDetails = box.read('loginDetails');
      final doctorName = loginDetails?['user']?['fullName'] ?? 
                        loginDetails?['user']?['name'] ?? 
                        'Your Doctor';
      
      print('🔔 [DOCTOR] ═══ QUIZ NOTIFICATION DEBUG START ═══');
      print('🔔 [DOCTOR] Sending quiz assignment notification to patient: $patientId');
      print('🔔 [DOCTOR] Doctor name: $doctorName');
      print('🔔 [DOCTOR] Quiz type received: "$questionnaireType"');
      print('🔔 [DOCTOR] Quiz type length: ${questionnaireType.length}');
      print('🔔 [DOCTOR] Quiz type bytes: ${questionnaireType.codeUnits}');
      
      final success = await notificationService.notifyPatientQuizAssigned(
        patientId: patientId,
        doctorName: doctorName,
        quizType: questionnaireType,
      );
      
      if (success) {
        print('🔔 [DOCTOR] ✅ Quiz assignment notification sent successfully!');
      } else {
        print('🔔 [DOCTOR] ❌ Failed to send quiz assignment notification');
      }
    } catch (e) {
      print('❌ [DOCTOR] Error sending quiz assignment notification: $e');
    }
  }

  // Reactive list for assigned quizzes
  final RxList<Map<String, dynamic>> assignedQuizzes = <Map<String, dynamic>>[].obs;

  // Get quizzes assigned by this doctor
  Future<void> getQuizAssignedByMe() async {
    try {
      isLoading.value = true;
      print('👨‍⚕️ [DOCTOR] Fetching quizzes assigned by me...');

      final response = await apiService.get(
        Constants.quizGetQuizAssignedByMe,
        requiresAuth: true,
      );

      if (response.success) {
        print('👨‍⚕️ [DOCTOR] ✅ Assigned quizzes fetched successfully!');
        final quizzes = List<Map<String, dynamic>>.from(response.rawData?['data'] ?? []);
        assignedQuizzes.value = quizzes;
      } else {
        print('👨‍⚕️ [DOCTOR] ❌ Failed to fetch assigned quizzes: ${response.message}');
        assignedQuizzes.clear();
      }
    } catch (er) {
      print('❌ [DOCTOR] Error fetching assigned quizzes: $er');
      assignedQuizzes.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Get quizzes assigned by this doctor (legacy method)
  Future<List<Map<String, dynamic>>> getQuizzesAssignedByMe() async {
    try {
      print('👨‍⚕️ [DOCTOR] Fetching quizzes assigned by me...');

      final response = await apiService.get(
        Constants.quizGetQuizAssignedByMe,
        requiresAuth: true,
      );

      if (response.success) {
        print('👨‍⚕️ [DOCTOR] ✅ Assigned quizzes fetched successfully!');
        return List<Map<String, dynamic>>.from(response.rawData?['data'] ?? []);
      } else {
        print('👨‍⚕️ [DOCTOR] ❌ Failed to fetch assigned quizzes: ${response.message}');
        return [];
      }
    } catch (er) {
      print('❌ [DOCTOR] Error fetching assigned quizzes: $er');
      return [];
    }
  }
}
