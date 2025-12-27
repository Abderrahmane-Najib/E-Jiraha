import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AdmissionOuvertureScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;
  final String patientInitials;
  final String patientCin;
  final int patientAge;

  const AdmissionOuvertureScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientInitials,
    required this.patientCin,
    required this.patientAge,
  });

  @override
  ConsumerState<AdmissionOuvertureScreen> createState() =>
      _AdmissionOuvertureScreenState();
}

class _AdmissionOuvertureScreenState
    extends ConsumerState<AdmissionOuvertureScreen> {
  String _selectedPriority = 'P';
  String _selectedService = 'Chirurgie Viscérale A';
  final TextEditingController _allergiesController =
      TextEditingController(text: 'Néant');
  final TextEditingController _motifController = TextEditingController();

  bool _consentementSigne = false;
  bool _dossierMedical = false;
  bool _priseEnCharge = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _allergiesController.dispose();
    _motifController.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Patient Box
                  _buildSelectedPatientBox(),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Détails de l\'Admission',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assignation au service et motif clinique',
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
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
                  child: Icon(Icons.arrow_back,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ouverture du Dossier',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPatientBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.patientInitials,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CIN: ${widget.patientCin} • ${widget.patientAge} ans',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryDark.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Modify button
          GestureDetector(
            onTap: () => context.pop(),
            child: Text(
              'MODIFIER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
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
          // Priority Select
          _buildLabel('MODE D\'ENTRÉE & PRIORITÉ'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedPriority == 'U'
                    ? AppColors.error
                    : AppColors.border,
                width: _selectedPriority == 'U' ? 2 : 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPriority,
                isExpanded: true,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _selectedPriority == 'U'
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'U',
                    child: Text('🔴 URGENCE (Triage immédiat)'),
                  ),
                  DropdownMenuItem(
                    value: 'P',
                    child: Text('🟢 PROGRAMMÉE (Planifiée)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedPriority = value);
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Service Select
          _buildLabel('SERVICE DE DESTINATION'),
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
                value: _selectedService,
                isExpanded: true,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                items: [
                  'Chirurgie Viscérale A',
                  'Chirurgie Viscérale B',
                  'Traumatologie-Orthopédie',
                  'Unité des Brûlés',
                ].map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedService = value);
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Allergies
          _buildLabel('ALLERGIES SIGNALÉES (CRUCIAL)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _allergiesController,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Indiquer \'NÉANT\' ou précisez',
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
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          // Red left border overlay
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          const SizedBox(height: 18),

          // Motif
          _buildLabel('MOTIF DE L\'HOSPITALISATION'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _motifController,
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: Appendicectomie à réaliser...',
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
            ),
          ),

          const SizedBox(height: 18),

          // Documents Checklist
          _buildLabel('DOCUMENTS OBLIGATOIRES (ADMISSION)'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildDocItem(
                  '📄 Consentement éclairé signé',
                  _consentementSigne,
                  (value) => setState(() => _consentementSigne = value ?? false),
                ),
                const SizedBox(height: 8),
                _buildDocItem(
                  '📂 Dossier médical externe',
                  _dossierMedical,
                  (value) => setState(() => _dossierMedical = value ?? false),
                ),
                const SizedBox(height: 8),
                _buildDocItem(
                  '💳 Prise en charge Assurance',
                  _priseEnCharge,
                  (value) => setState(() => _priseEnCharge = value ?? false),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Scanner - Fonctionnalité à venir'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(
                    '+ SCANNER UN DOCUMENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Submit Button
          GestureDetector(
            onTap: _isLoading ? null : _submitForm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
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
                        'Valider & Ouvrir le Dossier',
                        style: TextStyle(
                          fontSize: 15,
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

  Widget _buildDocItem(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Dossier ouvert pour ${widget.patientName}'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );

      context.go('/secretary');
    }
  }
}
