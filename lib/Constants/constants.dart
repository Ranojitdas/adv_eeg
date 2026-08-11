import 'package:get_storage/get_storage.dart';

class Constants {
  // Base API URL - Update this to match your new backend
  static String apiUrl =
      'https://api.knowurmind.com/api/v1';

  // Basic headers for non-authenticated requests
  static Map<String, String> header = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get authenticated headers with JWT token
  static Map<String, String> get authHeader {
    final token = GetStorage().read('loginDetails')?['token'] ?? '';
    if (token.isEmpty) {
      print('⚠️ [AUTH] No token found in storage');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ===== USER ROUTES (api/v1/users) =====
  static String get userRegister => '$apiUrl/users/register';
  static String get userVerifyOtp => '$apiUrl/users/verify-otp';
  static String get userLogin => '$apiUrl/users/login';
  static String get userMe => '$apiUrl/users/me';
  static String get userLogout => '$apiUrl/users/logout';
  static String get userForgotPassword => '$apiUrl/users/forgot-password';
  static String getResetPassword(String token) => '$apiUrl/users/reset-password/$token';
  static String get userUpdateLocation => '$apiUrl/users/update-user-location';
  static String getUserById(String id) => '$apiUrl/users/$id';

  // ===== DOCTOR ROUTES (api/v1/doctor) =====
  static String get doctorGetAllDoctors => '$apiUrl/doctor/get-all-doctors';
  static String get doctorGetAllPatients => '$apiUrl/doctor/get-all-patients';

  // ===== RELATIVE ROUTES (api/v1/relative) =====
  static String get relativeGetMonitoredPatient =>
      '$apiUrl/relative/get-monitored-patient';

  // ===== QUESTION ROUTES (api/v1/question) =====
  static String get questionCreate => '$apiUrl/question/create';
  static String get questionAll => '$apiUrl/question/all';
  static String getQuestionByType(String type) => '$apiUrl/question/type/$type';
  static String getQuestionById(String questionId) =>
      '$apiUrl/question/$questionId';

  // ===== QUIZ ROUTES (api/v1/quiz) =====
  static String get quizAssign => '$apiUrl/quiz/assign';
  static String get quizMyAssignedQuiz => '$apiUrl/quiz/my-assigned-quiz';
  static String get quizSelfInitiate => '$apiUrl/quiz/self-initiate';
  static String getQuizSubmit(String quizAttemptId) =>
      '$apiUrl/quiz/submit/$quizAttemptId';
  static String getQuizHistory(String patientId) =>
      '$apiUrl/quiz/history/$patientId';
  static String get quizMyAllQuizzes => '$apiUrl/quiz/my-all-quizzes';
  static String getQuizById(String quizAttemptId) =>
      '$apiUrl/quiz/get-quiz-by-id/$quizAttemptId';
  static String get quizGetQuizAssignedByMe =>
      '$apiUrl/quiz/get-quiz-assigned-by-me';

  // ===== PATIENT HISTORY ROUTES (api/v1/patient-history) =====
  static String get patientHistoryCreate => '$apiUrl/patient-history';
  static String get patientHistoryGet => '$apiUrl/patient-history';
  static String get patientHistory => '$apiUrl/patient-history';

  // ===== NOTIFICATION ROUTES (api/v1/notification) =====
  static String get notificationCreate => '$apiUrl/notification';
  static String get notificationsGet => '$apiUrl/notification';
  static String get notificationsGetAll => '$apiUrl/notification/get-notifications';
  static String notificationMarkAsRead(String notificationId) => 
      '$apiUrl/notification/$notificationId/read';
  static String get notificationsMarkAllAsRead => '$apiUrl/notification/mark-all-read';
  static String getNotificationDelete(String notificationId) => 
      '$apiUrl/notification/$notificationId';
  static String get notificationsDeleteAll => '$apiUrl/notification/delete-all';
  static String get notificationsStats => '$apiUrl/notification/stats';
  static String get notificationsUnreadCount => '$apiUrl/notification/unread-count';
  static String getNotificationsByType(String type) => 
      '$apiUrl/notification/type/$type';
  static String get notificationsPreferences => '$apiUrl/notification/preferences';

  // ===== BRAIN SIGNAL ROUTES (api/v1/brain-signal-score) =====
  static String get brainSignalStore => '$apiUrl/brain-signal-score/store';
  static String getBrainSignalScores(String userId) => 
      '$apiUrl/brain-signal-score/$userId';
  static String getBrainSignalLatestScore(String userId) => 
      '$apiUrl/brain-signal-score/latest/$userId';

  // Debug method to print current configuration
  static void printConfig() {
    print('🔧 [CONFIG] API URL: $apiUrl');
    print('🔧 [CONFIG] Headers: $header');
  }

  // Debug method to print auth header
  static void printAuthHeader() {
    final token = GetStorage().read('loginDetails')?['token'] ?? '';
    print(
        '🔧 [CONFIG] Auth Token: ${token.isNotEmpty ? '${token.substring(0, 20)}...' : 'NOT SET'}');
    print('🔧 [CONFIG] Auth Header: $authHeader');
  }

  // Debug method to clear stored data for testing
  static void clearStoredData() {
    GetStorage().erase();
    print('🔧 [CONFIG] Cleared all stored data for testing');
  }
}

String predictionUrl = 'https://eeg-prediction-main-new-production.up.railway.app/';
