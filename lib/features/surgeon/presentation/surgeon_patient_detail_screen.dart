import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/hospital_case.dart';
import '../../../models/checklist.dart';
import '../../../models/anesthesia.dart';
import '../../../models/user.dart';
import '../../../models/surgery.dart'; // Needed for SurgeryStatus enum
import '../../../services/checklist_repository.dart';
import '../../../services/anesthesia_repository.dart';
import '../../../services/user_repository.dart';
import '../providers/surgeon_provider.dart';

/// Provider for patient detail with progress info
final patientDetailWithProgressProvider = FutureProvider.family<PatientDetailData?, String>((ref, caseId) async {
  final checklistRepository = ChecklistRepository();
  final anesthesiaRepository = AnesthesiaRepository();
  final userRepository = UserRepository();

  final patientData = await ref.watch(patientDetailsProvider(caseId).future);
  if (patientData == null) return null;

  // Get checklist for this case
  final checklists = await checklistRepository.getChecklistsByCaseId(caseId);
  final checklist = checklists.isNotEmpty ? checklists.first : null;

  // Get anesthesia evaluation for this case
  final evaluations = await anesthesiaRepository.getEvaluationsByCaseId(caseId);
  final evaluation = evaluations.isNotEmpty ? evaluations.first : null;

  // Get assigned staff names
  User? assignedNurse;
  User? assignedAnesthesiologist;

  if (patientData.surgery?.nurseIds.isNotEmpty == true) {
    assignedNurse = await userRepository.getUserById(patientData.surgery!.nurseIds.first);
  }

  if (patientData.surgery?.anesthesiologistId != null) {
    assignedAnesthesiologist = await userRepository.getUserById(patientData.surgery!.anesthesiologistId!);
  }

  return PatientDetailData(
    patientData: patientData,
    checklist: checklist,
    evaluation: evaluation,
    assignedNurse: assignedNurse,
    assignedAnesthesiologist: assignedAnesthesiologist,
  );
});

class PatientDetailData {
  final SurgeryRequestData patientData;
  final Checklist? checklist;
  final AnesthesiaEvaluation? evaluation;
  final User? assignedNurse;
  final User? assignedAnesthesiologist;

  const PatientDetailData({
    required this.patientData,
    this.checklist,
    this.evaluation,
    this.assignedNurse,
    this.assignedAnesthesiologist,
  });
}

class SurgeonPatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId; // This is actually caseId

  const SurgeonPatientDetailScreen({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<SurgeonPatientDetailScreen> createState() =>
      _SurgeonPatientDetailScreenState();
}

class _SurgeonPatientDetailScreenState
    extends ConsumerState<SurgeonPatientDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(patientDetailWithProgressProvider(widget.patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Patient non trouvé'));
          }
          return _buildContent(data);
        },
      ),
    );
  }

  Widget _buildContent(PatientDetailData data) {
    final patient = data.patientData.patient;
    final hospitalCase = data.patientData.hospitalCase;
    final surgery = data.patientData.surgery;
    final checklist = data.checklist;
    final evaluation = data.evaluation;

    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(patientDetailWithProgressProvider(widget.patientId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientHeader(patient, hospitalCase),
                  const SizedBox(height: 12),
                  _buildProgressCard(data),
                  const SizedBox(height: 12),
                  _buildClinicalSummary(hospitalCase),
                  const SizedBox(height: 12),
                  _buildStaffCard(data),
                  const SizedBox(height: 12),
                  _buildDemandeCard(hospitalCase, surgery),
                ],
              ),
            ),
          ),
        ),
        _buildBottomNav(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.88),
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'e-jiraha',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chirurgien • Détail Patient',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.chevron_left, size: 18, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader(patient, HospitalCase hospitalCase) {
    final patientName = patient?.fullName ?? 'Patient inconnu';
    final initials = _getInitials(patientName);
    final isUrgent = hospitalCase.entryMode == EntryMode.emergency;

    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: 'Dossier #${hospitalCase.id.substring(0, 8).toUpperCase()}'),
                    _StatusChip(
                      label: hospitalCase.status.label,
                      type: _getStatusChipType(hospitalCase.status),
                    ),
                    if (isUrgent)
                      const _StatusChip(label: 'Urgence', type: ChipType.risk),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(PatientDetailData data) {
    final checklist = data.checklist;
    final evaluation = data.evaluation;

    final checklistProgress = checklist != null
        ? checklist.items.where((i) => i.isCompleted).length
        : 0;
    final checklistTotal = checklist?.items.length ?? 0;
    final checklistComplete = checklist?.isCompleted ?? false;

    final hasEvaluation = evaluation != null;
    final asaScore = evaluation?.asaScore;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression Pré-opératoire',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'État d\'avancement des évaluations par l\'équipe',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Nurse Checklist Progress
          _ProgressRow(
            icon: Icons.medical_services_outlined,
            color: AppColors.nurseColor,
            title: 'Checklist Infirmier',
            subtitle: checklist != null
                ? 'Complétée par ${data.assignedNurse?.fullName ?? "Infirmier"}'
                : 'Non démarrée',
            progress: checklistTotal > 0 ? checklistProgress / checklistTotal : 0,
            progressText: '$checklistProgress/$checklistTotal',
            isComplete: checklistComplete,
          ),
          const SizedBox(height: 12),

          // Anesthesiologist Evaluation Progress
          _ProgressRow(
            icon: Icons.monitor_heart_outlined,
            color: AppColors.anesthesiologistColor,
            title: 'Évaluation Anesthésiste',
            subtitle: hasEvaluation
                ? 'ASA ${asaScore ?? "?"} - ${data.assignedAnesthesiologist?.fullName ?? "Anesthésiste"}'
                : 'Non évalué',
            progress: hasEvaluation ? 1.0 : 0.0,
            progressText: hasEvaluation ? 'Fait' : 'En attente',
            isComplete: hasEvaluation,
          ),

          const SizedBox(height: 14),

          // Overall Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: checklistComplete && hasEvaluation
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: checklistComplete && hasEvaluation
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFFED7AA),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  checklistComplete && hasEvaluation
                      ? Icons.check_circle
                      : Icons.schedule,
                  size: 20,
                  color: checklistComplete && hasEvaluation
                      ? const Color(0xFF065F46)
                      : const Color(0xFF9A3412),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    checklistComplete && hasEvaluation
                        ? 'Patient prêt pour le bloc opératoire'
                        : 'Évaluations en cours - pas encore prêt',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: checklistComplete && hasEvaluation
                          ? const Color(0xFF065F46)
                          : const Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalSummary(HospitalCase hospitalCase) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé clinique',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _KVBox(label: 'Motif', value: hospitalCase.mainDiagnosis ?? 'Non renseigné')),
              const SizedBox(width: 10),
              Expanded(child: _KVBox(label: 'Type d\'admission', value: hospitalCase.entryMode.label)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _KVBox(label: 'Service', value: hospitalCase.service)),
              const SizedBox(width: 10),
              Expanded(child: _KVBox(label: 'Chambre', value: hospitalCase.roomNumber ?? 'Non assignée')),
            ],
          ),
          if (hospitalCase.notes != null && hospitalCase.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _KVBox(label: 'Notes', value: hospitalCase.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffCard(PatientDetailData data) {
    final surgery = data.patientData.surgery;
    final nurse = data.assignedNurse;
    final anesthesiologist = data.assignedAnesthesiologist;

    if (surgery == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Équipe assignée',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune intervention créée - créez une demande pour assigner l\'équipe',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Équipe assignée',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (anesthesiologist != null)
            _StaffRow(
              icon: Icons.monitor_heart_outlined,
              color: AppColors.anesthesiologistColor,
              name: anesthesiologist.fullName,
              role: 'Anesthésiste',
            ),
          if (anesthesiologist != null && nurse != null)
            const SizedBox(height: 10),
          if (nurse != null)
            _StaffRow(
              icon: Icons.medical_services_outlined,
              color: AppColors.nurseColor,
              name: nurse.fullName,
              role: 'Infirmier',
            ),
          if (anesthesiologist == null && nurse == null)
            Text(
              'Aucun personnel assigné',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDemandeCard(HospitalCase hospitalCase, surgery) {
    final hasSurgery = surgery != null;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demande d\'intervention',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (hasSurgery) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Statut: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          _StatusChip(
                            label: _getSurgeryStatusLabel(surgery.status),
                            type: ChipType.ok,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        surgery.surgeryType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Statut: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const _StatusChip(label: 'Absente', type: ChipType.todo),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Créez une demande d\'intervention',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _PrimaryButton(
                  label: 'Créer',
                  icon: Icons.add,
                  onTap: () => context.push(
                    '/surgeon/demande',
                    extra: {
                      'caseId': hospitalCase.id,
                      'patientId': hospitalCase.patientId,
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _NavButton(
                label: 'Accueil',
                isActive: false,
                onTap: () => context.go('/surgeon'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NavButton(
                label: 'Patients',
                isActive: false,
                onTap: () => context.go('/surgeon/patients'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return '??';
  }

  ChipType _getStatusChipType(CaseStatus status) {
    switch (status) {
      case CaseStatus.admission:
        return ChipType.todo;
      case CaseStatus.preop:
        return ChipType.wait;
      case CaseStatus.surgery:
        return ChipType.wait;
      case CaseStatus.completed:
        return ChipType.ok;
      default:
        return ChipType.todo;
    }
  }

  String _getSurgeryStatusLabel(SurgeryStatus status) {
    switch (status) {
      case SurgeryStatus.scheduled:
        return 'Programmée';
      case SurgeryStatus.preparing:
        return 'En préparation';
      case SurgeryStatus.inProgress:
        return 'En cours';
      case SurgeryStatus.completed:
        return 'Terminée';
      case SurgeryStatus.cancelled:
        return 'Annulée';
      case SurgeryStatus.postponed:
        return 'Reportée';
    }
  }
}

// Reusable Components

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

enum ChipType { todo, wait, ok, risk }

class _StatusChip extends StatelessWidget {
  final String label;
  final ChipType type;

  const _StatusChip({
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, textColor) = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }

  (Color, Color, Color) _getColors() {
    switch (type) {
      case ChipType.todo:
        return (const Color(0xFFF1F5F9), const Color(0xFFE2E8F0), const Color(0xFF0F172A));
      case ChipType.wait:
        return (const Color(0xFFFFF7ED), const Color(0xFFFED7AA), const Color(0xFF9A3412));
      case ChipType.ok:
        return (const Color(0xFFECFDF5), const Color(0xFFA7F3D0), const Color(0xFF065F46));
      case ChipType.risk:
        return (const Color(0xFFFEF2F2), const Color(0xFFFECACA), const Color(0xFF991B1B));
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0B1220),
        ),
      ),
    );
  }
}

class _KVBox extends StatelessWidget {
  final String label;
  final String value;

  const _KVBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double progress;
  final String progressText;
  final bool isComplete;

  const _ProgressRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressText,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete ? color.withValues(alpha: 0.3) : AppColors.border,
          width: isComplete ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isComplete ? color.withValues(alpha: 0.15) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isComplete ? color : AppColors.border),
            ),
            child: Text(
              progressText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isComplete ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String role;

  const _StaffRow({
    required this.icon,
    required this.color,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.primary.withValues(alpha: 0.25) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
