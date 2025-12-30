import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/patient.dart';
import '../../../services/image_upload_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/patient_provider.dart';

class NewPatientScreen extends ConsumerStatefulWidget {
  const NewPatientScreen({super.key});

  @override
  ConsumerState<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends ConsumerState<NewPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _cinController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedGender = 'Féminin';
  DateTime? _dateOfBirth;
  bool _isLoading = false;

  // CIN Images
  final ImageUploadService _imageService = ImageUploadService();
  String? _cinFrontPath;
  String? _cinBackPath;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _cinController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Bar
          _buildTopBar(),

          // Content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Identité & État Civil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Création de l\'identité permanente au CHU',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Card
                    _buildFormCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Fiche Patient (Civil)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CIN Scanner
          _buildLabel('DOCUMENTS D\'IDENTITÉ (CIN)'),
          const SizedBox(height: 8),
          Row(
            children: [
              // CIN Front
              Expanded(
                child: _buildCINImagePicker(
                  label: 'Recto',
                  imagePath: _cinFrontPath,
                  isUploading: _isUploadingFront,
                  onTap: () => _showImagePickerDialog(isFront: true),
                  onRemove: () => setState(() => _cinFrontPath = null),
                ),
              ),
              const SizedBox(width: 12),
              // CIN Back
              Expanded(
                child: _buildCINImagePicker(
                  label: 'Verso',
                  imagePath: _cinBackPath,
                  isUploading: _isUploadingBack,
                  onTap: () => _showImagePickerDialog(isFront: false),
                  onRemove: () => setState(() => _cinBackPath = null),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Full Name
          _buildLabel('NOM & PRÉNOM'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _fullNameController,
            hint: 'Ex: Amina Mansouri',
            validator: (value) {
              if (value == null || value.isEmpty) return 'Champ requis';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // CIN and Gender Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('N° CIN'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _cinController,
                      hint: 'AB123456',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requis';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('SEXE'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          items: ['Féminin', 'Masculin'].map((gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedGender = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Date of Birth
          _buildLabel('DATE DE NAISSANCE'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateOfBirth != null
                          ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                          : 'dd/mm/yyyy',
                      style: TextStyle(
                        fontSize: 14,
                        color: _dateOfBirth != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Address
          _buildLabel('ADRESSE DE RÉSIDENCE'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _addressController,
            hint: 'N°, Rue, Quartier, Ville...',
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Champ requis';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Phone
          _buildLabel('TÉLÉPHONE MOBILE'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: '06XXXXXXXX',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Champ requis';
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Submit Button
          GestureDetector(
            onTap: _isLoading ? null : _submitForm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Enregistrer le Profil Patient',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _dateOfBirth = date);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner la date de naissance'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Get current user
    final currentUser = ref.read(currentUserProvider);
    final now = DateTime.now();

    // Create patient object
    final patient = Patient(
      id: '', // Will be set by Firestore
      fullName: _fullNameController.text.trim(),
      cin: _cinController.text.trim().toUpperCase(),
      gender: _selectedGender == 'Masculin' ? Gender.male : Gender.female,
      dateOfBirth: _dateOfBirth!,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      cinImageFront: _cinFrontPath,
      cinImageBack: _cinBackPath,
      createdAt: now,
      updatedAt: now,
      createdBy: currentUser?.id ?? 'unknown',
    );

    // Save to Firebase
    final patientId = await ref.read(patientProvider.notifier).createPatient(patient);

    if (mounted) {
      setState(() => _isLoading = false);

      if (patientId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Patient enregistré avec succès'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );

        context.go('/secretary');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildCINImagePicker({
    required String label,
    required String? imagePath,
    required bool isUploading,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imagePath != null ? AppColors.success : AppColors.primarySurface,
            width: 2,
          ),
        ),
        child: isUploading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chargement...',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : imagePath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 24,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'CIN $label',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Appuyer pour scanner',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  void _showImagePickerDialog({required bool isFront}) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Scanner CIN ${isFront ? "Recto" : "Verso"}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.camera_alt,
                      label: 'Caméra',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(isFront: isFront, fromCamera: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.photo_library,
                      label: 'Galerie',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(isFront: isFront, fromCamera: false);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primarySurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage({required bool isFront, required bool fromCamera}) async {
    setState(() {
      if (isFront) {
        _isUploadingFront = true;
      } else {
        _isUploadingBack = true;
      }
    });

    try {
      final image = fromCamera
          ? await _imageService.pickFromCamera()
          : await _imageService.pickFromGallery();

      if (image != null) {
        setState(() {
          if (isFront) {
            _cinFrontPath = image.path;
          } else {
            _cinBackPath = image.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la capture: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isFront) {
            _isUploadingFront = false;
          } else {
            _isUploadingBack = false;
          }
        });
      }
    }
  }
}
