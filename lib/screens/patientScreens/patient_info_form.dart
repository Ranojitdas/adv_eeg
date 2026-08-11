import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ADDvEEG/controllers/auth/login_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ADDvEEG/screens/auth/emailLogin.dart';
import 'package:ADDvEEG/Constants/constants.dart';
import 'package:ADDvEEG/services/api_service.dart';


class PatientInfoForm extends StatefulWidget {
  const PatientInfoForm({Key? key}) : super(key: key);

  @override
  State<PatientInfoForm> createState() => _PatientInfoFormState();
}

class _PatientInfoFormState extends State<PatientInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();
  bool _isLoading = false;
  bool _hasExistingData = false;
  bool _isEditMode = false;
  
  // Track individual field edit states
  Map<String, bool> _fieldEditStates = {};


  // Controllers for all fields
  final TextEditingController ageController = TextEditingController();
  String sex = 'Male';
  final TextEditingController maritalStatusController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController habitatController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController ageOfOnsetController = TextEditingController();
  final TextEditingController pastMedicalController = TextEditingController();
  final TextEditingController pastPsychiatricController = TextEditingController();
  final TextEditingController familyMedicalController = TextEditingController();
  final TextEditingController familyPsychiatricController = TextEditingController();
  String handedness = 'Right';
  final TextEditingController pulseController = TextEditingController();
  final TextEditingController bpSystolicController = TextEditingController();
  final TextEditingController bpDiastolicController = TextEditingController();
  final TextEditingController handednessController = TextEditingController();
  final TextEditingController firstMDEController = TextEditingController();
  final TextEditingController cvsController = TextEditingController();
  final TextEditingController rsController = TextEditingController();
  final TextEditingController gitController = TextEditingController();
  final TextEditingController cnsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExistingData();
  }

  @override
  void dispose() {
    ageController.dispose();
    maritalStatusController.dispose();
    incomeController.dispose();
    religionController.dispose();
    educationController.dispose();
    occupationController.dispose();
    habitatController.dispose();
    locationController.dispose();
    durationController.dispose();
    ageOfOnsetController.dispose();
    pastMedicalController.dispose();
    pastPsychiatricController.dispose();
    familyMedicalController.dispose();
    familyPsychiatricController.dispose();
    pulseController.dispose();
    bpSystolicController.dispose();
    bpDiastolicController.dispose();
    handednessController.dispose();
    firstMDEController.dispose();
    cvsController.dispose();
    rsController.dispose();
    gitController.dispose();
    cnsController.dispose();
    super.dispose();
  }

  /// Fetch existing patient data from backend
  Future<void> _fetchExistingData() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await apiService.get(Constants.patientHistoryGet, requiresAuth: true);
      
      if (response.success && response.rawData != null) {
        final data = response.rawData?['data'];
        if (data != null) {
          final isNew = data['isNew'] ?? false;
          
          if (isNew) {
            // New account - enable edit mode for all fields
            setState(() {
              _hasExistingData = false;
              _isEditMode = true;
              // Initialize all fields as editable for new accounts
              _fieldEditStates.clear();
            });
          } else {
            // Existing account - extract the nested 'history' object from the response
            final historyData = data['history'];
            if (historyData != null) {
              _populateFields(historyData);
              setState(() {
                _hasExistingData = true;
                _isEditMode = true;
                // Initialize all fields as non-editable
                _fieldEditStates.clear();
              });
            }
          }
        }
      }
    } catch (e) {
      // Handle error silently or show user-friendly message
      // No existing data is fine, user can create new
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Populate form fields with existing data
  void _populateFields(Map<String, dynamic> data) {
    ageController.text = data['age']?.toString() ?? '';
    
    // Map backend sex values to dropdown values
    String backendSex = data['sex'] ?? 'M';
    switch (backendSex.toUpperCase()) {
      case 'M':
        sex = 'Male';
        break;
      case 'F':
        sex = 'Female';
        break;
      default:
        sex = 'Other';
    }
    
    maritalStatusController.text = data['maritalStatus'] ?? '';
    incomeController.text = data['income']?.toString() ?? '';
    religionController.text = data['religion'] ?? '';
    educationController.text = data['education'] ?? '';
    occupationController.text = data['occupation'] ?? '';
    habitatController.text = data['habitat'] ?? '';
    locationController.text = data['location'] ?? '';
    durationController.text = data['durationOfIllness'] ?? '';
    ageOfOnsetController.text = data['ageOfOnset']?.toString() ?? '';
    firstMDEController.text = data['firstMDEAge']?.toString() ?? '';
    pastMedicalController.text = data['pastMedicalIllness']?.toString() ?? '';
    pastPsychiatricController.text = data['pastPsychiatricIllness']?.toString() ?? '';
    familyMedicalController.text = data['familyMedicalIllness']?.toString() ?? '';
    familyPsychiatricController.text = data['familyPsychiatricIllness']?.toString() ?? '';
    handedness = data['handedness'] ?? 'Right';
    pulseController.text = data['pulse']?.toString() ?? '';
    bpSystolicController.text = data['bloodPressureSystolic']?.toString() ?? '';
    bpDiastolicController.text = data['bloodPressureDiastolic']?.toString() ?? '';
    cvsController.text = data['cvs'] ?? '';
    rsController.text = data['rs'] ?? '';
    gitController.text = data['git'] ?? '';
    cnsController.text = data['cns'] ?? '';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // Use patient history endpoint from new backend API with correct payload structure
      final response = await apiService.post(
        Constants.patientHistoryCreate,
        body: {
          "age": int.tryParse(ageController.text) ?? 0,
          "sex": sex,
          "maritalStatus": maritalStatusController.text,
          "income": int.tryParse(incomeController.text) ?? 0,
          "religion": religionController.text,
          "education": educationController.text,
          "occupation": occupationController.text,
          "habitat": habitatController.text,
          "location": locationController.text,
          "durationOfIllness": durationController.text,
          "ageOfOnset": int.tryParse(ageOfOnsetController.text) ?? 0,
          "firstMDEAge": int.tryParse(firstMDEController.text) ?? 0,
          "pastMedicalIllness": pastMedicalController.text.toLowerCase() == 'true',
          "pastPsychiatricIllness": pastPsychiatricController.text.toLowerCase() == 'true',
          "familyMedicalIllness": familyMedicalController.text.toLowerCase() == 'true',
          "familyPsychiatricIllness": familyPsychiatricController.text.toLowerCase() == 'true',
          "handedness": handednessController.text,
          "pulse": int.tryParse(pulseController.text) ?? 0,
          "bloodPressureSystolic": int.tryParse(bpSystolicController.text) ?? 0,
          "bloodPressureDiastolic": int.tryParse(bpDiastolicController.text) ?? 0,
          "cvs": cvsController.text,
          "rs": rsController.text,
          "git": gitController.text,
          "cns": cnsController.text,
        },
        requiresAuth: true,
      );
      
      if (response.success) {
        Get.snackbar('Success', 
            _isEditMode ? 'Information updated successfully!' : 'Information saved successfully!',
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            colorText: Colors.green);
        
        if (_isEditMode) {
          // If editing existing data, just go back
          Get.back();
        } else {
          // If new data, return to login screen
          Get.offAll(() => UsernameLogin());
          Get.snackbar('Login Required', 'Please log in with your new credentials.',
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              colorText: Colors.orange);
        }
      } else {
        throw Exception(response.message ?? 'Failed to save information');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save information',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Skip logic: return to patient dashboard
              print('📋 [PATIENT_INFO] Skip button pressed - returning to dashboard');
              Get.back();
            },
            child:
                Text('Skip', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isEditMode ? 'Edit Patient Information' : 'Patient Information',
                              style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          if (_hasExistingData) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Edit Mode',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField('Age', ageController,
                          keyboardType: TextInputType.number),
                      _buildDropdown('Sex', sex, ['Male', 'Female', 'Other'],
                          (val) => setState(() => sex = val!)),
                      _buildTextField(
                          'Marital Status', maritalStatusController),
                      _buildTextField('Income', incomeController,
                          keyboardType: TextInputType.number),
                      _buildTextField('Religion', religionController),
                      _buildTextField('Education', educationController),
                      _buildTextField('Occupation', occupationController),
                      _buildTextField('Habitat', habitatController),
                      _buildTextField('Location', locationController),
                      _buildTextField(
                          'Duration of illness', durationController),
                      _buildTextField('Age of onset', ageOfOnsetController),
                      const SizedBox(height: 16),
                      Text('Past History',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      _buildTextField(
                          'Medical illness', pastMedicalController),
                      _buildTextField('Psychiatric illness',
                          pastPsychiatricController),
                      const SizedBox(height: 16),
                      Text('Family History',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      _buildTextField(
                          'Medical illness', familyMedicalController),
                      _buildTextField('Psychiatric illness',
                          familyPsychiatricController),
                      const SizedBox(height: 16),
                      Text('Medical Examination',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      _buildDropdown(
                          'Handedness',
                          handedness,
                          ['Right', 'Left'],
                          (val) => setState(() => handedness = val!)),
                      _buildTextField('Pulse', pulseController),
                      _buildTextField(
                          'Blood pressure systolic', bpSystolicController),
                      _buildTextField(
                          'Blood pressure diastolic', bpDiastolicController),
                      _buildTextField('CVS', cvsController),
                      _buildTextField('RS', rsController),
                      _buildTextField('GIT', gitController),
                      _buildTextField('CNS', cnsController),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_isEditMode ? 'Update' : 'Save',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFieldEditable(String fieldKey) {
    setState(() {
      _fieldEditStates[fieldKey] = !(_fieldEditStates[fieldKey] ?? false);
    });
  }
  
  bool _isFieldEditable(String fieldKey) {
    return _fieldEditStates[fieldKey] ?? false;
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    bool hasData = controller.text.isNotEmpty;
    String fieldKey = label.toLowerCase().replaceAll(' ', '_');
    bool isFieldEditable = _isFieldEditable(fieldKey);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              if (hasData && _hasExistingData) ...[const SizedBox(width: 8), 
                GestureDetector(
                  onTap: () => _toggleFieldEditable(fieldKey),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    tween: Tween(begin: 0.0, end: isFieldEditable ? 1.0 : 0.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + (value * 0.1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              Colors.transparent,
                              Colors.blue.withValues(alpha: 0.15),
                              value,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color.lerp(
                                Colors.transparent,
                                Colors.blue.withValues(alpha: 0.3),
                                value,
                              )!,
                              width: (value * 1.5).clamp(0.0, 2.0),
                            ),
                          ),
                          child: Icon(
                            isFieldEditable ? Icons.lock_open_rounded : Icons.edit_rounded,
                            size: 16,
                            color: Color.lerp(
                              Colors.blue.withValues(alpha: 0.7),
                              Colors.blue,
                              value,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: isFieldEditable ? 1.0 : 0.0),
            builder: (context, value, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                transform: Matrix4.identity()..scale(1.0 + (value * 0.02)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: value > 0 ? LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.05 * value),
                      Colors.blue.withValues(alpha: 0.02 * value),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                  boxShadow: value > 0 ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.15 * value),
                      blurRadius: 12 * value,
                      spreadRadius: 2 * value,
                      offset: Offset(0, 4 * value),
                    ),
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.08 * value),
                      blurRadius: 20 * value,
                      spreadRadius: -2 * value,
                      offset: Offset(0, 8 * value),
                    ),
                  ] : null,
                ),
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: _hasExistingData && !isFieldEditable,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color.lerp(
                          Colors.grey[300]!,
                          Colors.blue.withValues(alpha: 0.4),
                          value,
                        )!,
                        width: 1 + (value * 1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color.lerp(
                          Colors.grey[300]!,
                          Colors.blue.withValues(alpha: 0.4),
                          value,
                        )!,
                        width: 1 + (value * 0.5),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: hasData && _hasExistingData
                        ? TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween(begin: 0.0, end: isFieldEditable ? 1.0 : 0.0),
                            builder: (context, iconValue, child) {
                              return Transform.rotate(
                                angle: iconValue * 0.5,
                                child: Icon(
                                  isFieldEditable ? Icons.edit_outlined : Icons.check_circle_rounded,
                                  color: Color.lerp(
                                    Colors.green.withValues(alpha: 0.7),
                                    Colors.blue.withValues(alpha: 0.8),
                                    iconValue,
                                  ),
                                  size: 20,
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter $label';
                    }
                    return null;
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String dropdownValue, List<String> items,
      ValueChanged<String?> onChanged) {
    bool hasData = dropdownValue.isNotEmpty;
    String fieldKey = label.toLowerCase().replaceAll(' ', '_');
    bool isFieldEditable = _isFieldEditable(fieldKey);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              if (hasData && _hasExistingData) ...[const SizedBox(width: 8), 
                GestureDetector(
                  onTap: () => _toggleFieldEditable(fieldKey),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    tween: Tween(begin: 0.0, end: isFieldEditable ? 1.0 : 0.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + (value * 0.1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              Colors.transparent,
                              Colors.blue.withValues(alpha: 0.15),
                              value,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color.lerp(
                                Colors.transparent,
                                Colors.blue.withValues(alpha: 0.3),
                                value,
                              )!,
                              width: (value * 1.5).clamp(0.0, 2.0),
                            ),
                          ),
                          child: Icon(
                            isFieldEditable ? Icons.lock_open_rounded : Icons.edit_rounded,
                            size: 16,
                            color: Color.lerp(
                              Colors.blue.withValues(alpha: 0.7),
                              Colors.blue,
                              value,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: isFieldEditable ? 1.0 : 0.0),
            builder: (context, value, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                transform: Matrix4.identity()..scale(1.0 + (value * 0.02)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: value > 0 ? LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.05 * value),
                      Colors.blue.withValues(alpha: 0.02 * value),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                  boxShadow: value > 0 ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.15 * value),
                      blurRadius: 12 * value,
                      spreadRadius: 2 * value,
                      offset: Offset(0, 4 * value),
                    ),
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.08 * value),
                      blurRadius: 20 * value,
                      spreadRadius: -2 * value,
                      offset: Offset(0, 8 * value),
                    ),
                  ] : null,
                ),
                child: DropdownButtonFormField<String>(
                  value: dropdownValue,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color.lerp(
                          Colors.grey[300]!,
                          Colors.blue.withValues(alpha: 0.4),
                          value,
                        )!,
                        width: 1 + (value * 1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color.lerp(
                          Colors.grey[300]!,
                          Colors.blue.withValues(alpha: 0.4),
                          value,
                        )!,
                        width: 1 + (value * 0.5),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: hasData && _hasExistingData
                        ? TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween(begin: 0.0, end: isFieldEditable ? 1.0 : 0.0),
                            builder: (context, iconValue, child) {
                              return Transform.rotate(
                                angle: iconValue * 0.5,
                                child: Icon(
                                  isFieldEditable ? Icons.edit_outlined : Icons.check_circle_rounded,
                                  color: Color.lerp(
                                    Colors.green.withValues(alpha: 0.7),
                                    Colors.blue.withValues(alpha: 0.8),
                                    iconValue,
                                  ),
                                  size: 20,
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                  onChanged: (!_hasExistingData || isFieldEditable) ? onChanged : null,
                  items: items.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
