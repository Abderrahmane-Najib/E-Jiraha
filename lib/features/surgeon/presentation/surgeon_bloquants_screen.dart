import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SurgeonBloquantsScreen extends ConsumerStatefulWidget {
  const SurgeonBloquantsScreen({super.key});

  @override
  ConsumerState<SurgeonBloquantsScreen> createState() =>
      _SurgeonBloquantsScreenState();
}

class _SurgeonBloquantsScreenState extends ConsumerState<SurgeonBloquantsScreen> {
  int _selectedFilterIndex = 0;

  final List<_FilterOption> _filters = [
    _FilterOption('Tous', 3),
    _FilterOption('Biologie', null),
    _FilterOption('Consentement', null),
    _FilterOption('Anesthésie', null),
  ];

  final List<_BloquantPatient> _patients = [
    _BloquantPatient(
      initials: 'RM',
      name: 'Mr. Rachid M.',
      blockingReason: 'Bio manquante',
      dossier: 'Dossier #CHU-03214',
      chips: [
        _ChipData('NFS / CRP', ChipType.wait),
        _ChipData('Demande', ChipType.todo),
      ],
      hint: 'Dernière mise à jour par infirmière (il y a 15 min)',
    ),
    _BloquantPatient(
      initials: 'SA',
      name: 'Mrs. Sara A.',
      blockingReason: 'Consentement',
      dossier: 'Dossier #CHU-03188',
      chips: [
        _ChipData('Allergies à vérifier', ChipType.risk),
      ],
      hint: 'Patient signalé par anesthésie (il y a 1 h)',
    ),
    _BloquantPatient(
      initials: 'HL',
      name: 'Mr. Hamza L.',
      blockingReason: 'Avis anesthésie',
      dossier: 'Dossier #CHU-03102',
      chips: [
        _ChipData('Planning pré-anesthésie', ChipType.wait),
      ],
      hint: 'Patient transféré — attente créneau (il y a 3 h)',
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
                  // Hero Card with Orange Gradient
                  _buildHeroCard(),
                  const SizedBox(height: 12),

                  // Filter Chips
                  _buildFilterChips(),
                  const SizedBox(height: 12),

                  // Patient List
                  _buildPatientList(),
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
                    'Chirurgien • Dossiers bloquants',
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
          colors: [Color(0xFFF97316), Color(0xFFEA580C)], // Orange gradient
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dossiers bloquants',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Admissions stoppées par un pré-requis manquant (bio, consentement, anesthésie…)',
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
                  color: isActive ? const Color(0xFFFFF7ED) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFFDBA74)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  filter.count != null ? '${filter.label} (${filter.count})' : filter.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isActive ? const Color(0xFF9A3412) : AppColors.textSecondary,
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
        child: _BloquantPatientCard(
          patient: patient,
          onTap: () => context.push('/surgeon/patient/1'),
        ),
      )).toList(),
    );
  }
}

class _FilterOption {
  final String label;
  final int? count;

  _FilterOption(this.label, this.count);
}

class _BloquantPatient {
  final String initials;
  final String name;
  final String blockingReason;
  final String dossier;
  final List<_ChipData> chips;
  final String hint;

  _BloquantPatient({
    required this.initials,
    required this.name,
    required this.blockingReason,
    required this.dossier,
    required this.chips,
    required this.hint,
  });
}

enum ChipType { todo, wait, ok, risk }

class _ChipData {
  final String label;
  final ChipType type;

  _ChipData(this.label, this.type);
}

class _BloquantPatientCard extends StatelessWidget {
  final _BloquantPatient patient;
  final VoidCallback onTap;

  const _BloquantPatientCard({
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
            // Avatar with Orange Color
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.25)),
              ),
              alignment: Alignment.center,
              child: Text(
                patient.initials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFC2410C),
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
                        patient.blockingReason,
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
                  const SizedBox(height: 8),
                  Text(
                    patient.hint,
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
          const Color(0xFFFEF3C7), // Yellow-ish for bloquants
          const Color(0xFFFCD34D),
          const Color(0xFF92400E),
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
