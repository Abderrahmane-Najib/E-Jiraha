import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/hospital_case.dart';
import '../providers/nurse_provider.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planningState = ref.watch(planningProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Bar
          _buildTopBar(context),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(planningProvider.notifier).loadPlanning();
              },
              child: planningState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : planningState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                planningState.error!,
                                style: TextStyle(color: AppColors.error),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(planningProvider.notifier)
                                    .loadPlanning(),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : planningState.planningList.isEmpty
                          ? _buildEmptyState()
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    'Patients à préparer',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${planningState.planningList.length} patient${planningState.planningList.length > 1 ? 's' : ''} en attente de préparation.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Patient List
                                  ...planningState.planningList.map((data) {
                                    final patient = data.patient;
                                    final hospitalCase = data.hospitalCase;
                                    final checklist = data.preopChecklist;
                                    final patientName = patient?.fullName ?? 'Patient inconnu';
                                    final initials = _getInitials(patientName);
                                    final isUrgent = hospitalCase.entryMode == EntryMode.emergency;
                                    final progress = checklist?.items.where((item) => item.isCompleted).length ?? 0;
                                    final total = checklist?.items.length ?? 5;
                                    final scheduledTime = _formatTime(hospitalCase.entryDate);
                                    final hasVitalSigns = data.hasVitalSigns;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _PatientCard(
                                        initials: initials,
                                        name: patientName,
                                        dossierNumber: hospitalCase.id.substring(0, 8).toUpperCase(),
                                        room: hospitalCase.roomNumber ?? 'Non assignée',
                                        procedure: hospitalCase.mainDiagnosis ?? 'Non spécifié',
                                        time: scheduledTime,
                                        bloc: hospitalCase.service,
                                        progress: progress,
                                        total: total,
                                        isUrgent: isUrgent,
                                        hasChecklist: checklist != null,
                                        hasVitalSigns: hasVitalSigns,
                                        onTap: () {
                                          if (!hasVitalSigns) {
                                            // Show warning and redirect to triage
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.warning_amber, color: Colors.white),
                                                    const SizedBox(width: 8),
                                                    const Expanded(
                                                      child: Text('Constantes manquantes. Veuillez compléter le triage d\'abord.'),
                                                    ),
                                                  ],
                                                ),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: AppColors.warning,
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                            // Navigate to triage
                                            context.push(
                                              '/nurse/triage',
                                              extra: {
                                                'caseId': hospitalCase.id,
                                                'patientId': hospitalCase.patientId,
                                              },
                                            );
                                          } else {
                                            // Navigate to checklist
                                            context.push(
                                              '/nurse/checklist',
                                              extra: {
                                                'caseId': hospitalCase.id,
                                                'patientId': hospitalCase.patientId,
                                                'checklistId': checklist?.id,
                                              },
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun patient à préparer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les patients ont été préparés',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Planning Pré-op',
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return '??';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PatientCard extends StatelessWidget {
  final String initials;
  final String name;
  final String dossierNumber;
  final String room;
  final String procedure;
  final String time;
  final String bloc;
  final int progress;
  final int total;
  final bool isUrgent;
  final bool hasChecklist;
  final bool hasVitalSigns;
  final VoidCallback onTap;

  const _PatientCard({
    required this.initials,
    required this.name,
    required this.dossierNumber,
    required this.room,
    required this.procedure,
    required this.time,
    required this.bloc,
    required this.progress,
    required this.total,
    required this.isUrgent,
    required this.hasChecklist,
    required this.hasVitalSigns,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = progress > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasVitalSigns ? Colors.white : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasVitalSigns ? AppColors.border : AppColors.warning.withValues(alpha: 0.5),
            width: hasVitalSigns ? 1 : 2,
          ),
        ),
        child: Column(
          children: [
            // Warning banner if vital signs missing
            if (!hasVitalSigns) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Constantes manquantes - Triage requis',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward, size: 14, color: AppColors.warning),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                // Time Slot
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? const Color(0xFFFEE2E2)
                        : hasVitalSigns
                            ? AppColors.primarySurface
                            : AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isUrgent
                              ? AppColors.error
                              : hasVitalSigns
                                  ? AppColors.primary
                                  : AppColors.warning,
                        ),
                      ),
                      Text(
                        bloc,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isUrgent
                              ? AppColors.error
                              : hasVitalSigns
                                  ? AppColors.primary
                                  : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Patient Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        procedure,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: !hasVitalSigns
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : hasProgress
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: !hasVitalSigns
                          ? AppColors.warning
                          : hasProgress
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFFEDD5),
                    ),
                  ),
                  child: Text(
                    !hasVitalSigns
                        ? 'Triage'
                        : hasProgress
                            ? 'Checklist ($progress/$total)'
                            : 'À débuter',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: !hasVitalSigns
                          ? AppColors.warning
                          : hasProgress
                              ? AppColors.error
                              : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
