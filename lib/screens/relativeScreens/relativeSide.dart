import 'package:ADDvEEG/controllers/relative/detailedRelativeViewController.dart';
import 'package:ADDvEEG/controllers/relative/relativeController.dart';
import 'package:ADDvEEG/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/api_service.dart';
import '../../Constants/constants.dart';

import '../doctorScreens/patientDetailedView(DocEnd).dart';
import '../doctorScreens/patient_quiz_details_screen.dart';
import '../patientScreens/health_analytics_page.dart';
import '../../utils/reportGenerator/quizReportGenerator.dart';
import '../../utils/reportGenerator/eegReportGenerator.dart';
import '../../controllers/patientSideControllers/getProfileController.dart';
import '../../controllers/patientSideControllers/quiz_controller.dart';
import '../../controllers/brain_signal/brain_signal_controller.dart';
import '../../models/profile_model.dart';
import '../../models/brainScoreModel.dart';
import '../landing.dart';

class RelativeSide extends StatefulWidget {
  const RelativeSide({super.key});

  @override
  State<RelativeSide> createState() => _RelativeSideState();
}

class _RelativeSideState extends State<RelativeSide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  Timer? _refreshTimer;
  final NotificationController notificationController = Get.put(NotificationController());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Set up periodic notification refresh like patient and doctor screens
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('🔄 [RELATIVE_DASHBOARD] Periodic refresh - checking for new notifications...');
      notificationController.fetchNotifications();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Method to show confirmation dialog and open Google Maps
  void _showOpenMapsDialog(BuildContext context, double lat, double lon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.map_outlined,
                color: const Color(0xFF0850FD),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Open in Google Maps',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Do you want to open this patient\'s location in Google Maps for detailed navigation?',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openGoogleMaps(lat, lon);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0850FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Open Maps',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to open Google Maps with the patient's location
  Future<void> _openGoogleMaps(double lat, double lon) async {
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    final Uri uri = Uri.parse(googleMapsUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to generic maps URL
        final String fallbackUrl = 'geo:$lat,$lon';
        final Uri fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri);
        } else {
          // Show error message
          Get.snackbar(
            'Error',
            'Could not open maps application',
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
      Get.snackbar(
        'Error',
        'Could not open maps application',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    RelativeController relativeController = Get.put(RelativeController());
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;
    final relativeName =
        GetStorage().read('loginDetails')?['user']?['name'] ?? 'Relative';
    final profilePic =
        'https://uxwing.com/wp-content/themes/uxwing/download/peoples-avatars/man-user-circle-icon.png';

    return Obx(
      () => ModalProgressHUD(
        inAsyncCall: relativeController.isLoading.value,
        progressIndicator: Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Patient Data',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Relative Dashboard',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              GetBuilder<NotificationController>(
                builder: (notificationController) {
                  return IconButton(
                    onPressed: () {
                      _showNotificationsBottomSheet(notificationController);
                    },
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications, color: Colors.white),
                        if (notificationController.unreadCount.value > 0)
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '${notificationController.unreadCount.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2A2A2A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Logout Confirmation',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final box = GetStorage();
                            box.remove('loginDetails');
                            box.remove('timestamp');
                            Get.offAll(() => LandingPage());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0850FD),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Background Image with Overlay
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/bg2.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.7),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
              // Pattern Overlay
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/pattern.png'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
                ),
              ),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SafeArea(
                    child: Obx(
                      () => !relativeController.isLoading.value
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0, vertical: 18.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.2),
                                        backgroundImage:
                                            NetworkImage(profilePic),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome, $relativeName',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'You have ${relativeController.data.value.message?.patient?.length ?? 0} patient(s) linked',
                                            style: GoogleFonts.poppins(
                                              color:
                                                  Colors.white.withValues(alpha: 0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                // Quick Actions
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  child: Row(
                                    children: [
                                      _buildQuickAction(
                                        icon: Icons.person_add_alt_1,
                                        label: 'Add Patient',
                                        onTap: () {
                                          Get.snackbar('Coming Soon',
                                              'This feature will allow you to link a patient.',
                                              backgroundColor:
                                                  Colors.white.withValues(alpha: 0.1),
                                              colorText: Colors.black);
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      _buildQuickAction(
                                        icon: Icons.account_circle,
                                        label: 'My Profile',
                                        onTap: () {
                                          Get.snackbar('Coming Soon',
                                              'Profile details will be shown here.',
                                              backgroundColor:
                                                  Colors.white.withValues(alpha: 0.1),
                                              colorText: Colors.black);
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      _buildQuickAction(
                                        icon: Icons.help_outline,
                                        label: 'Help',
                                        onTap: () {
                                          Get.snackbar('Help',
                                              'Contact support at ranojitdas362@gmail.com',
                                              backgroundColor:
                                                  Colors.white.withValues(alpha: 0.1),
                                              colorText: Colors.black);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Summary Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  child: Row(
                                    children: [
                                      _buildSummaryCard(
                                          'Total Patients',
                                          relativeController.data.value.message
                                                  ?.patient?.length
                                                  .toString() ??
                                              '0',
                                          Colors.blue),
                                      const SizedBox(width: 12),
                                      _buildSummaryCard('High Risk', '1',
                                          Colors.red), // Demo value
                                      const SizedBox(width: 12),
                                      _buildSummaryCard('Stable', '0',
                                          Colors.green), // Demo value
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 26),
                                // Patient List or Empty State
                                Expanded(
                                  child: (relativeController
                                          .data.value.message?.patient?.isEmpty ?? true)
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.people_outline_rounded,
                                                size: 64,
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No patients found',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Patients will appear here when assigned',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: ListView.builder(
                                            itemCount: relativeController.data
                                                .value.message?.patient?.length ?? 0,
                                            itemBuilder: (context, index) =>
                                                Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: _buildPatientCard(
                                                context,
                                                relativeController,
                                                index,
                                                isSmallScreen,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        selectedColor: const Color(0xFF0850FD),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF0850FD)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }

  // Get patient location from backend API
  Future<Map<String, dynamic>?> _getPatientLocation(String patientId) async {
    try {
      print('📍 [RELATIVE] Fetching location for patient: $patientId');
      
      // Get the API service
      final apiService = ApiService();
      
      final response = await apiService.get(
        Constants.getUserById(patientId),
        requiresAuth: true,
      );

      if (response.success && response.rawData != null) {
        print('📍 [RELATIVE] Location API response: ${response.rawData}');
        final userData = response.rawData!['data'] ?? response.rawData;
        return userData;
      } else {
        print('📍 [RELATIVE] Failed to fetch location: ${response.message}');
        return null;
      }
    } catch (e) {
      print('📍 [RELATIVE] Error getting patient location: $e');
      return null;
    }
  }

  String _getPatientName(dynamic patient) {
    if (patient == null) return 'Unknown Patient';
    
    // Try different possible name fields from API response
    if (patient.name != null && patient.name.isNotEmpty) {
      return patient.name;
    }
    
    // Try username as fallback
    if (patient.username != null && patient.username.isNotEmpty) {
      return patient.username;
    }
    
    // Try email prefix as last resort
    if (patient.email != null && patient.email.isNotEmpty) {
      return patient.email.split('@')[0];
    }
    
    return 'Unknown Patient';
  }

  Widget _buildPatientCard(
    BuildContext context,
    RelativeController relativeController,
    int index,
    bool isSmallScreen,
  ) {
    final patient = relativeController.data.value.message?.patient?[index];
    print('🔍 [DEBUG] Patient data at index $index: ${patient?.toJson()}');
    print('🔍 [DEBUG] Patient UID: ${patient?.uid}');
    print('🔍 [DEBUG] Patient Name: ${patient?.name}');
    print('🔍 [DEBUG] Patient Username: ${patient?.username}');
    print('🔍 [DEBUG] Patient Email: ${patient?.email}');
    if (patient == null) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.to(
            () => PatientDetailedView(
              uid: patient.uid ?? '',
            ),
            arguments: patient,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0850FD).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      backgroundImage: const NetworkImage(
                        'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPatientName(patient),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patient.email ?? 'No email',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'View',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0850FD),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Show patient location from backend data
              FutureBuilder<Map<String, dynamic>?>(
                future: _getPatientLocation(patient.uid ?? ''),
                builder: (context, snapshot) {
                  print('Backend location for ${patient.uid}: ${snapshot.data}');
                  double? lat;
                  double? lon;
                  if (snapshot.hasData && snapshot.data != null) {
                    final locationData = snapshot.data!;
                    if (locationData['currentLocation'] != null && 
                        locationData['currentLocation']['coordinates'] != null) {
                      final coords = locationData['currentLocation']['coordinates'] as List;
                      if (coords.length >= 2) {
                        lat = (coords[0] as num?)?.toDouble();
                        lon = (coords[1] as num?)?.toDouble();
                      }
                    }
                  }
                  if (lat != null && lon != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(lat, lon),
                                initialZoom: 13,
                                onTap: (tapPosition, point) {
                                  if (lat != null && lon != null) {
                                    _showOpenMapsDialog(context, lat, lon);
                                  }
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c'],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      width: 40,
                                      height: 40,
                                      point: LatLng(lat, lon),
                                      child: const Icon(Icons.location_pin,
                                          color: Colors.red, size: 40),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        FutureBuilder<List<Placemark>>(
                          future: placemarkFromCoordinates(lat, lon),
                          builder: (context, placeSnapshot) {
                            if (placeSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (placeSnapshot.hasError ||
                                placeSnapshot.data == null ||
                                placeSnapshot.data!.isEmpty) {
                              return Text(
                                'Place name not available',
                                style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.7)),
                              );
                            } else {
                              final placemark = placeSnapshot.data!.first;
                              final placeName = [
                                placemark.locality,
                                placemark.subLocality,
                                placemark.administrativeArea,
                                placemark.country
                              ]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join(', ');
                              return Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.place,
                                        color: Color(0xFF0850FD), size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        placeName,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  } else {
                    return Center(
                      child: Text(
                        'Location not available',
                        style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    );
                  }
                },
              ),
              FutureBuilder(
                future: relativeController.fetchQuiz(
                  patient.uid ?? '',
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasData &&
                      relativeController.quiz.value.data.isNotEmpty) {
                    final latestQuiz =
                        relativeController.quiz.value.data.first;
                    final isDepressed =
                        latestQuiz.questionnaireType == 'BDI'
                            ? latestQuiz.score > 20
                            : latestQuiz.score > 17;

                    if (isDepressed) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'High Depression Score',
                                  style: GoogleFonts.poppins(
                                    color: Colors.red.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    if (latestQuiz.latitude != null &&
                                        latestQuiz.longitude != null)
                                      Image.network(
                                        'https://staticmap.openstreetmap.de/staticmap.php?center=${latestQuiz.latitude},${latestQuiz.longitude}&zoom=15&size=600x300&markers=${latestQuiz.latitude},${latestQuiz.longitude},red',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[800],
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.location_off,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5),
                                                    size: 32,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Location not available',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.5),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    else
                                      Container(
                                        color: Colors.grey[800],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.location_off,
                                                color: Colors.white
                                                    .withValues(alpha: 0.5),
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Location not available',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (latestQuiz.latitude != null &&
                                        latestQuiz.longitude != null)
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: InkWell(
                                            onTap: () {
                                              final url =
                                                  'https://www.openstreetmap.org/?mlat=${latestQuiz.latitude}&mlon=${latestQuiz.longitude}#map=15/${latestQuiz.latitude}/${latestQuiz.longitude}';
                                              launchUrl(Uri.parse(url));
                                            },
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.open_in_new,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Open in Maps',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    context,
                    'View Details',
                    Icons.person_outline_rounded,
                    () {
                      Get.to(
                        () => PatientDetailedView(
                          uid: patient.uid ?? '',
                        ),
                        arguments: patient,
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    'health_analytics'.tr,
                    Icons.analytics_outlined,
                    () {
                      Get.to(() => HealthAnalyticsPage(
                        patientId: patient.uid,
                        patientName: _getPatientName(patient),
                      ));
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Reports',
                    Icons.description_outlined,
                    () {
                      _showReportDialog(context, patient);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsBottomSheet(NotificationController notificationController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (notificationController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0850FD)),
                  );
                }

                if (notificationController.notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: notificationController.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationController.notifications[index];
                    final isRead = notification['read'] ?? false;
                    final title = notification['title'] ?? 'Notification';
                    final body = notification['body'] ?? '';
                    final createdAt = notification['createdAt'] ?? '';
                    final type = notification['type'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRead 
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFF0850FD).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRead 
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFF0850FD).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getNotificationTypeColor(type),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getNotificationTypeLabel(type),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0850FD),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            _formatNotificationTime(createdAt),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'quiz_completion':
        return Colors.green;
      case 'quiz_assignment':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'quiz_completion':
        return 'Quiz Complete';
      case 'quiz_assignment':
        return 'Quiz Assigned';
      default:
        return 'General';
    }
  }

  String _formatNotificationTime(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _showReportDialog(BuildContext context, dynamic patient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Generate Report',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select the type of report to generate for ${_getPatientName(patient)}',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              _buildReportOption(
                context,
                'Quiz Report',
                'Generate assessment and quiz history report',
                Icons.quiz_outlined,
                const Color(0xFF6C63FF),
                () async {
                  Get.back();
                  await _generateQuizReport(patient);
                },
              ),
              const SizedBox(height: 12),
              _buildReportOption(
                context,
                'EEG Report',
                'Generate brain signal analysis report',
                Icons.psychology_outlined,
                const Color(0xFF00C6FF),
                () async {
                  Get.back();
                  await _generateEEGReport(patient);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQuizReport(dynamic patient) async {
    try {
      // Show loading dialog
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: Color(0xFF0850FD)),
        ),
        barrierDismissible: false,
      );

      // Get quiz history
      final getProfileController = Get.find<GetProflieController>();
      await getProfileController.fetchQuizHistory();

      // Create profile object
      final userProfile = Profile(
        name: _getPatientName(patient),
        email: patient.email ?? 'Not provided',
        contact: patient.contact ?? 'Not provided',
        age: patient.age,
        gender: patient.gender ?? 'Not specified',
        address: patient.address ?? 'Not provided',
      );

      // Generate report
      await generateQuizReport(
        getProfileController.quizHistory,
        userProfile,
      );

      Get.back(); // Close loading dialog
      Get.snackbar(
        'Success',
        'Quiz report generated successfully!',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to generate quiz report: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _generateEEGReport(dynamic patient) async {
    try {
      // Show loading dialog
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: Color(0xFF0850FD)),
        ),
        barrierDismissible: false,
      );

      // Get brain scores
      final brainSignalController = Get.find<BrainSignalController>();
      await brainSignalController.loadBrainSignalScores();

      // Create profile object
      final userProfile = Profile(
        name: _getPatientName(patient),
        email: patient.email ?? 'Not provided',
        contact: patient.contact ?? 'Not provided',
        age: patient.age,
        gender: patient.gender ?? 'Not specified',
        address: patient.address ?? 'Not provided',
      );

      // Convert Map data to BrainScoreModel list
      final brainScores = brainSignalController.brainSignalScores.map((scoreMap) => 
        BrainScoreModel.fromJson(scoreMap)
      ).toList().obs;

      // Generate report
      await generatEEGReport(
        brainScores,
      );

      Get.back(); // Close loading dialog
      Get.snackbar(
        'Success',
        'EEG report generated successfully!',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to generate EEG report: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }
}

class PatientDetailedView extends StatefulWidget {
  const PatientDetailedView({super.key, required this.uid});
  final String uid;

  @override
  State<PatientDetailedView> createState() => _PatientDetailedViewState();
}

class _PatientDetailedViewState extends State<PatientDetailedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RelativeDetailedController relativeController =
    Get.put(RelativeDetailedController(data: widget.uid));
    final size = MediaQuery
        .of(context)
        .size;
    final isSmallScreen = size.width < 600;

    return Obx(
          () =>
          ModalProgressHUD(
            inAsyncCall: relativeController.isLoading.value,
            progressIndicator: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0850FD)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading Patient Data',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            child: Scaffold(
              appBar: AppBar(
                elevation: 0,
                backgroundColor: const Color(0xFF1A1A1A),
                leading: IconButton(
                  icon:
                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
                title: Text(
                  'Patient Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            AlertDialog(
                              backgroundColor: const Color(0xFF2A2A2A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                'Logout Confirmation',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to logout?',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                  },
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final box = GetStorage();
                                    box.remove('loginDetails');
                                    box.remove('timestamp');
                                    Get.offAll(() => LandingPage());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0850FD),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Logout',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1A1A1A),
              body: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SafeArea(
                    child: Scrollbar(
                      radius: const Radius.circular(5),
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPatientHeader(
                                context, relativeController, isSmallScreen),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Quiz Scores', isSmallScreen),
                            const SizedBox(height: 16),
                            _buildQuizChart(
                                context, relativeController, isSmallScreen),
                            const SizedBox(height: 24),
                            _buildSectionTitle('EEG Scores', isSmallScreen),
                            const SizedBox(height: 16),
                            _buildEegChart(
                                context, relativeController, isSmallScreen),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildPatientHeader(BuildContext context,
      RelativeDetailedController relativeController, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
        vertical: 16.0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0850FD).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              child: CircleAvatar(
                radius: 28,
                backgroundImage:
                const NetworkImage('https://i.pravatar.cc/150?img=3'),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient ${relativeController.profile.value.fullName}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Recent Quiz Score',
                  relativeController.chartData.isNotEmpty
                      ? relativeController.chartData.last.y.toString()
                      : 'No Quiz Given Yet!',
                  Icons.quiz_outlined,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Recent EEG Score',
                  relativeController.brainScore.isNotEmpty
                      ? relativeController.brainScore.last.y.toString()
                      : 'No EEG Tests Taken Yet!',
                  Icons.psychology_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0850FD).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0850FD),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$label: ',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
        vertical: 8.0,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0850FD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizChart(BuildContext context,
      RelativeDetailedController relativeController, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Score History',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                labelStyle: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.transparent,
              series: <CartesianSeries<dynamic, DateTime>>[
                LineSeries<dynamic, DateTime>(
                  dataSource: relativeController.chartData.isEmpty
                      ? null
                      : relativeController.chartData.toList(),
                  pointColorMapper: (dynamic data, _) =>
                  (data as dynamic).y! > 15 ? Colors.red : Colors.green,
                  name: 'Score',
                  onPointTap: (pointInteractionDetails) {
                    // Handle point tap if needed
                  },
                  xValueMapper: (dynamic data, _) => (data as dynamic).x,
                  yValueMapper: (dynamic data, _) => (data as dynamic).y,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    borderWidth: 2,
                    borderColor: Colors.white,
                  ),
                  dataLabelMapper: (dynamic data, _) =>
                  'Score: ${(data as dynamic).y}',
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEegChart(BuildContext context,
      RelativeDetailedController relativeController, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EEG Score History',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                labelStyle: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.transparent,
              series: <CartesianSeries<dynamic, DateTime>>[
                LineSeries<dynamic, DateTime>(
                  dataSource: relativeController.brainScore.isEmpty
                      ? null
                      : relativeController.brainScore.toList(),
                  pointColorMapper: (dynamic data, _) =>
                  (data as dynamic).y! >= 1 ? Colors.red : Colors.green,
                  name: 'Score',
                  onPointTap: (pointInteractionDetails) {
                    // Handle point tap if needed
                  },
                  xValueMapper: (dynamic data, _) => (data as dynamic).x,
                  yValueMapper: (dynamic data, _) => (data as dynamic).y,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    borderWidth: 2,
                    borderColor: Colors.white,
                  ),
                  dataLabelMapper: (dynamic data, _) =>
                  'Score: ${(data as dynamic).y}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPatientName(dynamic patient) {
    if (patient == null) return 'Unknown Patient';
    
    // Try different possible name fields from API response
    if (patient.firstName != null && patient.firstName.isNotEmpty) {
      String fullName = patient.firstName;
      if (patient.lastName != null && patient.lastName.isNotEmpty) {
        fullName += ' ' + patient.lastName;
      }
      return fullName;
    }
    
    if (patient.name != null && patient.name.isNotEmpty) {
      return patient.name;
    }
    
    // Try username as fallback
    if (patient.username != null && patient.username.isNotEmpty) {
      return patient.username;
    }
    
    // Try email prefix as last resort
    if (patient.email != null && patient.email.isNotEmpty) {
      return patient.email.split('@')[0];
    }
    
    return 'Unknown Patient';
  }
}