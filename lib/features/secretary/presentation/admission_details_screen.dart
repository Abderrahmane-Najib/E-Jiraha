import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/hospital_case.dart';
import '../../../models/patient.dart';
import '../../../services/hospital_case_repository.dart';
import '../../../services/patient_repository.dart';
import '../../../services/user_repository.dart';

class AdmissionDetailsScreen extends ConsumerStatefulWidget {
  final String caseId;

  const AdmissionDetailsScreen({
    super.key,
    required this.caseId,
  });

  @override
  ConsumerState<AdmissionDetailsScreen> createState() =>
      _AdmissionDetailsScreenState();
}

class _AdmissionDetailsScreenState
    extends ConsumerState<AdmissionDetailsScreen> {
  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();
  final UserRepository _userRepository = UserRepository();

  bool _isLoading = true;
  HospitalCase? _hospitalCase;
  Patient? _patient;
  String? _doctorName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final hospitalCase = await _caseRepository.getCaseById(widget.caseId);
      if (hospitalCase != null) {
        final patient =
            await _patientRepository.getPatientById(hospitalCase.patientId);
        String? doctorName;
        if (hospitalCase.responsibleDoctorId != null) {
          final doctor =
              await _userRepository.getUserById(hospitalCase.responsibleDoctorId!);
          doctorName = doctor?.fullName;
        }

        if (mounted) {
          setState(() {
            _hospitalCase = hospitalCase;
            _patient = patient;
            _doctorName = doctorName;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Dossier non trouvé'),
              backgroundColor: AppColors.error,
            ),
          );
          context.pop();
        }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hospitalCase == null || _patient == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Dossier non trouvé'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Banner
                    _buildPatientBanner(),
                    const SizedBox(height: 16),

                    // Status Card
                    _buildStatusCard(),
                    const SizedBox(height: 16),

                    // Case Info Card
                    _buildCaseInfoCard(),
                    const SizedBox(height: 16),

                    // Vital Signs Card (if available)
                    if (_hospitalCase!.vitalSigns != null &&
                        _hospitalCase!.vitalSigns!.isNotEmpty)
                      _buildVitalSignsCard(),

                    // Diagnosis Card (if available)
                    if (_hospitalCase!.mainDiagnosis != null &&
                        _hospitalCase!.mainDiagnosis!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDiagnosisCard(),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails du Dossier',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '#${_hospitalCase!.id.substring(0, 8).toUpperCase()}',
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
        ),
      ),
    );
  }

  Widget _buildPatientBanner() {
    final isUrgent = _hospitalCase!.entryMode == EntryMode.emergency;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              _patient!.initials,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patient!.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CIN: ${_patient!.cin} • ${_patient!.age} ans',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _patient!.phone,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (isUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'URGENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _hospitalCase!.status;
    final (statusLabel, statusColor) = _getStatusStyle(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut actuel',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _hospitalCase!.entryMode == EntryMode.emergency
                  ? 'Urgence'
                  : 'Programmé',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations du dossier',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Date d\'entrée',
            value: DateFormat('dd/MM/yyyy à HH:mm')
                .format(_hospitalCase!.entryDate),
          ),
          const Divider(height: 20),
          _InfoRow(
            icon: Icons.local_hospital,
            label: 'Service',
            value: _hospitalCase!.service.isNotEmpty
                ? _hospitalCase!.service
                : 'Non assigné',
          ),
          if (_doctorName != null) ...[
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.person,
              label: 'Médecin responsable',
              value: _doctorName!,
            ),
          ],
          if (_hospitalCase!.roomNumber != null) ...[
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.bed,
              label: 'Chambre / Lit',
              value:
                  '${_hospitalCase!.roomNumber}${_hospitalCase!.bedNumber != null ? ' / ${_hospitalCase!.bedNumber}' : ''}',
            ),
          ],
          if (_hospitalCase!.stayDuration > 0) ...[
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.access_time,
              label: 'Durée de séjour',
              value: '${_hospitalCase!.stayDuration} jour(s)',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalSignsCard() {
    final vitalSigns = _hospitalCase!.vitalSigns!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Signes Vitaux',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (vitalSigns['tension'] != null)
                _VitalChip(
                  label: 'Tension',
                  value: '${vitalSigns['tension']}',
                  unit: 'mmHg',
                ),
              if (vitalSigns['pouls'] != null)
                _VitalChip(
                  label: 'Pouls',
                  value: '${vitalSigns['pouls']}',
                  unit: 'bpm',
                ),
              if (vitalSigns['temp'] != null)
                _VitalChip(
                  label: 'Temp',
                  value: '${vitalSigns['temp']}',
                  unit: '°C',
                ),
              if (vitalSigns['spo2'] != null)
                _VitalChip(
                  label: 'SpO2',
                  value: '${vitalSigns['spo2']}',
                  unit: '%',
                ),
              if (vitalSigns['poids'] != null)
                _VitalChip(
                  label: 'Poids',
                  value: '${vitalSigns['poids']}',
                  unit: 'kg',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_information,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Diagnostic',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _hospitalCase!.mainDiagnosis!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (_hospitalCase!.diagnosisCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Code CIM-10: ${_hospitalCase!.diagnosisCode}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action based on status
        if (_hospitalCase!.status == CaseStatus.admission)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push(
                  '/secretary/admission-ouverture',
                  extra: {
                    'caseId': _hospitalCase!.id,
                    'patientId': _patient!.id,
                  },
                );
              },
              icon: const Icon(Icons.edit_document),
              label: const Text('Compléter le dossier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showPatientDetails(),
                icon: const Icon(Icons.person_outline),
                label: const Text('Patient'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Print dossier
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impression à venir'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPatientDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Patient header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _patient!.initials,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _patient!.fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CIN: ${_patient!.cin}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Patient details
              _PatientDetailRow(
                icon: Icons.cake_outlined,
                label: 'Date de naissance',
                value: DateFormat('dd/MM/yyyy').format(_patient!.dateOfBirth),
              ),
              _PatientDetailRow(
                icon: Icons.cake_outlined,
                label: 'Âge',
                value: '${_patient!.age} ans',
              ),
              _PatientDetailRow(
                icon: _patient!.gender == Gender.male ? Icons.male : Icons.female,
                label: 'Sexe',
                value: _patient!.gender == Gender.male ? 'Masculin' : 'Féminin',
              ),
              _PatientDetailRow(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: _patient!.phone,
              ),
              if (_patient!.email != null && _patient!.email!.isNotEmpty)
                _PatientDetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _patient!.email!,
                ),
              _PatientDetailRow(
                icon: Icons.location_on_outlined,
                label: 'Adresse',
                value: _patient!.address,
              ),
              if (_patient!.bloodType != null && _patient!.bloodType != BloodType.unknown)
                _PatientDetailRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Groupe sanguin',
                  value: _patient!.bloodType!.name,
                ),

              // Allergies
              if (_patient!.allergies.isNotEmpty) ...[
                const Divider(height: 32),
                Row(
                  children: [
                    Icon(Icons.warning_amber, size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Allergies',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _patient!.allergies.map((allergy) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      allergy,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  )).toList(),
                ),
              ],

              // Antecedents
              if (_patient!.antecedents.isNotEmpty) ...[
                const Divider(height: 32),
                Row(
                  children: [
                    Icon(Icons.history, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Antécédents',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(_patient!.antecedents.map((ant) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: AppColors.textSecondary)),
                      Expanded(
                        child: Text(
                          ant,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))),
              ],

              // Emergency contact
              if (_patient!.emergencyContactName != null &&
                  _patient!.emergencyContactName!.isNotEmpty) ...[
                const Divider(height: 32),
                Row(
                  children: [
                    Icon(Icons.emergency, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Contact d\'urgence',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _patient!.emergencyContactName!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_patient!.emergencyContactPhone != null)
                  Text(
                    _patient!.emergencyContactPhone!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],

              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _getStatusStyle(CaseStatus status) {
    switch (status) {
      case CaseStatus.admission:
        return ('Admission', const Color(0xFFEA580C));
      case CaseStatus.consultation:
        return ('Consultation', const Color(0xFF0F172A));
      case CaseStatus.preop:
        return ('Pré-opératoire', const Color(0xFF1E40AF));
      case CaseStatus.surgery:
        return ('Bloc opératoire', const Color(0xFF92400E));
      case CaseStatus.postop:
        return ('Post-opératoire', const Color(0xFF065F46));
      case CaseStatus.discharge:
        return ('Sortie', const Color(0xFF166534));
      case CaseStatus.completed:
        return ('Terminé', const Color(0xFF166534));
      case CaseStatus.cancelled:
        return ('Annulé', const Color(0xFF991B1B));
    }
  }

  IconData _getStatusIcon(CaseStatus status) {
    switch (status) {
      case CaseStatus.admission:
        return Icons.login;
      case CaseStatus.consultation:
        return Icons.medical_services;
      case CaseStatus.preop:
        return Icons.checklist;
      case CaseStatus.surgery:
        return Icons.local_hospital;
      case CaseStatus.postop:
        return Icons.healing;
      case CaseStatus.discharge:
        return Icons.logout;
      case CaseStatus.completed:
        return Icons.check_circle;
      case CaseStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _VitalChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 10,
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

class _PatientDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PatientDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
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
