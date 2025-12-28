import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/hospital_case.dart';
import '../../../models/surgery.dart';
import '../../../models/user.dart';
import '../../../services/surgery_repository.dart';
import '../../../services/hospital_case_repository.dart';
import '../../../services/user_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/surgeon_provider.dart';

class SurgeonDemandeScreen extends ConsumerStatefulWidget {
  final String? caseId;
  final String? patientId;

  const SurgeonDemandeScreen({
    super.key,
    this.caseId,
    this.patientId,
  });

  @override
  ConsumerState<SurgeonDemandeScreen> createState() =>
      _SurgeonDemandeScreenState();
}

class _SurgeonDemandeScreenState extends ConsumerState<SurgeonDemandeScreen> {
  final SurgeryRepository _surgeryRepository = SurgeryRepository();
  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final UserRepository _userRepository = UserRepository();

  SurgeryRequestData? _selectedPatientData;
  String _selectedDecision = 'À valider';
  String _selectedPriority = 'Urgence';
  String _selectedDuration = '45 min';
  final TextEditingController _diagnosticController = TextEditingController();
  final TextEditingController _gesteController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  // Staff selection
  List<User> _nurses = [];
  List<User> _anesthesiologists = [];
  String? _selectedAnesthesiologistId;
  List<String> _selectedNurseIds = [];
  bool _loadingStaff = true;

