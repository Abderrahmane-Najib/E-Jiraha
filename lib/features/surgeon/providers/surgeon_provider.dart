import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/hospital_case.dart';
import '../../../models/patient.dart';
import '../../../models/surgery.dart';
import '../../../services/hospital_case_repository.dart';
import '../../../services/patient_repository.dart';
import '../../../services/surgery_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Surgery request data with patient info
class SurgeryRequestData {
  final HospitalCase hospitalCase;
  final Patient? patient;
  final Surgery? surgery;

  const SurgeryRequestData({
    required this.hospitalCase,
    this.patient,
    this.surgery,
  });
}

/// State for surgeon patients list
class SurgeonPatientsState {
  final List<SurgeryRequestData> patients;
  final List<SurgeryRequestData> todayPatients;
  final bool isLoading;
  final String? error;

  const SurgeonPatientsState({
    this.patients = const [],
    this.todayPatients = const [],
    this.isLoading = false,
    this.error,
  });

  SurgeonPatientsState copyWith({
    List<SurgeryRequestData>? patients,
    List<SurgeryRequestData>? todayPatients,
    bool? isLoading,
    String? error,
  }) {
    return SurgeonPatientsState(
      patients: patients ?? this.patients,
      todayPatients: todayPatients ?? this.todayPatients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Surgeon patients notifier
class SurgeonPatientsNotifier extends StateNotifier<SurgeonPatientsState> {
  final String? surgeonId;

  SurgeonPatientsNotifier(this.surgeonId) : super(const SurgeonPatientsState()) {
    loadPatients();
  }

  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();
  final SurgeryRepository _surgeryRepository = SurgeryRepository();

  /// Load all patients for surgeon
  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get active cases (preop and surgery status)
      final preopCases = await _caseRepository.getCasesByStatus(CaseStatus.preop);
      final surgeryCases = await _caseRepository.getCasesByStatus(CaseStatus.surgery);
      final consultationCases = await _caseRepository.getCasesByStatus(CaseStatus.consultation);
      final admissionCases = await _caseRepository.getCasesByStatus(CaseStatus.admission);

      var allCases = [...admissionCases, ...consultationCases, ...preopCases, ...surgeryCases];

      // Filter by assigned surgeon if surgeonId is provided
      if (surgeonId != null && surgeonId!.isNotEmpty) {
        allCases = allCases.where((c) => c.responsibleDoctorId == surgeonId).toList();
      }

      // Load patient and surgery data for each case
      final patients = await Future.wait(
        allCases.map((c) async {
          final patient = await _patientRepository.getPatientById(c.patientId);
          final surgeries = await _surgeryRepository.getSurgeriesByCaseId(c.id);
          final surgery = surgeries.isNotEmpty ? surgeries.first : null;
          return SurgeryRequestData(
            hospitalCase: c,
            patient: patient,
            surgery: surgery,
          );
        }),
      );

      // Filter today's patients
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayPatients = patients.where((p) {
        final entryDate = p.hospitalCase.entryDate;
        return entryDate.year == today.year &&
               entryDate.month == today.month &&
               entryDate.day == today.day;
      }).toList();

      state = state.copyWith(
        patients: patients,
        todayPatients: todayPatients,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for surgeon patients (filtered by current surgeon)
final surgeonPatientsProvider =
    StateNotifierProvider<SurgeonPatientsNotifier, SurgeonPatientsState>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return SurgeonPatientsNotifier(currentUser?.id);
});

/// State for decisions pending validation
class DecisionsState {
  final List<SurgeryRequestData> pendingDecisions;
  final bool isLoading;
  final String? error;

  const DecisionsState({
    this.pendingDecisions = const [],
    this.isLoading = false,
    this.error,
  });

  DecisionsState copyWith({
    List<SurgeryRequestData>? pendingDecisions,
    bool? isLoading,
    String? error,
  }) {
    return DecisionsState(
      pendingDecisions: pendingDecisions ?? this.pendingDecisions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Decisions notifier
class DecisionsNotifier extends StateNotifier<DecisionsState> {
  final String? surgeonId;

  DecisionsNotifier(this.surgeonId) : super(const DecisionsState()) {
    loadPendingDecisions();
  }

  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();
  final SurgeryRepository _surgeryRepository = SurgeryRepository();

  /// Load pending decisions (admission cases assigned to this surgeon)
  Future<void> loadPendingDecisions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Cases in admission need surgeon decision
      final admissionCases = await _caseRepository.getCasesByStatus(CaseStatus.admission);

      // Filter by assigned surgeon
      var filteredCases = admissionCases;
      if (surgeonId != null && surgeonId!.isNotEmpty) {
        filteredCases = admissionCases.where((c) => c.responsibleDoctorId == surgeonId).toList();
      }

      final pendingDecisions = await Future.wait(
        filteredCases.map((c) async {
          final patient = await _patientRepository.getPatientById(c.patientId);
          return SurgeryRequestData(
            hospitalCase: c,
            patient: patient,
          );
        }),
      );

      state = state.copyWith(
        pendingDecisions: pendingDecisions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Approve surgery decision
  Future<bool> approveDecision(String caseId, Surgery surgery) async {
    try {
      // Create surgery record
      await _surgeryRepository.createSurgery(surgery);
      // Update case status to consultation (nurse will see in triage queue)
      await _caseRepository.updateCaseStatus(caseId, CaseStatus.consultation);
      await loadPendingDecisions();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
      return false;
    }
  }

  /// Reject surgery decision
  Future<bool> rejectDecision(String caseId, String reason) async {
    try {
      // Update case status to cancelled
      await _caseRepository.updateCaseStatus(caseId, CaseStatus.cancelled);
      await loadPendingDecisions();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for decisions (filtered by current surgeon)
final decisionsProvider =
    StateNotifierProvider<DecisionsNotifier, DecisionsState>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return DecisionsNotifier(currentUser?.id);
});

/// State for blocking issues
class BloquantsState {
  final List<SurgeryRequestData> bloquants;
  final bool isLoading;
  final String? error;

  const BloquantsState({
    this.bloquants = const [],
    this.isLoading = false,
    this.error,
  });

  BloquantsState copyWith({
    List<SurgeryRequestData>? bloquants,
    bool? isLoading,
    String? error,
  }) {
    return BloquantsState(
      bloquants: bloquants ?? this.bloquants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Bloquants notifier
class BloquantsNotifier extends StateNotifier<BloquantsState> {
  final String? surgeonId;

  BloquantsNotifier(this.surgeonId) : super(const BloquantsState()) {
    loadBloquants();
  }

  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();

  /// Load cases with blocking issues
  Future<void> loadBloquants() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get preop cases that might have blockers
      final preopCases = await _caseRepository.getCasesByStatus(CaseStatus.preop);

      // Filter by assigned surgeon
      var filteredCases = preopCases;
      if (surgeonId != null && surgeonId!.isNotEmpty) {
        filteredCases = preopCases.where((c) => c.responsibleDoctorId == surgeonId).toList();
      }

      // Filter cases with missing documents or blockers
      final bloquants = await Future.wait(
        filteredCases.where((c) => c.notes?.contains('bloquant') == true || c.notes?.contains('manquant') == true).map((c) async {
          final patient = await _patientRepository.getPatientById(c.patientId);
          return SurgeryRequestData(
            hospitalCase: c,
            patient: patient,
          );
        }),
      );

      state = state.copyWith(
        bloquants: bloquants,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for bloquants (filtered by current surgeon)
final bloquantsProvider =
    StateNotifierProvider<BloquantsNotifier, BloquantsState>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return BloquantsNotifier(currentUser?.id);
});

/// Provider for dashboard stats
class SurgeonDashboardStats {
  final int decisionsCount;
  final int bloquantsCount;
  final int todayPatientsCount;

  const SurgeonDashboardStats({
    this.decisionsCount = 0,
    this.bloquantsCount = 0,
    this.todayPatientsCount = 0,
  });
}

final surgeonDashboardStatsProvider = FutureProvider<SurgeonDashboardStats>((ref) async {
  final caseRepository = HospitalCaseRepository();
  final currentUser = ref.watch(currentUserProvider);
  final surgeonId = currentUser?.id;

  try {
    final admissionCases = await caseRepository.getCasesByStatus(CaseStatus.admission);
    final preopCases = await caseRepository.getCasesByStatus(CaseStatus.preop);

    // Filter by surgeon
    var filteredAdmissions = admissionCases;
    var filteredPreop = preopCases;
    if (surgeonId != null && surgeonId.isNotEmpty) {
      filteredAdmissions = admissionCases.where((c) => c.responsibleDoctorId == surgeonId).toList();
      filteredPreop = preopCases.where((c) => c.responsibleDoctorId == surgeonId).toList();
    }

    final bloquants = filteredPreop.where((c) => c.notes?.contains('bloquant') == true || c.notes?.contains('manquant') == true).length;

    // Today's admissions for this surgeon
    final todayCases = await caseRepository.getTodayAdmissions();
    var filteredTodayCases = todayCases;
    if (surgeonId != null && surgeonId.isNotEmpty) {
      filteredTodayCases = todayCases.where((c) => c.responsibleDoctorId == surgeonId).toList();
    }

    return SurgeonDashboardStats(
      decisionsCount: filteredAdmissions.length,
      bloquantsCount: bloquants,
      todayPatientsCount: filteredTodayCases.length,
    );
  } catch (e) {
    return const SurgeonDashboardStats();
  }
});

/// Provider for patient details
final patientDetailsProvider = FutureProvider.family<SurgeryRequestData?, String>((ref, caseId) async {
  final caseRepository = HospitalCaseRepository();
  final patientRepository = PatientRepository();
  final surgeryRepository = SurgeryRepository();

  try {
    final hospitalCase = await caseRepository.getCaseById(caseId);
    if (hospitalCase == null) return null;

    final patient = await patientRepository.getPatientById(hospitalCase.patientId);
    final surgeries = await surgeryRepository.getSurgeriesByCaseId(caseId);

    return SurgeryRequestData(
      hospitalCase: hospitalCase,
      patient: patient,
      surgery: surgeries.isNotEmpty ? surgeries.first : null,
    );
  } catch (e) {
    return null;
  }
});
