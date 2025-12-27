import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/patient_card.dart';
import '../../../models/patient.dart';
import '../../../models/hospital_case.dart';
import '../../../routing/app_router.dart';

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data
  final List<(Patient, HospitalCase?)> _allPatients = [
    (
      Patient(
        id: '1',
        fullName: 'Amina Mansouri',
        cin: 'AB123456',
        gender: Gender.female,
        dateOfBirth: DateTime(1985, 3, 15),
        address: '123 Rue Hassan II, Casablanca',
        phone: '0612345678',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_secretary',
      ),
      HospitalCase(
        id: 'case1',
        patientId: '1',
        service: 'Chirurgie Générale',
        entryMode: EntryMode.scheduled,
        status: CaseStatus.admission,
        entryDate: DateTime.now(),
        roomNumber: '201',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_secretary',
      ),
    ),
    (
      Patient(
        id: '2',
        fullName: 'Mohamed Alami',
        cin: 'CD789012',
        gender: Gender.male,
        dateOfBirth: DateTime(1972, 8, 22),
        address: '45 Avenue Mohammed V, Rabat',
        phone: '0698765432',
        allergies: ['Pénicilline'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_secretary',
      ),
      HospitalCase(
        id: 'case2',
        patientId: '2',
        service: 'Chirurgie Générale',
        entryMode: EntryMode.emergency,
        status: CaseStatus.preop,
        entryDate: DateTime.now().subtract(const Duration(days: 1)),
        roomNumber: '105',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_secretary',
      ),
    ),
    (
      Patient(
        id: '3',
        fullName: 'Fatima Benali',
        cin: 'EF345678',
        gender: Gender.female,
        dateOfBirth: DateTime(1990, 11, 5),
        address: '78 Boulevard Zerktouni, Marrakech',
        phone: '0655443322',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_secretary',
      ),
      HospitalCase(
        id: 'case3',
        patientId: '3',
        service: 'Chirurgie Générale',
        entryMode: EntryMode.scheduled,
        status: CaseStatus.consultation,
        entryDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_secretary',
      ),
    ),
    (
      Patient(
        id: '4',
        fullName: 'Youssef Benjelloun',
        cin: 'GH901234',
        gender: Gender.male,
        dateOfBirth: DateTime(1965, 5, 18),
        address: '12 Rue Moulay Ismail, Fès',
        phone: '0666778899',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_secretary',
      ),
      null,
    ),
    (
      Patient(
        id: '5',
        fullName: 'Khadija Ouazzani',
        cin: 'IJ567890',
        gender: Gender.female,
        dateOfBirth: DateTime(1995, 9, 30),
        address: '56 Avenue Hassan II, Tanger',
        phone: '0677889900',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_secretary',
      ),
      HospitalCase(
        id: 'case5',
        patientId: '5',
        service: 'Chirurgie Générale',
        entryMode: EntryMode.scheduled,
        status: CaseStatus.postop,
        entryDate: DateTime.now().subtract(const Duration(days: 3)),
        roomNumber: '302',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_secretary',
      ),
    ),
  ];

  List<(Patient, HospitalCase?)> get _filteredPatients {
    if (_searchQuery.isEmpty) return _allPatients;
    return _allPatients.where((item) {
      final patient = item.$1;
      final query = _searchQuery.toLowerCase();
      return patient.fullName.toLowerCase().contains(query) ||
          patient.cin.toLowerCase().contains(query) ||
          patient.phone.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, size: 18),
          ),
          onPressed: () => context.go(AppRoutes.secretaryDashboard),
        ),
        title: Text(
          AppStrings.patientList,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showFilterDialog(context);
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: AppStrings.searchPatient,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredPatients.length} patient(s) trouvé(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Patient List
          Expanded(
            child: _filteredPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.noData,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPatients.length,
                    itemBuilder: (context, index) {
                      final (patient, hospitalCase) = _filteredPatients[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PatientCard(
                          patient: patient,
                          currentCase: hospitalCase,
                          onTap: () {
                            _showPatientDetails(context, patient, hospitalCase);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.newPatient),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrer par',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected: true,
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Admission'),
                  selected: false,
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Pré-op'),
                  selected: false,
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Post-op'),
                  selected: false,
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Urgence'),
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Appliquer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPatientDetails(
    BuildContext context,
    Patient patient,
    HospitalCase? hospitalCase,
  ) {
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
                        patient.initials,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
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
                          patient.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          'CIN: ${patient.cin}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailItem(
                icon: Icons.cake_outlined,
                label: 'Âge',
                value: '${patient.age} ans',
              ),
              _DetailItem(
                icon: patient.gender == Gender.male
                    ? Icons.male
                    : Icons.female,
                label: 'Sexe',
                value: patient.gender.label,
              ),
              _DetailItem(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: patient.phone,
              ),
              _DetailItem(
                icon: Icons.location_on_outlined,
                label: 'Adresse',
                value: patient.address,
              ),
              if (patient.allergies.isNotEmpty)
                _DetailItem(
                  icon: Icons.warning_amber,
                  label: 'Allergies',
                  value: patient.allergies.join(', '),
                  isWarning: true,
                ),
              if (hospitalCase != null) ...[
                const Divider(height: 32),
                Text(
                  'Dossier actuel',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                _DetailItem(
                  icon: Icons.medical_services_outlined,
                  label: 'Statut',
                  value: hospitalCase.status.label,
                ),
                _DetailItem(
                  icon: Icons.login,
                  label: 'Mode d\'entrée',
                  value: hospitalCase.entryMode.label,
                ),
                if (hospitalCase.roomNumber != null)
                  _DetailItem(
                    icon: Icons.bed_outlined,
                    label: 'Chambre',
                    value: hospitalCase.roomNumber!,
                  ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Dossier'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isWarning ? AppColors.warning : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isWarning ? AppColors.warning : null,
                    fontWeight: isWarning ? FontWeight.w600 : null,
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