  bool get _hasPreselectedPatient => widget.caseId != null;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    if (widget.caseId != null) {
      _loadPreselectedPatient();
    }
  }

  Future<void> _loadStaff() async {
    try {
      final nurses = await _userRepository.getUsersByRole(UserRole.nurse);
      final anesthesiologists = await _userRepository.getUsersByRole(UserRole.anesthesiologist);
      if (mounted) {
        // Show active staff, or all if none are active
        var activeNurses = nurses.where((n) => n.isActive).toList();
        var activeAnesth = anesthesiologists.where((a) => a.isActive).toList();
        if (activeNurses.isEmpty && nurses.isNotEmpty) activeNurses = nurses;
        if (activeAnesth.isEmpty && anesthesiologists.isNotEmpty) activeAnesth = anesthesiologists;
        setState(() {
          _nurses = activeNurses;
          _anesthesiologists = activeAnesth;
          _loadingStaff = false;
        });
      }
    } catch (e) {
      // Fallback: get all users and filter manually
      try {
        final allUsers = await _userRepository.getAllUsers();
        if (mounted) {
          setState(() {
            _nurses = allUsers.where((u) => u.role == UserRole.nurse).toList();
            _anesthesiologists = allUsers.where((u) => u.role == UserRole.anesthesiologist).toList();
            _loadingStaff = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _loadingStaff = false);
        }
      }
    }
  }

  Future<void> _loadPreselectedPatient() async {
    final data = await ref.read(patientDetailsProvider(widget.caseId!).future);
    if (data != null) {
      setState(() {
        _selectedPatientData = data;
        _diagnosticController.text = data.hospitalCase.mainDiagnosis ?? '';
      });
    }
  }

  @override
  void dispose() {
    _diagnosticController.dispose();
    _gesteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectPatient(SurgeryRequestData data) {
    setState(() {
      _selectedPatientData = data;
      _diagnosticController.text = data.hospitalCase.mainDiagnosis ?? '';
    });
  }

  Future<void> _saveForm() async {
    if (_selectedPatientData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner un patient'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_diagnosticController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez entrer un diagnostic'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_gesteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez entrer un geste demandé'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      final hospitalCase = _selectedPatientData!.hospitalCase;

      // Create surgery record
      final surgery = Surgery(
        id: '',
        caseId: hospitalCase.id,
        patientId: hospitalCase.patientId,
        leadSurgeonId: user?.id ?? '',
        surgeryType: _gesteController.text.trim(),
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: _parseDurationMinutes(_selectedDuration),
        status: SurgeryStatus.scheduled,
        urgency: _parseUrgency(_selectedPriority),
        anesthesiologistId: _selectedAnesthesiologistId,
        nurseIds: _selectedNurseIds,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user?.id ?? '',
      );

      await _surgeryRepository.createSurgery(surgery);

      // Update case status if decision is to operate
      if (_selectedDecision == 'Opérer') {
        await _caseRepository.updateCaseStatus(hospitalCase.id, CaseStatus.preop);
      } else if (_selectedDecision == 'Annuler') {
        await _caseRepository.updateCaseStatus(hospitalCase.id, CaseStatus.cancelled);
      }

      // Refresh providers
      ref.invalidate(decisionsProvider);
      ref.invalidate(surgeonPatientsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Demande enregistrée avec succès'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  int _parseDurationMinutes(String duration) {
    switch (duration) {
      case '45 min':
        return 45;
      case '60 min':
        return 60;
      case '90 min':
        return 90;
      default:
        return 60;
    }
  }

  SurgeryUrgency _parseUrgency(String priority) {
    switch (priority) {
      case 'Urgence':
        return SurgeryUrgency.emergency;
      case 'Semi-urgent':
        return SurgeryUrgency.urgent;
      case 'Programmé':
        return SurgeryUrgency.elective;
      default:
        return SurgeryUrgency.elective;
    }
  }

  @override
  Widget build(BuildContext context) {
    final decisionsState = ref.watch(decisionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 14),
                  if (!_hasPreselectedPatient) ...[
                    _buildAdmissionsCard(decisionsState),
                    const SizedBox(height: 14),
                  ],
                  _buildFormCard(),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
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
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chirurgien • Demande d\'intervention',
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

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -60,
            child: Transform.rotate(
              angle: 0.314,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Créer une demande',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisir une admission assignée au chirurgien puis compléter la décision opératoire et les pré-requis.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionsCard(DecisionsState state) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admissions assignées',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dossiers en attente de décision opératoire / demande.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.pendingDecisions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aucune admission en attente',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...state.pendingDecisions.map((data) {
              final patient = data.patient;
              final hospitalCase = data.hospitalCase;
              final patientName = patient?.fullName ?? 'Patient inconnu';
              final initials = _getInitials(patientName);
              final isSelected = _selectedPatientData?.hospitalCase.id == hospitalCase.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AdmissionItem(
                  initials: initials,
                  name: patientName,
                  time: _getEntryType(hospitalCase.entryMode),
                  dossier: '#${hospitalCase.id.substring(0, 8).toUpperCase()}',
                  isSelected: isSelected,
                  onChoose: () => _selectPatient(data),
                ),
              );
            }),
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

  String _getEntryType(EntryMode mode) {
    switch (mode) {
      case EntryMode.scheduled:
        return 'Programmée';
      case EntryMode.emergency:
        return 'Urgence';
    }
  }

  Widget _buildFormCard() {
    final patientName = _selectedPatientData?.patient?.fullName ?? 'Aucun patient sélectionné';
    final dossierNumber = _selectedPatientData != null
        ? '#${_selectedPatientData!.hospitalCase.id.substring(0, 8).toUpperCase()}'
        : '—';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient sélectionné:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary.withValues(alpha: 0.78),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patientName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Dossier',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary.withValues(alpha: 0.78),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dossierNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FormField(
            label: 'Décision opératoire',
            isRequired: true,
            child: _Dropdown(
              value: _selectedDecision,
              items: const ['À valider', 'Opérer', 'Reporter', 'Annuler'],
              onChanged: (value) => setState(() => _selectedDecision = value!),
            ),
          ),
          const SizedBox(height: 12),
          _FormField(
            label: 'Diagnostic / Motif',
            isRequired: true,
            child: _TextInput(controller: _diagnosticController),
          ),
          const SizedBox(height: 12),
          _FormField(
            label: 'Geste demandé',
            isRequired: true,
            child: _TextInput(controller: _gesteController),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Priorité',
                  isRequired: true,
                  child: _Dropdown(
                    value: _selectedPriority,
                    items: const ['Urgence', 'Semi-urgent', 'Programmé'],
                    onChanged: (value) => setState(() => _selectedPriority = value!),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FormField(
                  label: 'Durée estimée',
                  isRequired: true,
                  child: _Dropdown(
                    value: _selectedDuration,
                    items: const ['45 min', '60 min', '90 min'],
                    onChanged: (value) => setState(() => _selectedDuration = value!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Anesthesiologist selection
          _FormField(
            label: 'Anesthésiste',
            isRequired: false,
            child: _loadingStaff
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _StaffDropdown(
                    value: _selectedAnesthesiologistId,
                    hint: 'Sélectionner un anesthésiste',
                    items: _anesthesiologists,
                    icon: Icons.monitor_heart_outlined,
                    color: AppColors.anesthesiologistColor,
                    onChanged: (value) => setState(() => _selectedAnesthesiologistId = value),
                  ),
          ),
          const SizedBox(height: 12),
          // Nurse selection
          _FormField(
            label: 'Infirmier(s)',
            isRequired: false,
            child: _loadingStaff
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _MultiStaffSelector(
                    selectedIds: _selectedNurseIds,
                    availableStaff: _nurses,
                    icon: Icons.medical_services_outlined,
                    color: AppColors.nurseColor,
                    hint: 'Sélectionner des infirmiers',
                    onChanged: (ids) => setState(() => _selectedNurseIds = ids),
                  ),
          ),
          const SizedBox(height: 12),
          _FormField(
            label: 'Notes',
            isRequired: false,
            child: _TextAreaInput(controller: _notesController),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'Annuler',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _isSubmitting ? null : _saveForm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enregistrer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
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
}

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

class _AdmissionItem extends StatelessWidget {
  final String initials;
  final String name;
  final String time;
  final String dossier;
  final bool isSelected;
  final VoidCallback onChoose;

  const _AdmissionItem({
    required this.initials,
    required this.name,
    required this.time,
    required this.dossier,
    required this.isSelected,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 13,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Dossier $dossier',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onChoose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                isSelected ? 'Sélectionné' : 'Choisir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final Widget child;
  final Widget? trailing;

  const _FormField({
    required this.label,
    required this.isRequired,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary.withValues(alpha: 0.86),
                    letterSpacing: 0.2,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        dropdownColor: Colors.white,
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;

  const _TextInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.55)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _TextAreaInput extends StatelessWidget {
  final TextEditingController controller;

  const _TextAreaInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.55)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
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
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.border,
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

class _StaffDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<User> items;
  final IconData icon;
  final Color color;
  final ValueChanged<String?> onChanged;

  const _StaffDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null ? color : AppColors.border,
          width: value != null ? 2 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          items: items.map((user) {
            return DropdownMenuItem(
              value: user.id,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MultiStaffSelector extends StatelessWidget {
  final List<String> selectedIds;
  final List<User> availableStaff;
  final IconData icon;
  final Color color;
  final String hint;
  final ValueChanged<List<String>> onChanged;

  const _MultiStaffSelector({
    required this.selectedIds,
    required this.availableStaff,
    required this.icon,
    required this.color,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected staff chips
        if (selectedIds.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedIds.map((id) {
              final user = availableStaff.firstWhere(
                (u) => u.id == id,
                orElse: () => availableStaff.first,
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        final newIds = List<String>.from(selectedIds)..remove(id);
                        onChanged(newIds);
                      },
                      child: Icon(Icons.close, size: 14, color: color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        // Add button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: null,
              isExpanded: true,
              hint: Text(
                selectedIds.isEmpty ? hint : '+ Ajouter un autre',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              items: availableStaff
                  .where((user) => !selectedIds.contains(user.id))
                  .map((user) {
                return DropdownMenuItem(
                  value: user.id,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.fullName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final newIds = List<String>.from(selectedIds)..add(value);
                  onChanged(newIds);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
