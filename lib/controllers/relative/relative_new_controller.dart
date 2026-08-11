import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../Constants/constants.dart';
import '../../services/api_service.dart';

class RelativeNewController extends GetxController {
  var isLoading = false.obs;
  var monitoredPatient = Rxn<Map<String, dynamic>>();

  // Get monitored patient using new backend API
  Future<Map<String, dynamic>?> getMonitoredPatient() async {
    try {
      isLoading.value = true;
      print('👥 [RELATIVE] Fetching monitored patient...');

      final response = await apiService.get(
        Constants.relativeGetMonitoredPatient,
        requiresAuth: true,
      );

      if (response.success) {
        print('👥 [RELATIVE] ✅ Monitored patient fetched successfully!');
        final patientData = response.rawData?['data'] ?? response.rawData;
        monitoredPatient.value = patientData;
        return patientData;
      } else {
        print('👥 [RELATIVE] ❌ Failed to fetch monitored patient: ${response.message}');
        return null;
      }
    } catch (err) {
      print('❌ [RELATIVE] Error fetching monitored patient: $err');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Clear monitored patient data
  void clearMonitoredPatient() {
    monitoredPatient.value = null;
  }
}
