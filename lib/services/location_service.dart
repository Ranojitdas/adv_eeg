import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../Constants/constants.dart';
import '../services/api_service.dart';

class LocationService extends GetxController {
  var currentLocation = <String, dynamic>{}.obs;
  var isLocationEnabled = false.obs;
  final GetStorage box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    checkLocationPermission();
  }

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('📍 [LOCATION] Location services are disabled');
      isLocationEnabled.value = false;
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('📍 [LOCATION] Location permissions are denied');
        isLocationEnabled.value = false;
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('📍 [LOCATION] Location permissions are permanently denied');
      isLocationEnabled.value = false;
      return false;
    }

    isLocationEnabled.value = true;
    return true;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      print('📍 [LOCATION] Starting location retrieval process...');
      
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        print('📍 [LOCATION] ❌ Location permission not granted');
        return null;
      }
      
      print('📍 [LOCATION] ✅ Location permission granted, getting position...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('📍 [LOCATION] ✅ Position retrieved successfully');
      print('📍 [LOCATION] Latitude: ${position.latitude}');
      print('📍 [LOCATION] Longitude: ${position.longitude}');
      print('📍 [LOCATION] Accuracy: ${position.accuracy}m');

      currentLocation.value = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('📍 [LOCATION] Location data stored in observable');

      return position;
    } catch (e) {
      print('❌ [LOCATION] Exception getting current location: $e');
      print('❌ [LOCATION] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Update user location on backend
  Future<bool> updateUserLocation({
    String? context, // 'login', 'quiz_attempt', 'general'
  }) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        print('📍 [LOCATION] Cannot update location - position unavailable');
        return false;
      }

      final loginDetails = box.read('loginDetails');
      if (loginDetails == null) {
        print('📍 [LOCATION] Cannot update location - user not logged in');
        return false;
      }

      final payload = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'context': context ?? 'general',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📍 [LOCATION] Updating user location for context: $context');

      final response = await apiService.patch(
        Constants.userUpdateLocation,
        body: payload,
        requiresAuth: true,
      );

      if (response.success) {
        print('📍 [LOCATION] ✅ Location updated successfully');
        return true;
      } else {
        print('📍 [LOCATION] ❌ Failed to update location: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ [LOCATION] Error updating location: $e');
      return false;
    }
  }

  /// Update location on backend with context
  Future<bool> updateLocationWithContext(String context) async {
    try {
      print('📍 [LOCATION] Starting location update process with context: $context');
      
      final position = await getCurrentLocation();
      if (position == null) {
        print('📍 [LOCATION] ❌ Cannot update location - position retrieval failed');
        return false;
      }

      print('📍 [LOCATION] Preparing backend update request...');
      print('📍 [LOCATION] Coordinates: [${position.latitude}, ${position.longitude}]');
      print('📍 [LOCATION] Context: $context');
      print('📍 [LOCATION] API Endpoint: ${Constants.userUpdateLocation}');

      final response = await apiService.patch(
        Constants.userUpdateLocation,
        body: {
          "coordinates": [position.latitude, position.longitude]
        },
        requiresAuth: true,
      );

      print('📍 [LOCATION] Backend update API call completed');
      
      if (response.success) {
        print('📍 [LOCATION] ✅ Location updated successfully on backend');
        print('📍 [LOCATION] Response data: ${response.rawData}');
        return true;
      } else {
        print('📍 [LOCATION] ❌ Backend location update failed');
        print('📍 [LOCATION] Error message: ${response.message}');
        print('📍 [LOCATION] Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [LOCATION] Exception in location update: $e');
      print('❌ [LOCATION] Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Update location on login
  Future<void> updateLocationOnLogin() async {
    print('📍 [LOCATION] Triggered location update for LOGIN event');
    final success = await updateLocationWithContext('login');
    if (success) {
      print('📍 [LOCATION] ✅ Login location update completed successfully');
    } else {
      print('📍 [LOCATION] ❌ Login location update failed');
    }
  }

  /// Update location on quiz attempt
  Future<void> updateLocationOnQuizAttempt() async {
    print('📍 [LOCATION] Triggered location update for QUIZ ATTEMPT event');
    final success = await updateLocationWithContext('quiz_attempt');
    if (success) {
      print('📍 [LOCATION] ✅ Quiz attempt location update completed successfully');
    } else {
      print('📍 [LOCATION] ❌ Quiz attempt location update failed');
    }
  }

  /// Update location generally (can be called anywhere)
  Future<void> updateLocationGeneral() async {
    await updateUserLocation(context: 'general');
  }

  /// Get location display string
  String getLocationDisplayString() {
    if (currentLocation.isEmpty) return 'Location not available';
    
    final lat = currentLocation['latitude']?.toStringAsFixed(4) ?? '0.0000';
    final lng = currentLocation['longitude']?.toStringAsFixed(4) ?? '0.0000';
    
    return '$lat, $lng';
  }
}
