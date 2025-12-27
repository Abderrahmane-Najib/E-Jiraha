import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class TriageQueueScreen extends ConsumerWidget {
  const TriageQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Bar
          _buildTopBar(context),

          // Content
          Expanded(
            child: SingleChildScrollView(
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
                    '4 admissions nécessitent une prise de constantes.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Triage List
                  ..._patients.map((patient) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TriageCard(
                      patient: patient,
                      onTap: () => context.push(
                        '/nurse/triage?patientId=${patient.id}&patientName=${Uri.encodeComponent(patient.name)}&patientInitials=${patient.initials}&dossierNumber=${patient.dossierNumber}&service=${Uri.encodeComponent(patient.service)}&isUrgent=${patient.isUrgent}',
                      ),
                    ),
                  )),
                ],
              ),
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

  static final List<_PatientData> _patients = [
    _PatientData(
      id: '1',
      initials: 'AM',
      name: 'Amina Mansouri',
      dossierNumber: 'CHU-02451',
      service: 'Chirurgie Viscérale',
      waitTime: '12 min',
      isUrgent: false,
    ),
    _PatientData(
      id: '2',
      initials: 'YB',
      name: 'Youssef Bennani',
      dossierNumber: 'CHU-02452',
      service: 'Urgence',
      waitTime: '05 min',
      isUrgent: true,
    ),
    _PatientData(
      id: '3',
      initials: 'SK',
      name: 'Salma Kadiri',
      dossierNumber: 'CHU-02453',
      service: 'Traumatologie',
      waitTime: '24 min',
      isUrgent: false,
    ),
    _PatientData(
      id: '4',
      initials: 'KE',
      name: 'Karim El Amrani',
      dossierNumber: 'CHU-02454',
      service: 'Chirurgie Générale',
      waitTime: '45 min',
      isUrgent: false,
    ),
  ];
}

class _PatientData {
  final String id;
  final String initials;
  final String name;
  final String dossierNumber;
  final String service;
  final String waitTime;
  final bool isUrgent;

  _PatientData({
    required this.id,
    required this.initials,
    required this.name,
    required this.dossierNumber,
    required this.service,
    required this.waitTime,
    required this.isUrgent,
  });
}

class _TriageCard extends StatelessWidget {
  final _PatientData patient;
  final VoidCallback onTap;

  const _TriageCard({
    required this.patient,
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
                color: patient.isUrgent
                    ? const Color(0xFFFEE2E2)
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                patient.initials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: patient.isUrgent ? AppColors.error : AppColors.primary,
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
                    patient.name,
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
                          '⏱ ${patient.waitTime}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: patient.isUrgent
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (patient.isUrgent)
                        Text(
                          '🚨 URGENCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        )
                      else
                        Text(
                          patient.service,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
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
                color: patient.isUrgent ? AppColors.error : AppColors.primary,
                boxShadow: patient.isUrgent
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
