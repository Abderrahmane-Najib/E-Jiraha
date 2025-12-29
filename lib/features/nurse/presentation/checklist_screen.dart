import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/checklist.dart';
import '../../../models/patient.dart';
import '../../../models/hospital_case.dart';
import '../../../models/activity_log.dart';
import '../../../services/checklist_repository.dart';
import '../../../services/patient_repository.dart';
import '../../../services/hospital_case_repository.dart';
import '../../../services/activity_log_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/nurse_provider.dart';

/// Provider for loading checklist screen data
final checklistScreenDataProvider = FutureProvider.family<ChecklistScreenData?, String>((ref, caseId) async {
  if (caseId.isEmpty) return null;

  final caseRepo = HospitalCaseRepository();
  final patientRepo = PatientRepository();
  final checklistRepo = ChecklistRepository();

  try {
    final hospitalCase = await caseRepo.getCaseById(caseId);
    if (hospitalCase == null) return null;

    final patient = await patientRepo.getPatientById(hospitalCase.patientId);

    // Try to find existing preop checklist for this case
    Checklist? checklist;
    try {
      checklist = await checklistRepo.getChecklistByCaseAndType(caseId, ChecklistType.preop);
    } catch (e) {
      // Checklist might not exist yet, that's OK
      checklist = null;
    }

    return ChecklistScreenData(
      patient: patient,
      hospitalCase: hospitalCase,
      checklist: checklist,
    );
  } catch (e) {
    rethrow;
  }
});

class ChecklistScreenData {
  final Patient? patient;
  final HospitalCase? hospitalCase;
  final Checklist? checklist;

  const ChecklistScreenData({
    this.patient,
    this.hospitalCase,
    this.checklist,
  });
}

class ChecklistScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String patientId;
  final String? checklistId;

  const ChecklistScreen({
    super.key,
    required this.caseId,
    required this.patientId,
    this.checklistId,
  });

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  final ChecklistRepository _checklistRepository = ChecklistRepository();
  final ActivityLogRepository _logRepository = ActivityLogRepository();
  Map<String, ChecklistItemStatus> _itemStatuses = {};
  bool _isSubmitting = false;
  Checklist? _currentChecklist;
  Patient? _patient;

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(checklistScreenDataProvider(widget.caseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur: $error', style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(checklistScreenDataProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data == null || data.hospitalCase == null) {
            return const Center(child: Text('Données non trouvées'));
          }

          final patient = data.patient;
          final hospitalCase = data.hospitalCase!;
          _currentChecklist = data.checklist;
          _patient = patient;

          // Check if vital signs are filled
          final vitals = hospitalCase.vitalSigns;
          final hasVitalSigns = vitals != null &&
              vitals.isNotEmpty &&
              (vitals['tension']?.toString().isNotEmpty ?? false) &&
              vitals['pouls'] != null;

          // If vital signs are missing, show warning and redirect
          if (!hasVitalSigns) {
            return _buildVitalSignsMissingScreen(hospitalCase);
          }

          // Initialize item statuses from checklist
          if (_currentChecklist != null && _itemStatuses.isEmpty) {
            for (final item in _currentChecklist!.items) {
              _itemStatuses[item.id] = item.status;
            }
          }

          return Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientHero(patient, hospitalCase),
                      const SizedBox(height: 24),
                      _buildChecklistSection(),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChecklistSection() {
    if (_currentChecklist == null) {
      return _buildCreateChecklistButton();
    }

    final checklist = _currentChecklist!;
    final completedCount = _itemStatuses.values
        .where((s) => s == ChecklistItemStatus.done || s == ChecklistItemStatus.notApplicable)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Checklist de sécurité',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$completedCount / ${checklist.items.length} VALIDÉS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...checklist.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ChecklistItemCard(
            label: item.label,
            isChecked: _itemStatuses[item.id] == ChecklistItemStatus.done,
            isRequired: item.isRequired,
            onChanged: (value) => _updateItemStatus(item, value ?? false),
          ),
        )),
      ],
    );
  }

  Widget _buildCreateChecklistButton() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.playlist_add,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune checklist créée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez une checklist pré-opératoire',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createChecklist,
            icon: const Icon(Icons.add),
            label: const Text('Créer la checklist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createChecklist() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final checklist = Checklist.createPreopChecklist(
        id: '',
        caseId: widget.caseId,
        createdBy: user.id,
      );

      final checklistId = await _checklistRepository.createChecklist(checklist);

      // Load the created checklist with its ID
      final createdChecklist = await _checklistRepository.getChecklistById(checklistId);
      if (createdChecklist != null) {
        setState(() {
          _currentChecklist = createdChecklist;
          _itemStatuses.clear();
          for (final item in createdChecklist.items) {
            _itemStatuses[item.id] = item.status;
          }
        });
      }

      // Also invalidate provider for consistency
      ref.invalidate(checklistScreenDataProvider(widget.caseId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Checklist créée avec succès'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateItemStatus(ChecklistItem item, bool isChecked) async {
    if (_currentChecklist == null || _currentChecklist!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur: Checklist non initialisée'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final newStatus = isChecked ? ChecklistItemStatus.done : ChecklistItemStatus.pending;
    final user = ref.read(currentUserProvider);

    setState(() {
      _itemStatuses[item.id] = newStatus;
    });

    try {
      final updatedItem = item.copyWith(
        status: newStatus,
        completedAt: isChecked ? DateTime.now() : null,
        completedBy: isChecked ? user?.id : null,
      );

      await _checklistRepository.updateChecklistItem(
        _currentChecklist!.id,
        updatedItem,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _itemStatuses[item.id] = item.status;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sauvegarde: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 20),
            Text(
              'Préparation Bloc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHero(Patient? patient, HospitalCase hospitalCase) {
    final patientName = patient?.fullName ?? 'Patient inconnu';
    final dossierNumber = hospitalCase.id.substring(0, 8).toUpperCase();
    final room = hospitalCase.roomNumber ?? 'Non assignée';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID #$dossierNumber • $room',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_currentChecklist == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: GestureDetector(
        onTap: _isSubmitting ? null : _submitChecklist,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 20, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'VALIDER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitChecklist() async {
    if (_currentChecklist == null || _currentChecklist!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur: Checklist non initialisée'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _checklistRepository.markAsCompleted(_currentChecklist!.id, user.id);

      // Log the activity
      await _logRepository.logActivity(
        type: ActivityType.checklistCompleted,
        description: 'Checklist pré-opératoire complétée pour ${_patient?.fullName ?? 'Patient'}',
        targetId: _currentChecklist!.id,
        targetName: _patient?.fullName ?? 'Patient',
        userId: user.id,
      );

      // Refresh all relevant providers
      ref.read(planningProvider.notifier).loadPlanning();
      ref.read(triageQueueProvider.notifier).loadTriageQueue();
      ref.invalidate(nurseDashboardStatsProvider);
      ref.invalidate(checklistScreenDataProvider(widget.caseId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Checklist validée avec succès'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildVitalSignsMissingScreen(HospitalCase hospitalCase) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Warning icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 50,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Constantes manquantes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Les signes vitaux du patient doivent être enregistrés avant de pouvoir compléter la checklist pré-opératoire.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Go to triage button
                  GestureDetector(
                    onTap: () {
                      context.pushReplacement(
                        '/nurse/triage',
                        extra: {
                          'caseId': hospitalCase.id,
                          'patientId': hospitalCase.patientId,
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Compléter le triage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Back button
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Retour',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistItemCard extends StatelessWidget {
  final String label;
  final bool isChecked;
  final bool isRequired;
  final ValueChanged<bool?> onChanged;

  const _ChecklistItemCard({
    required this.label,
    required this.isChecked,
    required this.isRequired,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isChecked ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isChecked ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isChecked ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isRequired)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Requis',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
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
}
