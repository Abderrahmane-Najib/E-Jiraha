import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SurgeonDecisionsScreen extends ConsumerStatefulWidget {
  const SurgeonDecisionsScreen({super.key});

  @override
  ConsumerState<SurgeonDecisionsScreen> createState() =>
      _SurgeonDecisionsScreenState();
}

class _SurgeonDecisionsScreenState extends ConsumerState<SurgeonDecisionsScreen> {
  int _selectedFilterIndex = 0;

  final List<_FilterOption> _filters = [
    _FilterOption('Toutes', 6),
    _FilterOption('À décider', 3),
    _FilterOption('À compléter', 2),
    _FilterOption('En cours', 1),
  ];

  final List<_PatientData> _patients = [
    _PatientData(
      initials: 'RM',
      name: 'Mr. Rachid M.',
      time: '11:05',
      dossier: 'Dossier #CHU-03214',
      chips: [
        _ChipData('Décision', ChipType.todo),
        _ChipData('Bio manquante', ChipType.wait),
      ],
    ),
    _PatientData(
      initials: 'SA',
      name: 'Mrs. Sara A.',
      time: '10:20',
      dossier: 'Dossier #CHU-03188',
      chips: [
        _ChipData('Décision', ChipType.todo),
        _ChipData('Allergies', ChipType.risk),
      ],
    ),
    _PatientData(
      initials: 'HL',
      name: 'Mr. Hamza L.',
      time: '09:45',
      dossier: 'Dossier #CHU-03102',
      chips: [
        _ChipData('Décision', ChipType.todo),
        _ChipData('Imagerie OK', ChipType.ok),
      ],
    ),
  ];

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
                  const SizedBox(height: 12),

                  // Filter Chips
                  _buildFilterChips(),
                  const SizedBox(height: 12),

                  // Patient List
                  _buildPatientList(),
                  const SizedBox(height: 12),

                  // CTA Link
                  _buildCtaLink(),
                ],
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
                    'Chirurgien • Décisions',
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
          colors: [Color(0xFF0F766E), Color(0xFF0B5450)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Décisions à valider',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Admissions nécessitant une décision opératoire ou une validation de demande.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final filter = _filters[index];
          final isActive = _selectedFilterIndex == index;

          return Padding(
            padding: EdgeInsets.only(right: index < _filters.length - 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primarySurface : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  '${filter.label} (${filter.count})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPatientList() {
    return Column(
      children: _patients.map((patient) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _PatientCard(
          patient: patient,
          onTap: () => context.push('/surgeon/patient/1'),
        ),
      )).toList(),
    );
  }

  Widget _buildCtaLink() {
    return GestureDetector(
      onTap: () => context.push('/surgeon/patients'),
      child: Row(
        children: [
          Text(
            'Voir tous les patients',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '→',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final int count;

  _FilterOption(this.label, this.count);
}

class _PatientData {
  final String initials;
  final String name;
  final String time;
  final String dossier;
  final List<_ChipData> chips;

  _PatientData({
    required this.initials,
    required this.name,
    required this.time,
    required this.dossier,
    required this.chips,
  });
}

enum ChipType { todo, wait, ok, risk }

class _ChipData {
  final String label;
  final ChipType type;

  _ChipData(this.label, this.type);
}

class _PatientCard extends StatelessWidget {
  final _PatientData patient;
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
        padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                patient.initials,
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
                          patient.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        patient.time,
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
                      _Pill(label: patient.dossier),
                      ...patient.chips.map((chip) => _StatusChip(
                        label: chip.label,
                        type: chip.type,
                      )),
                    ],
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
