import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../Constants/constants.dart';

// Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? rawData;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.rawData,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? data) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: data,
      message: json['message'],
      statusCode: json['statusCode'],
      rawData: json,
    );
  }

  factory ApiResponse.error(String message, int? statusCode) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final GetStorage _storage = GetStorage();

  // HTTP client with timeout
  final http.Client _client = http.Client();

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      // Check token expiration before making request
      if (requiresAuth && !isAuthenticated) {
        print('❌ [AUTH] Token expired or missing, redirecting to login');
        // Only redirect if not in signup/registration flow and not already on landing page
        if (!Get.currentRoute.contains('SignUp') && 
            !Get.currentRoute.contains('OtpVerification') &&
            !Get.currentRoute.contains('LandingPage') &&
            Get.currentRoute != '/') {
          Get.offAllNamed('/LandingPage');
        }
        return ApiResponse.error('Authentication required. Please login again.', 401);
      }

      final requestHeaders =
          requiresAuth ? Constants.authHeader : Constants.header;
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      print('🌐 [API] GET Request: $endpoint');
      print('🌐 [API] Headers: $requestHeaders');

      final response = await _client
          .get(Uri.parse(endpoint), headers: requestHeaders)
          .timeout(const Duration(seconds: 30));

      print('🌐 [API] Response Status: ${response.statusCode}');
      print('🌐 [API] Response Body: ${response.body}');

      // Handle 401 Unauthorized responses
      if (response.statusCode == 401) {
        print('❌ [AUTH] Received 401 Unauthorized, clearing auth and redirecting');
        clearAuth();
        // Only redirect if not in signup/registration flow and not already on landing page
        if (!Get.currentRoute.contains('SignUp') && 
            !Get.currentRoute.contains('OtpVerification') &&
            !Get.currentRoute.contains('LandingPage') &&
            Get.currentRoute != '/') {
          Get.offAllNamed('/LandingPage');
        }
        return ApiResponse.error('Session expired. Please login again.', 401);
      }

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('❌ [API] GET Request Error: $e');
      return ApiResponse.error('Network error: $e', null);
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      final requestHeaders =
          requiresAuth ? Constants.authHeader : Constants.header;
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      print('🌐 [API] POST Request: $endpoint');
      print('🌐 [API] Body: ${jsonEncode(body)}');
      print('🌐 [API] Headers: $requestHeaders');

      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      print('🌐 [API] Response Status: ${response.statusCode}');
      print('🌐 [API] Response Body: ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('❌ [API] POST Request Error: $e');
      return ApiResponse.error('Network error: $e', null);
    }
  }

  // Generic PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      final requestHeaders =
          requiresAuth ? Constants.authHeader : Constants.header;
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      print('🌐 [API] PATCH Request: $endpoint');
      print('🌐 [API] Body: ${jsonEncode(body)}');
      print('🌐 [API] Headers: $requestHeaders');

      final response = await _client
          .patch(
            Uri.parse(endpoint),
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      print('🌐 [API] Response Status: ${response.statusCode}');
      print('🌐 [API] Response Body: ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('❌ [API] PATCH Request Error: $e');
      return ApiResponse.error('Network error: $e', null);
    }
  }

  // Handle response and parse JSON
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html')) {
        print('❌ [API] Received HTML error page instead of JSON');
        String errorMessage = 'Server error';

        // Try to extract error message from HTML
        if (response.body.contains('Unauthorized')) {
          errorMessage =
              'Invalid credentials. Please check your email and password.';
        } else if (response.body.contains('Cannot POST')) {
          errorMessage =
              'Endpoint not found. Please check the API configuration.';
        } else if (response.body.contains('Not Found')) {
          errorMessage = 'Resource not found.';
        } else {
          errorMessage =
              'Server returned an error page (${response.statusCode})';
        }

        return ApiResponse.error(errorMessage, response.statusCode);
      }

      final jsonData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        T? data;
        if (fromJson != null && jsonData is Map<String, dynamic>) {
          data = fromJson(jsonData);
        }

        return ApiResponse(
          success: true,
          data: data,
          message: jsonData['message'],
          statusCode: response.statusCode,
          rawData: jsonData,
        );
      } else {
        final message = jsonData['message'] ??
            'Request failed with status ${response.statusCode}';
        return ApiResponse.error(message, response.statusCode);
      }
    } catch (e) {
      print('❌ [API] Response parsing error: $e');
      return ApiResponse.error(
          'Failed to parse response: $e', response.statusCode);
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated {
    final token = _storage.read('loginDetails')?['token'];
    if (token == null || token.isEmpty) return false;
    
    // Check if token is expired
    return !_isTokenExpired(token);
  }

  // Get current user token
  String? get currentToken {
    final token = _storage.read('loginDetails')?['token'];
    if (token != null && _isTokenExpired(token)) {
      print('⚠️ [AUTH] Token is expired, clearing auth data');
      clearAuth();
      return null;
    }
    return token;
  }

  // Check if JWT token is expired
  bool _isTokenExpired(String token) {
    try {
      // JWT tokens have 3 parts separated by dots
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Decode the payload (second part)
      final payload = parts[1];
      // Add padding if needed for base64 decoding
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);

      // Check expiration time
      final exp = payloadMap['exp'];
      if (exp == null) return true;

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      
      print('🕒 [AUTH] Token expires at: $expirationTime');
      print('🕒 [AUTH] Current time: $now');
      
      return now.isAfter(expirationTime);
    } catch (e) {
      print('❌ [AUTH] Error checking token expiration: $e');
      return true; // Assume expired if we can't parse it
    }
  }

  // Clear authentication data
  void clearAuth() {
    _storage.remove('loginDetails');
    _storage.remove('timestamp');
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String url, {
    bool requiresAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      print('🗑️ [API] DELETE Request: $url');

      final headers = requiresAuth ? Constants.authHeader : Constants.header;

      final response = await _client.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('🗑️ [API] DELETE Response: ${response.statusCode}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('❌ [API] DELETE Request Error: $e');
      return ApiResponse.error('Network error: $e', null);
    }
  }

  // Handle token refresh (if needed)
  Future<bool> refreshToken() async {
    // Implement token refresh logic here if your backend supports it
    // For now, return false to trigger re-login
    return false;
  }

  // Dispose resources
  void dispose() {
    _client.close();
  }
}

// Global API service instance
final apiService = ApiService();
