import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AnesthesiologistPlanningScreen extends ConsumerWidget {
  const AnesthesiologistPlanningScreen({super.key});

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
                    'Vérifiez les checklists avant validation.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Patient List
                  ..._patients.map((patient) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PatientCard(
                      patient: patient,
                      onTap: () => context.push(
                        '/anesthesiologist/checklist-view?patientId=${patient.id}&patientName=${Uri.encodeComponent(patient.name)}&patientInitials=${patient.initials}&dossierNumber=${patient.dossierNumber}&room=${Uri.encodeComponent(patient.room)}&progress=${patient.progress}&total=${patient.total}',
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

  static final List<_PatientPlanningData> _patients = [
    _PatientPlanningData(
      id: '1',
      initials: 'AM',
      name: 'Amina MANSOURI',
      dossierNumber: 'CHU-02451',
      room: 'Salle 04',
      procedure: 'Cholécystectomie',
      time: '09:30',
      bloc: 'Bloc A',
      progress: 5,
      total: 5,
      isComplete: true,
    ),
    _PatientPlanningData(
      id: '2',
      initials: 'YB',
      name: 'Youssef BENNANI',
      dossierNumber: 'CHU-02452',
      room: 'Salle 07',
      procedure: 'Hernie Inguinale',
      time: '10:15',
      bloc: 'Bloc B',
      progress: 3,
      total: 5,
      isComplete: false,
    ),
    _PatientPlanningData(
      id: '3',
      initials: 'DA',
      name: 'Driss ALAMI',
      dossierNumber: 'CHU-02455',
      room: 'Salle 02',
      procedure: 'Appendicectomie',
      time: '11:00',
      bloc: 'Bloc A',
      progress: 0,
      total: 5,
      isComplete: false,
    ),
  ];
}

class _PatientPlanningData {
  final String id;
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

  _PatientPlanningData({
    required this.id,
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
  });
}

class _PatientCard extends StatelessWidget {
  final _PatientPlanningData patient;
  final VoidCallback onTap;

  const _PatientCard({
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
                    patient.time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    patient.bloc,
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
                    patient.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patient.procedure,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: patient.isComplete
                    ? AppColors.success.withValues(alpha: 0.1)
                    : patient.progress > 0
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: patient.isComplete
                      ? AppColors.success.withValues(alpha: 0.3)
                      : patient.progress > 0
                          ? AppColors.warning.withValues(alpha: 0.3)
                          : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (patient.isComplete)
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppColors.success,
                    )
                  else
                    Icon(
                      Icons.pending,
                      size: 12,
                      color: patient.progress > 0 ? AppColors.warning : AppColors.textSecondary,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    patient.isComplete
                        ? 'Prêt'
                        : '${patient.progress}/${patient.total}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: patient.isComplete
                          ? AppColors.success
                          : patient.progress > 0
                              ? AppColors.warning
                              : AppColors.textSecondary,
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
