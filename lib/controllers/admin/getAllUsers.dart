import 'dart:convert';

import 'package:ADDvEEG/models/anyUserModel.dart';
import 'package:get/get.dart';

import '../../Constants/constants.dart';
import '../../services/api_service.dart';

class UsersController extends GetxController {
  UsersController(this.role);
  final String role;
  var users = User().obs;
  var doctors = User().obs;
  var relatives = User().obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchUsers();
    super.onInit();
  }

  void fetchUsers() async {
    try {
      print('👥 [ADMIN] Fetching all users by role...');

      // Fetch users (patients) - using new API endpoints
      final usersResponse = await apiService.get(
        Constants.doctorGetAllPatients, // Use doctor endpoint to get patients
        requiresAuth: true,
      );

      // Fetch doctors
      final doctorsResponse = await apiService.get(
        Constants.doctorGetAllDoctors,
        requiresAuth: true,
      );

      // Fetch relatives - this might need a different endpoint
      final relativesResponse = await apiService.get(
        Constants.relativeGetMonitoredPatient, // Use relative endpoint
        requiresAuth: true,
      );

      if (usersResponse.success) {
        print('👥 [ADMIN] ✅ Users fetched successfully!');
        users.value = userFromJson(jsonEncode(usersResponse.rawData));
      } else {
        print('👥 [ADMIN] ❌ Failed to fetch users: ${usersResponse.message}');
      }

      if (doctorsResponse.success) {
        print('👥 [ADMIN] ✅ Doctors fetched successfully!');
        doctors.value = userFromJson(jsonEncode(doctorsResponse.rawData));
      } else {
        print(
            '👥 [ADMIN] ❌ Failed to fetch doctors: ${doctorsResponse.message}');
      }

      if (relativesResponse.success) {
        print('👥 [ADMIN] ✅ Relatives fetched successfully!');
        relatives.value = userFromJson(jsonEncode(relativesResponse.rawData));
      } else {
        print(
            '👥 [ADMIN] ❌ Failed to fetch relatives: ${relativesResponse.message}');
      }
    } catch (err) {
      print('❌ [ADMIN] Error fetching users: $err');
    } finally {
      isLoading(false);
    }
  }
}
