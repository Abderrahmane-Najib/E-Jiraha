import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/hospital_case.dart';
import '../../../models/patient.dart';
import '../../../services/hospital_case_repository.dart';
import '../../../services/patient_repository.dart';
import '../providers/nurse_provider.dart';

class TriageScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String patientId;

  const TriageScreen({
    super.key,
    required this.caseId,
    required this.patientId,
  });

  @override
  ConsumerState<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends ConsumerState<TriageScreen> {
  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();

  final TextEditingController _tensionController = TextEditingController();
  final TextEditingController _poulsController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _poidsController = TextEditingController();

  bool _isLoading = false;
  bool _isDataLoading = true;
  Patient? _patient;
  HospitalCase? _hospitalCase;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final patient = await _patientRepository.getPatientById(widget.patientId);
      final hospitalCase = await _caseRepository.getCaseById(widget.caseId);

      if (mounted) {
        setState(() {
          _patient = patient;
          _hospitalCase = hospitalCase;
          _isDataLoading = false;

          // Pre-fill existing vital signs if any
          if (hospitalCase?.vitalSigns != null) {
            _tensionController.text = hospitalCase!.vitalSigns!['tension'] ?? '';
            _poulsController.text = hospitalCase.vitalSigns!['pouls']?.toString() ?? '';
            _tempController.text = hospitalCase.vitalSigns!['temp']?.toString() ?? '';
            _spo2Controller.text = hospitalCase.vitalSigns!['spo2']?.toString() ?? '';
            _poidsController.text = hospitalCase.vitalSigns!['poids']?.toString() ?? '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDataLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tensionController.dispose();
    _poulsController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    _poidsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final patientName = _patient?.fullName ?? 'Patient inconnu';
    final initials = _getInitials(patientName);
    final isUrgent = _hospitalCase?.entryMode == EntryMode.emergency;

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
                  // Patient Banner
                  _buildPatientBanner(
                    name: patientName,
                    initials: initials,
                    dossierNumber: _hospitalCase?.id.substring(0, 8).toUpperCase() ?? '',
                    service: _hospitalCase?.service ?? '',
                    isUrgent: isUrgent,
                  ),
                  const SizedBox(height: 24),

                  // Section Title
                  Text(
                    'Signes Vitaux',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Form Card
                  _buildFormCard(),
                  const SizedBox(height: 20),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return '??';
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
                  child: Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Triage Infirmier',
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

  Widget _buildPatientBanner({
    required String name,
    required String initials,
    required String dossierNumber,
    required String service,
    required bool isUrgent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#$dossierNumber • $service',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (isUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'URGENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Tension & Pouls
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'TENSION (MMHG)',
                  controller: _tensionController,
                  hint: '12/8',
                  keyboardType: TextInputType.text,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: 'POULS (BPM)',
                  controller: _poulsController,
                  hint: '75',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Temp & SpO2
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'TEMP. (°C)',
                  controller: _tempController,
                  hint: '37.2',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: 'SPO2 (%)',
                  controller: _spo2Controller,
                  hint: '98',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Poids
          _buildInputField(
            label: 'POIDS (KG)',
            controller: _poidsController,
            hint: '68',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
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
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submitTriage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Valider le Triage',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _submitTriage() async {
    setState(() => _isLoading = true);

    try {
      // Prepare vital signs data
      final vitalSigns = {
        'tension': _tensionController.text.trim(),
        'pouls': int.tryParse(_poulsController.text.trim()),
        'temp': double.tryParse(_tempController.text.trim()),
        'spo2': int.tryParse(_spo2Controller.text.trim()),
        'poids': double.tryParse(_poidsController.text.trim()),
        'recordedAt': DateTime.now().toIso8601String(),
      };

      // Save to Firebase
      await _caseRepository.updateVitalSigns(widget.caseId, vitalSigns);

      // Update case status to preop if it was in admission or consultation
      if (_hospitalCase?.status == CaseStatus.admission ||
          _hospitalCase?.status == CaseStatus.consultation) {
        await _caseRepository.updateCaseStatus(widget.caseId, CaseStatus.preop);
      }

      // Refresh the triage queue and planning
      ref.read(triageQueueProvider.notifier).loadTriageQueue();
      ref.read(planningProvider.notifier).loadPlanning();
      ref.invalidate(nurseDashboardStatsProvider);

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Constantes enregistrées pour ${_patient?.fullName ?? "le patient"}'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );

        context.go('/nurse');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
