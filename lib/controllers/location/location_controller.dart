import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../Constants/constants.dart';
import '../../services/api_service.dart';

class LocationController extends GetxController {
  RxDouble latitude = 0.0.obs;
  RxDouble longitude = 0.0.obs;
  RxBool hasLocation = false.obs;
  RxBool isUpdatingLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      print('🌍 [LOCATION] Starting location request...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('🌍 [LOCATION] Location services are disabled');
        hasLocation.value = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('🌍 [LOCATION] Location permission denied');
          hasLocation.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('🌍 [LOCATION] Location permission permanently denied');
        hasLocation.value = false;
        return;
      }

      // Try to get last known position first for faster response
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        print('🌍 [LOCATION] Using last known position: ${lastPosition.latitude}, ${lastPosition.longitude}');
        latitude.value = lastPosition.latitude;
        longitude.value = lastPosition.longitude;
        hasLocation.value = true;
        
        // Update backend with location
        await updateLocationInBackend();
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      print('🌍 [LOCATION] Current position obtained: ${position.latitude}, ${position.longitude}');
      latitude.value = position.latitude;
      longitude.value = position.longitude;
      hasLocation.value = true;
      
      // Update backend with location
      await updateLocationInBackend();
    } catch (e) {
      print('🌍 [LOCATION] Error getting location: $e');
      hasLocation.value = false;
    }
  }

  Future<void> updateLocationInBackend() async {
    if (!hasLocation.value || isUpdatingLocation.value) return;
    
    try {
      isUpdatingLocation.value = true;
      print('🌍 [LOCATION] Updating location in backend...');

      final response = await apiService.patch(
        Constants.userUpdateLocation,
        body: {
          "coordinates": [latitude.value, longitude.value]
        },
        requiresAuth: true,
      );

      if (response.success) {
        print('🌍 [LOCATION] ✅ Location updated successfully in backend');
      } else {
        print('🌍 [LOCATION] ❌ Failed to update location: ${response.message}');
      }
    } catch (e) {
      print('🌍 [LOCATION] Error updating location in backend: $e');
    } finally {
      isUpdatingLocation.value = false;
    }
  }

  // Get location data for other controllers
  Map<String, double> getLocationData() {
    return {
      'latitude': latitude.value,
      'longitude': longitude.value,
    };
  }

  // Force location refresh
  Future<void> refreshLocation() async {
    hasLocation.value = false;
    await getCurrentLocation();
  }
}
