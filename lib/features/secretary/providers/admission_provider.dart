import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/hospital_case.dart';
import '../../../models/patient.dart';
import '../../../services/hospital_case_repository.dart';
import '../../../services/patient_repository.dart';

/// Admission data with patient info
class AdmissionData {
  final HospitalCase hospitalCase;
  final Patient? patient;

  const AdmissionData({
    required this.hospitalCase,
    this.patient,
  });
}

/// State for admission management
class AdmissionState {
  final List<AdmissionData> admissions;
  final List<AdmissionData> todayAdmissions;
  final bool isLoading;
  final String? error;

  const AdmissionState({
    this.admissions = const [],
    this.todayAdmissions = const [],
    this.isLoading = false,
    this.error,
  });

  AdmissionState copyWith({
    List<AdmissionData>? admissions,
    List<AdmissionData>? todayAdmissions,
    bool? isLoading,
    String? error,
  }) {
    return AdmissionState(
      admissions: admissions ?? this.admissions,
      todayAdmissions: todayAdmissions ?? this.todayAdmissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Admission management notifier
class AdmissionNotifier extends StateNotifier<AdmissionState> {
  AdmissionNotifier() : super(const AdmissionState()) {
    loadAdmissions();
  }

  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();

  /// Load all admissions with patient data
  Future<void> loadAdmissions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get active cases
      final cases = await _caseRepository.getActiveCases();
      final todayCases = await _caseRepository.getTodayAdmissions();

      // Load patient data for each case
      final admissions = await Future.wait(
        cases.map((c) async {
          final patient = await _patientRepository.getPatientById(c.patientId);
          return AdmissionData(hospitalCase: c, patient: patient);
        }),
      );

      final todayAdmissions = await Future.wait(
        todayCases.map((c) async {
          final patient = await _patientRepository.getPatientById(c.patientId);
          return AdmissionData(hospitalCase: c, patient: patient);
        }),
      );

      state = state.copyWith(
        admissions: admissions,
        todayAdmissions: todayAdmissions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des admissions: $e',
      );
    }
  }

  /// Create a new admission (hospital case)
  Future<String?> createAdmission(HospitalCase hospitalCase) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = await _caseRepository.createCase(hospitalCase);
      await loadAdmissions();
      return id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création de l\'admission: $e',
      );
      return null;
    }
  }

  /// Update admission
  Future<bool> updateAdmission(HospitalCase hospitalCase) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _caseRepository.updateCase(hospitalCase);
      await loadAdmissions();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour: $e',
      );
      return false;
    }
  }

  /// Update case status
  Future<bool> updateCaseStatus(String caseId, CaseStatus status) async {
    try {
      await _caseRepository.updateCaseStatus(caseId, status);
      await loadAdmissions();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  /// Delete admission
  Future<bool> deleteAdmission(String caseId) async {
    try {
      await _caseRepository.deleteCase(caseId);
      await loadAdmissions();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Get cases by status
  Future<List<HospitalCase>> getCasesByStatus(CaseStatus status) async {
    return _caseRepository.getCasesByStatus(status);
  }

  /// Get cases by patient
  Future<List<HospitalCase>> getCasesByPatient(String patientId) async {
    return _caseRepository.getCasesByPatientId(patientId);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for admission management
final admissionProvider =
    StateNotifierProvider<AdmissionNotifier, AdmissionState>((ref) {
  return AdmissionNotifier();
});

/// Provider for a single case by ID
final caseByIdProvider = FutureProvider.family<HospitalCase?, String>((ref, caseId) async {
  final caseRepository = HospitalCaseRepository();
  return await caseRepository.getCaseById(caseId);
});

/// Provider for cases by status
final casesByStatusProvider = FutureProvider.family<List<HospitalCase>, CaseStatus>((ref, status) async {
  final caseRepository = HospitalCaseRepository();
  return await caseRepository.getCasesByStatus(status);
});

/// Provider for cases by patient
final casesByPatientProvider = FutureProvider.family<List<HospitalCase>, String>((ref, patientId) async {
  final caseRepository = HospitalCaseRepository();
  return await caseRepository.getCasesByPatientId(patientId);
});
