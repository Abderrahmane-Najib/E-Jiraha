import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/hospital_case.dart';
import '../providers/surgeon_provider.dart';

class SurgeonPatientsScreen extends ConsumerStatefulWidget {
  const SurgeonPatientsScreen({super.key});

  @override
  ConsumerState<SurgeonPatientsScreen> createState() =>
      _SurgeonPatientsScreenState();
}

class _SurgeonPatientsScreenState extends ConsumerState<SurgeonPatientsScreen> {
  int _selectedNavIndex = 1;
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(surgeonPatientsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Bar
          _buildTopBar(),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(surgeonPatientsProvider.notifier).loadPatients();
              },
              child: patientsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : patientsState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                patientsState.error!,
                                style: TextStyle(color: AppColors.error),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(surgeonPatientsProvider.notifier)
                                    .loadPatients(),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchBar(),
                              const SizedBox(height: 12),
                              _buildFilterChips(patientsState),
                              const SizedBox(height: 12),
                              _buildPatientList(patientsState),
                            ],
                          ),
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
                    'Chirurgien • Patients',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _IconButton(
                icon: Icons.chevron_left,
                onTap: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Recherche: Nom, N° dossier, CIN',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(SurgeonPatientsState state) {
    final filters = [
      _FilterOption('Tous', state.patients.length),
      _FilterOption('Consultation', state.patients.where((p) =>
          p.hospitalCase.status == CaseStatus.consultation).length),
      _FilterOption('Pré-op', state.patients.where((p) =>
          p.hospitalCase.status == CaseStatus.preop).length),
      _FilterOption('En bloc', state.patients.where((p) =>
          p.hospitalCase.status == CaseStatus.surgery).length),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final isActive = _selectedFilterIndex == index;

          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 10 : 0),
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
                child: Row(
                  children: [
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        filter.count.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0B1220),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPatientList(SurgeonPatientsState state) {
    if (state.patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun patient',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filter patients based on selected filter
    List<SurgeryRequestData> filteredPatients;
    switch (_selectedFilterIndex) {
      case 1:
        filteredPatients = state.patients.where((p) =>
            p.hospitalCase.status == CaseStatus.consultation).toList();
        break;
      case 2:
        filteredPatients = state.patients.where((p) =>
            p.hospitalCase.status == CaseStatus.preop).toList();
        break;
      case 3:
        filteredPatients = state.patients.where((p) =>
            p.hospitalCase.status == CaseStatus.surgery).toList();
        break;
      default:
        filteredPatients = state.patients;
    }

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filteredPatients = filteredPatients.where((p) {
        final patientName = p.patient?.fullName.toLowerCase() ?? '';
        final caseId = p.hospitalCase.id.toLowerCase();
        return patientName.contains(searchQuery) || caseId.contains(searchQuery);
      }).toList();
    }

    return Column(
      children: filteredPatients.map((data) {
        final patient = data.patient;
        final hospitalCase = data.hospitalCase;
        final patientName = patient?.fullName ?? 'Patient inconnu';
        final initials = _getInitials(patientName);
        final isUrgent = hospitalCase.entryMode == EntryMode.emergency;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PatientCard(
            initials: initials,
            name: patientName,
            time: isUrgent ? 'Urgence' : _getEntryType(hospitalCase.entryMode),
            dossier: 'Dossier #${hospitalCase.id.substring(0, 8).toUpperCase()}',
            status: hospitalCase.status,
            onTap: () => context.push('/surgeon/patient/${hospitalCase.id}'),
          ),
        );
      }).toList(),
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
                isActive: _selectedNavIndex == 0,
                onTap: () {
                  setState(() => _selectedNavIndex = 0);
                  context.go('/surgeon');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NavButton(
                label: 'Patients',
                isActive: _selectedNavIndex == 1,
                onTap: () => setState(() => _selectedNavIndex = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final int count;

  _FilterOption(this.label, this.count);
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.primary),
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

class _PatientCard extends StatelessWidget {
  final String initials;
  final String name;
  final String time;
  final String dossier;
  final CaseStatus status;
  final VoidCallback onTap;

  const _PatientCard({
    required this.initials,
    required this.name,
    required this.time,
    required this.dossier,
    required this.status,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(label: dossier),
                      _StatusChip(status: status),
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0B1220),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final CaseStatus status;

  const _StatusChip({required this.status});

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
      case CaseStatus.admission:
        return ('Admission', const Color(0xFFF1F5F9), const Color(0xFFE2E8F0), const Color(0xFF0F172A));
      case CaseStatus.consultation:
        return ('Consultation', const Color(0xFFFFF7ED), const Color(0xFFFED7AA), const Color(0xFF9A3412));
      case CaseStatus.preop:
        return ('Pré-op', const Color(0xFFECFDF5), const Color(0xFFA7F3D0), const Color(0xFF065F46));
      case CaseStatus.surgery:
        return ('En bloc', const Color(0xFFEFF6FF), const Color(0xFFBFDBFE), const Color(0xFF1E40AF));
      case CaseStatus.postop:
        return ('Post-op', const Color(0xFFF5F3FF), const Color(0xFFDDD6FE), const Color(0xFF5B21B6));
      case CaseStatus.discharge:
        return ('Sortie', const Color(0xFFFFF7ED), const Color(0xFFFED7AA), const Color(0xFF9A3412));
      case CaseStatus.completed:
        return ('Terminé', const Color(0xFFECFDF5), const Color(0xFFA7F3D0), const Color(0xFF065F46));
      case CaseStatus.cancelled:
        return ('Annulé', const Color(0xFFFEF2F2), const Color(0xFFFECACA), const Color(0xFF991B1B));
    }
  }
}
