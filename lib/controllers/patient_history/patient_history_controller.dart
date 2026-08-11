import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../Constants/constants.dart';
import '../../models/patient_history/patient_history_models.dart';
import '../../services/api_service.dart';

class PatientHistoryController extends GetxController {
  var isLoading = false.obs;
  var patientHistory = Rxn<PatientHistoryData>();

  // Update patient history using new backend API
  Future<bool> updatePatientHistory(PatientHistoryRequest historyData) async {
    try {
      isLoading.value = true;
      print('🏥 [HISTORY] Updating patient history...');

      final response = await apiService.post(
        Constants.patientHistory,
        body: historyData.toJson(),
        requiresAuth: true,
      );

      if (response.success) {
        print('🏥 [HISTORY] ✅ Patient history updated successfully!');
        
        // Update local data if response contains updated history
        if (response.rawData?['data'] != null) {
          patientHistory.value = PatientHistoryData.fromJson(response.rawData!['data']);
        }
        
        return true;
      } else {
        print('🏥 [HISTORY] ❌ Failed to update patient history: ${response.message}');
        Get.snackbar('Error', response.message ?? 'Failed to update patient history');
        return false;
      }
    } catch (err) {
      print('❌ [HISTORY] Error updating patient history: $err');
      Get.snackbar('Error', 'Network error occurred while updating history');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get patient history using new backend API
  Future<PatientHistoryData?> getPatientHistory({String? patientId}) async {
    try {
      isLoading.value = true;
      print('🏥 [HISTORY] Fetching patient history...');

      String endpoint = Constants.patientHistory;
      Map<String, dynamic>? queryParams;

      // Add patientId as query parameter if provided
      if (patientId != null) {
        endpoint += '?patientId=$patientId';
      }

      final response = await apiService.get(
        endpoint,
        requiresAuth: true,
      );

      if (response.success) {
        print('🏥 [HISTORY] ✅ Patient history fetched successfully!');
        
        final historyData = PatientHistoryData.fromJson(response.rawData?['data'] ?? response.rawData ?? {});
        patientHistory.value = historyData;
        return historyData;
      } else {
        print('🏥 [HISTORY] ❌ Failed to fetch patient history: ${response.message}');
        return null;
      }
    } catch (err) {
      print('❌ [HISTORY] Error fetching patient history: $err');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Get current user's patient history
  Future<PatientHistoryData?> getMyPatientHistory() async {
    try {
      final loginDetails = GetStorage().read('loginDetails');
      final userId = loginDetails?['user']?['_id'] ?? loginDetails?['user']?['uid'];
      
      if (userId != null) {
        return await getPatientHistory(patientId: userId);
      } else {
        print('❌ [HISTORY] User ID not found in login details');
        return null;
      }
    } catch (err) {
      print('❌ [HISTORY] Error getting current user history: $err');
      return null;
    }
  }

  // Clear patient history data
  void clearHistory() {
    patientHistory.value = null;
  }
}
