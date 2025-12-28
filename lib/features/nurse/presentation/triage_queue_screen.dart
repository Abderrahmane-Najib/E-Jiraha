import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/hospital_case.dart';
import '../providers/nurse_provider.dart';

class TriageQueueScreen extends ConsumerWidget {
  const TriageQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triageState = ref.watch(triageQueueProvider);

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
                await ref.read(triageQueueProvider.notifier).loadTriageQueue();
              },
              child: triageState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : triageState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                triageState.error!,
                                style: TextStyle(color: AppColors.error),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(triageQueueProvider.notifier)
                                    .loadTriageQueue(),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : triageState.triageQueue.isEmpty
                          ? _buildEmptyState()
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    'Patients en attente',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${triageState.triageQueue.length} admission${triageState.triageQueue.length > 1 ? 's' : ''} nécessite${triageState.triageQueue.length > 1 ? 'nt' : ''} une prise de constantes.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Triage List
                                  ...triageState.triageQueue.map((data) {
                                    final patient = data.patient;
                                    final hospitalCase = data.hospitalCase;
                                    final isUrgent = hospitalCase.entryMode == EntryMode.emergency;
                                    final patientName = patient?.fullName ?? 'Patient inconnu';
                                    final initials = _getInitials(patientName);
                                    final waitTime = _getWaitTime(hospitalCase.entryDate);

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _TriageCard(
                                        initials: initials,
                                        name: patientName,
                                        dossierNumber: hospitalCase.id.substring(0, 8).toUpperCase(),
                                        service: hospitalCase.service,
                                        waitTime: waitTime,
                                        isUrgent: isUrgent,
                                        onTap: () => context.push(
                                          '/nurse/triage',
                                          extra: {
                                            'caseId': hospitalCase.id,
                                            'patientId': hospitalCase.patientId,
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
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun patient en attente',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les patients ont été triés',
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
                'File de Triage',
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return '??';
  }

  String _getWaitTime(DateTime entryDate) {
    final now = DateTime.now();
    final difference = now.difference(entryDate);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes} min';
    }
  }
}

class _TriageCard extends StatelessWidget {
  final String initials;
  final String name;
  final String dossierNumber;
  final String service;
  final String waitTime;
  final bool isUrgent;
  final VoidCallback onTap;

  const _TriageCard({
    required this.initials,
    required this.name,
    required this.dossierNumber,
    required this.service,
    required this.waitTime,
    required this.isUrgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isUrgent
                    ? const Color(0xFFFEE2E2)
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isUrgent ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          waitTime,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isUrgent
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isUrgent)
                        Text(
                          'URGENCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            service,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Urgency Indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUrgent ? AppColors.error : AppColors.primary,
                boxShadow: isUrgent
                    ? [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
