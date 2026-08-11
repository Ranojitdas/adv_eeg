import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Controller to manage data context for different user types
/// Handles switching between patient data and relative viewing patient data
class DataContextController extends GetxController {
  final _storage = GetStorage();
  
  // Current user info
  RxString currentUserId = ''.obs;
  RxString currentUserRole = ''.obs;
  
  // Patient data context (for relatives viewing patient data)
  RxString viewingPatientId = ''.obs;
  RxString viewingPatientName = ''.obs;
  RxBool isViewingAsRelative = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeUserContext();
  }
  
  /// Initialize user context from stored login details
  void _initializeUserContext() {
    final loginDetails = _storage.read('loginDetails');
    if (loginDetails != null && loginDetails['user'] != null) {
      currentUserId.value = loginDetails['user']['_id'] ?? '';
      currentUserRole.value = loginDetails['user']['role'] ?? '';
      
      print('🔄 [DATA_CONTEXT] Initialized - User: ${currentUserId.value}, Role: ${currentUserRole.value}');
    }
  }
  
  /// Set patient context for relatives to view patient data
  void setPatientContext(String patientId, String patientName) {
    viewingPatientId.value = patientId;
    viewingPatientName.value = patientName;
    isViewingAsRelative.value = true;
    
    print('🔄 [DATA_CONTEXT] Set patient context - Patient: $patientId ($patientName)');
    print('🔄 [DATA_CONTEXT] Relative ${currentUserId.value} now viewing patient data');
  }
  
  /// Clear patient context (return to own data)
  void clearPatientContext() {
    viewingPatientId.value = '';
    viewingPatientName.value = '';
    isViewingAsRelative.value = false;
    
    print('🔄 [DATA_CONTEXT] Cleared patient context - Back to own data');
  }
  
  /// Get the user ID to use for data fetching
  String getDataUserId() {
    if (isViewingAsRelative.value && viewingPatientId.value.isNotEmpty) {
      print('🔄 [DATA_CONTEXT] Using patient ID for data: ${viewingPatientId.value}');
      return viewingPatientId.value;
    }
    
    print('🔄 [DATA_CONTEXT] Using current user ID for data: ${currentUserId.value}');
    return currentUserId.value;
  }
  
  /// Check if currently viewing as relative
  bool get isRelativeView => isViewingAsRelative.value;
  
  /// Get display name for current context
  String getContextDisplayName() {
    if (isViewingAsRelative.value && viewingPatientName.value.isNotEmpty) {
      return "${viewingPatientName.value}'s Data";
    }
    return "My Data";
  }
  
  /// Reset context on logout
  void resetContext() {
    currentUserId.value = '';
    currentUserRole.value = '';
    clearPatientContext();
    
    print('🔄 [DATA_CONTEXT] Context reset on logout');
  }
}
