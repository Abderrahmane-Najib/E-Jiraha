import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/hospital_case.dart';
import '../providers/anesthesiologist_provider.dart';

class AnesthesiologistPlanningScreen extends ConsumerWidget {
  const AnesthesiologistPlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planningState = ref.watch(anesthesiaPlanningProvider);

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
                await ref.read(anesthesiaPlanningProvider.notifier).loadPlanning();
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
                                    .read(anesthesiaPlanningProvider.notifier)
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
                                    'Patients planifiés',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${planningState.planningList.length} patient${planningState.planningList.length > 1 ? 's' : ''} en attente.',
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
                                    final evaluation = data.evaluation;
                                    final patientName = patient?.fullName ?? 'Patient inconnu';
                                    final initials = _getInitials(patientName);
                                    final progress = checklist?.items.where((item) => item.isCompleted).length ?? 0;
                                    final total = checklist?.items.length ?? 5;
                                    final isComplete = checklist?.isCompleted ?? false;
                                    final scheduledTime = _formatTime(hospitalCase.entryDate);

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
                                        isComplete: isComplete,
                                        hasEvaluation: evaluation != null,
                                        isValidated: evaluation?.isValidated ?? false,
                                        onTap: () => context.push(
                                          '/anesthesiologist/checklist-view',
                                          extra: {
                                            'caseId': hospitalCase.id,
                                            'patientId': hospitalCase.patientId,
                                            'checklistId': checklist?.id,
                                          },
                                        ),
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
            Icons.event_available,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun patient planifié',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune intervention prévue pour le moment',
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
  final bool isComplete;
  final bool hasEvaluation;
  final bool isValidated;
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
    required this.isComplete,
    required this.hasEvaluation,
    required this.isValidated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Time Slot
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    bloc,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color borderColor;
    Color textColor;
    String label;
    IconData icon;

    if (isValidated) {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      borderColor = AppColors.success.withValues(alpha: 0.3);
      textColor = AppColors.success;
      label = 'Prêt';
      icon = Icons.check_circle;
    } else if (hasEvaluation) {
      bgColor = AppColors.warning.withValues(alpha: 0.1);
      borderColor = AppColors.warning.withValues(alpha: 0.3);
      textColor = AppColors.warning;
      label = 'En cours';
      icon = Icons.pending;
    } else {
      bgColor = const Color(0xFFF5F5F5);
      borderColor = AppColors.border;
      textColor = AppColors.textSecondary;
      label = 'À évaluer';
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
