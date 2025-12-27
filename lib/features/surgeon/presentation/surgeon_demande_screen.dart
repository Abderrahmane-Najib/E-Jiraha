import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SurgeonDemandeScreen extends ConsumerStatefulWidget {
  final String? patientId;
  final String? patientName;
  final String? patientInitials;
  final String? dossierNumber;
  final String? diagnostic;
  final String? geste;

  const SurgeonDemandeScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.patientInitials,
    this.dossierNumber,
    this.diagnostic,
    this.geste,
  });

  @override
  ConsumerState<SurgeonDemandeScreen> createState() =>
      _SurgeonDemandeScreenState();
}

class _SurgeonDemandeScreenState extends ConsumerState<SurgeonDemandeScreen> {
  late String _selectedPatient;
  late String _selectedDossier;
  String _selectedDecision = 'À valider';
  String _selectedPriority = 'Urgence';
  String _selectedDuration = '45 min';
  late TextEditingController _diagnosticController;
  late TextEditingController _gesteController;
  final TextEditingController _notesController =
      TextEditingController(text: 'Antécédents: RAS. Allergies: Aucune connue.');

  bool get _hasPreselectedPatient => widget.patientId != null;

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.patientName ?? 'Mr. Rachid M.';
    _selectedDossier = widget.dossierNumber ?? '#CHU-03214';
    _diagnosticController = TextEditingController(
      text: widget.diagnostic ?? 'Appendicite aiguë suspectée',
    );
    _gesteController = TextEditingController(
      text: widget.geste ?? 'Appendicectomie',
    );
  }

  final List<_PrerequisItem> _prerequisites = [
    _PrerequisItem(name: 'Imagerie (Écho/Scanner)', status: PrerequisStatus.ok, isChecked: true),
    _PrerequisItem(name: 'Biologie (NFS/CRP)', status: PrerequisStatus.wait, isChecked: false),
    _PrerequisItem(name: 'Consentement', status: PrerequisStatus.todo, isChecked: false),
    _PrerequisItem(name: 'Avis anesthésie', status: PrerequisStatus.todo, isChecked: false),
  ];

  final List<_AdmissionData> _admissions = [
    _AdmissionData(
      initials: 'RM',
      name: 'Mr. Rachid M.',
      time: 'Urgence',
      dossier: '#CHU-03214',
      chips: [_ChipData('Bio manquante', ChipType.wait)],
      diagnostic: 'Appendicite aiguë suspectée',
      geste: 'Appendicectomie',
    ),
    _AdmissionData(
      initials: 'SA',
      name: 'Mrs. Sara A.',
      time: 'Consult',
      dossier: '#CHU-03188',
      chips: [_ChipData('Décision', ChipType.todo), _ChipData('Allergies', ChipType.risk)],
      diagnostic: 'Cholécystite',
      geste: 'Cholécystectomie',
    ),
    _AdmissionData(
      initials: 'HL',
      name: 'Mr. Hamza L.',
      time: 'Transfert',
      dossier: '#CHU-03102',
      chips: [_ChipData('Imagerie OK', ChipType.ok)],
      diagnostic: 'Occlusion intestinale',
      geste: 'Laparotomie exploratrice',
    ),
  ];

  int get _completedPrerequisites =>
      _prerequisites.where((p) => p.isChecked).length;

  @override
  void dispose() {
    _diagnosticController.dispose();
    _gesteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectPatient(_AdmissionData admission) {
    setState(() {
      _selectedPatient = admission.name;
      _selectedDossier = admission.dossier;
      _diagnosticController.text = admission.diagnostic;
      _gesteController.text = admission.geste;
    });
  }

  void _togglePrerequisite(int index) {
    setState(() {
      _prerequisites[index].isChecked = !_prerequisites[index].isChecked;
    });
  }

  void _saveForm() {
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande enregistrée'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Bar
          _buildTopBar(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card
                  _buildHeroCard(),
                  const SizedBox(height: 14),

                  // Admissions Card - only show if no patient is pre-selected
                  if (!_hasPreselectedPatient) ...[
                    _buildAdmissionsCard(),
                    const SizedBox(height: 14),
                  ],

                  // Form Card
                  _buildFormCard(),
                ],
              ),
            ),
          ),

          // Bottom Navigation
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
              // Brand
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

              // Back button
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
          // Decorative shape
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

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
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

  Widget _buildAdmissionsCard() {
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

          // Admission List
          ...List.generate(_admissions.length, (index) {
            final admission = _admissions[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index < _admissions.length - 1 ? 10 : 0),
              child: _AdmissionItem(
                admission: admission,
                onChoose: () => _selectPatient(admission),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Bar
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
                        _selectedPatient,
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
                      _selectedDossier,
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

          // Decision Select
          _FormField(
            label: 'Décision opératoire',
            isRequired: true,
            child: _Dropdown(
              value: _selectedDecision,
              items: ['À valider', 'Opérer', 'Reporter', 'Annuler'],
              onChanged: (value) => setState(() => _selectedDecision = value!),
            ),
          ),
          const SizedBox(height: 12),

          // Diagnostic Input
          _FormField(
            label: 'Diagnostic / Motif',
            isRequired: true,
            child: _TextInput(controller: _diagnosticController),
          ),
          const SizedBox(height: 12),

          // Geste Input
          _FormField(
            label: 'Geste demandé',
            isRequired: true,
            child: _TextInput(controller: _gesteController),
          ),
          const SizedBox(height: 12),

          // Priority and Duration Row
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Priorité',
                  isRequired: true,
                  child: _Dropdown(
                    value: _selectedPriority,
                    items: ['Urgence', 'Semi-urgent', 'Programmé'],
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
                    items: ['45 min', '60 min', '90 min'],
                    onChanged: (value) => setState(() => _selectedDuration = value!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Notes
          _FormField(
            label: 'Notes',
            isRequired: false,
            child: _TextAreaInput(controller: _notesController),
          ),
          const SizedBox(height: 12),

          // Prerequisites
          _FormField(
            label: 'Pré-requis (à compléter avant anesthésie)',
            isRequired: false,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$_completedPrerequisites/${_prerequisites.length} complétés',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            child: Column(
              children: List.generate(_prerequisites.length, (index) {
                final prereq = _prerequisites[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index < _prerequisites.length - 1 ? 10 : 0),
                  child: _PrerequisiteTile(
                    item: prereq,
                    onTap: () => _togglePrerequisite(index),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Buttons
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
                  onTap: _saveForm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
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

// Data Models

enum ChipType { todo, wait, ok, risk }

enum PrerequisStatus { ok, wait, todo }

class _ChipData {
  final String label;
  final ChipType type;

  _ChipData(this.label, this.type);
}

class _AdmissionData {
  final String initials;
  final String name;
  final String time;
  final String dossier;
  final List<_ChipData> chips;
  final String diagnostic;
  final String geste;

  _AdmissionData({
    required this.initials,
    required this.name,
    required this.time,
    required this.dossier,
    required this.chips,
    required this.diagnostic,
    required this.geste,
  });
}

class _PrerequisItem {
  final String name;
  final PrerequisStatus status;
  bool isChecked;

  _PrerequisItem({
    required this.name,
    required this.status,
    required this.isChecked,
  });
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

class _AdmissionItem extends StatelessWidget {
  final _AdmissionData admission;
  final VoidCallback onChoose;

  const _AdmissionItem({
    required this.admission,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
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
              admission.initials,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        admission.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      admission.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: 'Dossier ${admission.dossier}'),
                    ...admission.chips.map((chip) => _StatusChip(
                      label: chip.label,
                      type: chip.type,
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Choose Button
          GestureDetector(
            onTap: onChoose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Choisir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
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

class _PrerequisiteTile extends StatelessWidget {
  final _PrerequisItem item;
  final VoidCallback onTap;

  const _PrerequisiteTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: item.isChecked ? AppColors.primaryDark : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: item.isChecked ? AppColors.primaryDark : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: item.isChecked
                      ? Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          _PrerequisStatusChip(status: item.status),
        ],
      ),
    );
  }
}

class _PrerequisStatusChip extends StatelessWidget {
  final PrerequisStatus status;

  const _PrerequisStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, borderColor, textColor) = _getStyle();

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

  (String, Color, Color, Color) _getStyle() {
    switch (status) {
      case PrerequisStatus.ok:
        return (
          'OK',
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          const Color(0xFF065F46),
        );
      case PrerequisStatus.wait:
        return (
          'En attente',
          const Color(0xFFFFF7ED),
          const Color(0xFFFED7AA),
          const Color(0xFF9A3412),
        );
      case PrerequisStatus.todo:
        return (
          'À faire',
          const Color(0xFFF1F5F9),
          const Color(0xFFE2E8F0),
          const Color(0xFF0F172A),
        );
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0B1220),
        ),
      ),
    );
  }
}

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
        return (
          const Color(0xFFF1F5F9),
          const Color(0xFFE2E8F0),
          const Color(0xFF0F172A),
        );
      case ChipType.wait:
        return (
          const Color(0xFFFFF7ED),
          const Color(0xFFFED7AA),
          const Color(0xFF9A3412),
        );
      case ChipType.ok:
        return (
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          const Color(0xFF065F46),
        );
      case ChipType.risk:
        return (
          const Color(0xFFFEF2F2),
          const Color(0xFFFECACA),
          const Color(0xFF991B1B),
        );
    }
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
