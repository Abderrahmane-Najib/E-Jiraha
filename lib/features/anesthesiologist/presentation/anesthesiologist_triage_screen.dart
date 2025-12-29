import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/anesthesia.dart';
import '../../../models/checklist.dart';
import '../../../models/hospital_case.dart';
import '../../../models/patient.dart';
import '../../../services/hospital_case_repository.dart';
import '../../../services/patient_repository.dart';
import '../../../services/anesthesia_repository.dart';
import '../../../services/checklist_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/anesthesiologist_provider.dart';

class AnesthesiologistTriageScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String patientId;

  const AnesthesiologistTriageScreen({
    super.key,
    required this.caseId,
    required this.patientId,
  });

  @override
  ConsumerState<AnesthesiologistTriageScreen> createState() =>
      _AnesthesiologistTriageScreenState();
}

class _AnesthesiologistTriageScreenState
    extends ConsumerState<AnesthesiologistTriageScreen> {
  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();
  final AnesthesiaRepository _anesthesiaRepository = AnesthesiaRepository();
  final ChecklistRepository _checklistRepository = ChecklistRepository();

  int _selectedAsa = 2;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isDataLoading = true;

  Patient? _patient;
  HospitalCase? _hospitalCase;
  AnesthesiaEvaluation? _existingEvaluation;
  Checklist? _nurseChecklist;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final patient = await _patientRepository.getPatientById(widget.patientId);
      final hospitalCase = await _caseRepository.getCaseById(widget.caseId);
      final existingEval = await _anesthesiaRepository.getEvaluationByCaseId(widget.caseId);
      final nurseChecklist = await _checklistRepository.getChecklistByCaseAndType(
        widget.caseId,
        ChecklistType.preop,
      );

      if (mounted) {
        setState(() {
          _patient = patient;
          _hospitalCase = hospitalCase;
          _existingEvaluation = existingEval;
          _nurseChecklist = nurseChecklist;
          _isDataLoading = false;

          // Pre-fill existing evaluation if any
          if (existingEval != null) {
            _selectedAsa = existingEval.asaScore.riskLevel;
            _notesController.text = existingEval.notes ?? '';
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
    _notesController.dispose();
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
    final vitalSigns = _hospitalCase?.vitalSigns;

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

                  // Vital Signs Section (Read-only)
                  _buildSectionTitle('Signes Vitaux', isReadOnly: true),
                  const SizedBox(height: 12),
                  _buildVitalSignsCard(vitalSigns),
                  const SizedBox(height: 24),

                  // Nurse Checklist Progress Section (Read-only)
                  _buildSectionTitle('Checklist Infirmier', isReadOnly: true),
                  const SizedBox(height: 12),
                  _buildNurseChecklistCard(),
                  const SizedBox(height: 24),

                  // ASA Score Section (Editable)
                  _buildSectionTitle('Score ASA', isReadOnly: false),
                  const SizedBox(height: 12),
                  _buildAsaSelector(),
                  const SizedBox(height: 24),

                  // Notes Section
                  _buildSectionTitle('Notes cliniques', isReadOnly: false),
                  const SizedBox(height: 12),
                  _buildNotesField(),
                  const SizedBox(height: 24),

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
                'Évaluation Anesthésique',
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

  Widget _buildSectionTitle(String title, {required bool isReadOnly}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isReadOnly ? AppColors.textSecondary : AppColors.primary,
          ),
        ),
        if (isReadOnly) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Lecture seule',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVitalSignsCard(Map<String, dynamic>? vitalSigns) {
    final tension = vitalSigns?['tension']?.toString() ?? '—';
    final pouls = vitalSigns?['pouls']?.toString() ?? '—';
    final temp = vitalSigns?['temp']?.toString() ?? '—';
    final spo2 = vitalSigns?['spo2']?.toString() ?? '—';
    final poids = vitalSigns?['poids']?.toString() ?? '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Opacity(
        opacity: 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Tension & Pouls
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'TENSION (MMHG)',
                    value: tension,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'POULS (BPM)',
                    value: pouls,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Temp & SpO2
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'TEMP. (°C)',
                    value: temp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'SPO2 (%)',
                    value: spo2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 3: Poids
            _buildReadOnlyField(
              label: 'POIDS (KG)',
              value: poids,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNurseChecklistCard() {
    if (_nurseChecklist == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.pending_actions, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 12),
            Text(
              'Checklist non encore créée',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final items = _nurseChecklist!.items;
    final completedCount = items.where((item) => item.isCompleted).length;
    final totalCount = items.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final isCompleted = _nurseChecklist!.isCompleted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted ? AppColors.success : AppColors.border,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Opacity(
        opacity: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress header
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.pending,
                  color: isCompleted ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'Checklist complète' : 'Checklist en cours',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? AppColors.success : AppColors.warning,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedCount / $totalCount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                color: isCompleted ? AppColors.success : AppColors.primary,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),

            // Checklist items
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    item.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                    color: item.isCompleted ? AppColors.success : AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAsaSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Définir le Score ASA :',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final score = index + 1;
              final isSelected = _selectedAsa == score;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAsa = score;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _getAsaDescription(_selectedAsa),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getAsaDescription(int asa) {
    switch (asa) {
      case 1:
        return 'Patient en bonne santé';
      case 2:
        return 'Maladie systémique légère';
      case 3:
        return 'Maladie systémique grave';
      case 4:
        return 'Maladie systémique grave, menace vitale';
      case 5:
        return 'Patient moribond';
      default:
        return '';
    }
  }

  AsaScore _getAsaScore(int score) {
    switch (score) {
      case 1:
        return AsaScore.asa1;
      case 2:
        return AsaScore.asa2;
      case 3:
        return AsaScore.asa3;
      case 4:
        return AsaScore.asa4;
      case 5:
        return AsaScore.asa5;
      default:
        return AsaScore.asa2;
    }
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Antécédents et comorbidités...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submitEvaluation,
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
                  'ENREGISTRER L\'ÉVALUATION',
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

  Future<void> _submitEvaluation() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);

      // Safely convert weight to double
      final weightValue = _hospitalCase?.vitalSigns?['poids'];
      final weight = weightValue != null ? (weightValue as num).toDouble() : null;

      if (_existingEvaluation != null) {
        // Update existing evaluation
        final updated = _existingEvaluation!.copyWith(
          asaScore: _getAsaScore(_selectedAsa),
          notes: _notesController.text.trim(),
          weight: weight,
          updatedAt: DateTime.now(),
        );
        await _anesthesiaRepository.updateEvaluation(updated);
      } else {
        // Create new evaluation
        final evaluation = AnesthesiaEvaluation(
          id: '',
          caseId: widget.caseId,
          patientId: widget.patientId,
          anesthesiologistId: user?.id ?? '',
          asaScore: _getAsaScore(_selectedAsa),
          weight: weight,
          notes: _notesController.text.trim(),
          evaluationDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _anesthesiaRepository.createEvaluation(evaluation);
      }

      // Refresh the triage queue and dashboard stats
      ref.read(anesthesiaTriageProvider.notifier).loadTriageQueue();
      ref.invalidate(anesthesiaDashboardStatsProvider);

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Évaluation enregistrée (ASA $_selectedAsa)'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );

        context.go('/anesthesiologist');
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
