import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/patient.dart';
import '../../../models/hospital_case.dart';
import '../../../services/patient_repository.dart';
import '../../../services/hospital_case_repository.dart';

/// State for patient management
class PatientState {
  final List<Patient> patients;
  final Map<String, HospitalCase?> patientCases;
  final bool isLoading;
  final String? error;

  const PatientState({
    this.patients = const [],
    this.patientCases = const {},
    this.isLoading = false,
    this.error,
  });

  PatientState copyWith({
    List<Patient>? patients,
    Map<String, HospitalCase?>? patientCases,
    bool? isLoading,
    String? error,
  }) {
    return PatientState(
      patients: patients ?? this.patients,
      patientCases: patientCases ?? this.patientCases,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get patients with their current cases
  List<(Patient, HospitalCase?)> get patientsWithCases {
    return patients.map((p) => (p, patientCases[p.id])).toList();
  }
}

/// Patient management notifier
class PatientNotifier extends StateNotifier<PatientState> {
  PatientNotifier() : super(const PatientState()) {
    loadPatients();
  }

  final PatientRepository _patientRepository = PatientRepository();
  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();

  /// Load all patients and their active cases
  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final patients = await _patientRepository.getAllPatients();

      // Load active cases for each patient
      final Map<String, HospitalCase?> patientCases = {};
      for (final patient in patients) {
        final cases = await _caseRepository.getCasesByPatientId(patient.id);
        // Get the most recent active case
        final activeCase = cases.where((c) => c.isActive).firstOrNull;
        patientCases[patient.id] = activeCase;
      }

      state = state.copyWith(
        patients: patients,
        patientCases: patientCases,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des patients: $e',
      );
    }
  }

  /// Create a new patient
  Future<String?> createPatient(Patient patient) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = await _patientRepository.createPatient(patient);
      await loadPatients();
      return id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création du patient: $e',
      );
      return null;
    }
  }

  /// Update a patient
  Future<bool> updatePatient(Patient patient) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _patientRepository.updatePatient(patient);
      await loadPatients();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour: $e',
      );
      return false;
    }
  }

  /// Delete a patient
  Future<bool> deletePatient(String patientId) async {
    try {
      await _patientRepository.deletePatient(patientId);
      await loadPatients();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Search patients
  Future<List<Patient>> searchPatients(String query) async {
    if (query.isEmpty) return state.patients;
    return _patientRepository.searchPatients(query);
  }

  /// Get patient by ID
  Future<Patient?> getPatientById(String patientId) async {
    return _patientRepository.getPatientById(patientId);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for patient management
final patientProvider =
    StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  return PatientNotifier();
});

/// Provider for a single patient by ID
final patientByIdProvider = FutureProvider.family<Patient?, String>((ref, patientId) async {
  final patientRepository = PatientRepository();
  return await patientRepository.getPatientById(patientId);
});

/// Provider for recent patients
final recentPatientsProvider = FutureProvider<List<Patient>>((ref) async {
  final patientRepository = PatientRepository();
  return await patientRepository.getRecentPatients(limit: 5);
});
