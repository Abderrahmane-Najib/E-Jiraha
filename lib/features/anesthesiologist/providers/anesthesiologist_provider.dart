import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/hospital_case.dart';
import '../../../models/patient.dart';
import '../../../models/anesthesia.dart';
import '../../../models/checklist.dart';
import '../../../services/hospital_case_repository.dart';
import '../../../services/patient_repository.dart';
import '../../../services/anesthesia_repository.dart';
import '../../../services/checklist_repository.dart';
import '../../../services/surgery_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Anesthesia consultation data with patient info
class AnesthesiaConsultationData {
  final HospitalCase hospitalCase;
  final Patient? patient;
  final AnesthesiaEvaluation? evaluation;
  final Checklist? preopChecklist;

  const AnesthesiaConsultationData({
    required this.hospitalCase,
    this.patient,
    this.evaluation,
    this.preopChecklist,
  });

  bool get hasEvaluation => evaluation != null;
  bool get isValidated => evaluation?.isValidated ?? false;
}

/// State for anesthesiologist triage queue
class AnesthesiaTriageState {
  final List<AnesthesiaConsultationData> triageQueue;
  final bool isLoading;
  final String? error;

  const AnesthesiaTriageState({
    this.triageQueue = const [],
    this.isLoading = false,
    this.error,
  });

  AnesthesiaTriageState copyWith({
    List<AnesthesiaConsultationData>? triageQueue,
    bool? isLoading,
    String? error,
  }) {
    return AnesthesiaTriageState(
      triageQueue: triageQueue ?? this.triageQueue,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Anesthesia triage notifier
class AnesthesiaTriageNotifier extends StateNotifier<AnesthesiaTriageState> {
  final String? anesthesiologistId;

  AnesthesiaTriageNotifier(this.anesthesiologistId) : super(const AnesthesiaTriageState()) {
    loadTriageQueue();
  }

  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();
  final AnesthesiaRepository _anesthesiaRepository = AnesthesiaRepository();
  final SurgeryRepository _surgeryRepository = SurgeryRepository();

  /// Load triage queue (preop cases needing anesthesia evaluation, assigned to this anesthesiologist)
  Future<void> loadTriageQueue() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get cases in preop status that need anesthesia evaluation
      var preopCases = await _caseRepository.getCasesByStatus(CaseStatus.preop);

      // Filter by assigned anesthesiologist if ID is provided
      if (anesthesiologistId != null && anesthesiologistId!.isNotEmpty) {
        final assignedCaseIds = <String>{};
        for (final c in preopCases) {
          final surgeries = await _surgeryRepository.getSurgeriesByCaseId(c.id);
          for (final surgery in surgeries) {
            if (surgery.anesthesiologistId == anesthesiologistId) {
              assignedCaseIds.add(c.id);
              break;
            }
          }
        }
        preopCases = preopCases.where((c) => assignedCaseIds.contains(c.id)).toList();
      }

      final triageQueue = await Future.wait(
        preopCases.map((c) async {
          final patient = await _patientRepository.getPatientById(c.patientId);
          final evaluation = await _anesthesiaRepository.getEvaluationByCaseId(c.id);
          return AnesthesiaConsultationData(
            hospitalCase: c,
            patient: patient,
            evaluation: evaluation,
          );
        }),
      );

      // Filter to show only those without completed evaluation
      final pendingQueue = triageQueue.where((d) => !d.isValidated).toList();

      state = state.copyWith(
        triageQueue: pendingQueue,
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

/// Provider for anesthesia triage queue (filtered by current anesthesiologist)
final anesthesiaTriageProvider =
    StateNotifierProvider<AnesthesiaTriageNotifier, AnesthesiaTriageState>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return AnesthesiaTriageNotifier(currentUser?.id);
});

/// State for anesthesia planning
class AnesthesiaPlanningState {
  final List<AnesthesiaConsultationData> planningList;
  final bool isLoading;
  final String? error;

  const AnesthesiaPlanningState({
    this.planningList = const [],
    this.isLoading = false,
    this.error,
  });

  AnesthesiaPlanningState copyWith({
    List<AnesthesiaConsultationData>? planningList,
    bool? isLoading,
    String? error,
  }) {
    return AnesthesiaPlanningState(
      planningList: planningList ?? this.planningList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Anesthesia planning notifier
class AnesthesiaPlanningNotifier extends StateNotifier<AnesthesiaPlanningState> {
  final String? anesthesiologistId;

  AnesthesiaPlanningNotifier(this.anesthesiologistId) : super(const AnesthesiaPlanningState()) {
    loadPlanning();
  }

  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();
  final AnesthesiaRepository _anesthesiaRepository = AnesthesiaRepository();
  final ChecklistRepository _checklistRepository = ChecklistRepository();
  final SurgeryRepository _surgeryRepository = SurgeryRepository();

  /// Load planning (cases cleared for surgery, assigned to this anesthesiologist)
  Future<void> loadPlanning() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get cases in preop and surgery status
      final preopCases = await _caseRepository.getCasesByStatus(CaseStatus.preop);
      final surgeryCases = await _caseRepository.getCasesByStatus(CaseStatus.surgery);
      var allCases = [...preopCases, ...surgeryCases];

      // Filter by assigned anesthesiologist if ID is provided
      if (anesthesiologistId != null && anesthesiologistId!.isNotEmpty) {
        final assignedCaseIds = <String>{};
        for (final c in allCases) {
          final surgeries = await _surgeryRepository.getSurgeriesByCaseId(c.id);
          for (final surgery in surgeries) {
            if (surgery.anesthesiologistId == anesthesiologistId) {
              assignedCaseIds.add(c.id);
              break;
            }
          }
        }
        allCases = allCases.where((c) => assignedCaseIds.contains(c.id)).toList();
      }

      final planningList = await Future.wait(
        allCases.map((c) async {
          final patient = await _patientRepository.getPatientById(c.patientId);
          final evaluation = await _anesthesiaRepository.getEvaluationByCaseId(c.id);
          final checklist = await _checklistRepository.getChecklistByCaseAndType(
            c.id,
            ChecklistType.preop,
          );
          return AnesthesiaConsultationData(
            hospitalCase: c,
            patient: patient,
            evaluation: evaluation,
            preopChecklist: checklist,
          );
        }),
      );

      // Sort by entry date (most recent first)
      planningList.sort((a, b) {
        return b.hospitalCase.entryDate.compareTo(a.hospitalCase.entryDate);
      });

      state = state.copyWith(
        planningList: planningList,
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

/// Provider for anesthesia planning (filtered by current anesthesiologist)
final anesthesiaPlanningProvider =
    StateNotifierProvider<AnesthesiaPlanningNotifier, AnesthesiaPlanningState>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return AnesthesiaPlanningNotifier(currentUser?.id);
});

/// State for anesthesia evaluation
class EvaluationState {
  final AnesthesiaEvaluation? currentEvaluation;
  final bool isLoading;
  final String? error;

  const EvaluationState({
    this.currentEvaluation,
    this.isLoading = false,
    this.error,
  });

  EvaluationState copyWith({
    AnesthesiaEvaluation? currentEvaluation,
    bool? isLoading,
    String? error,
  }) {
    return EvaluationState(
      currentEvaluation: currentEvaluation ?? this.currentEvaluation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Evaluation notifier
class EvaluationNotifier extends StateNotifier<EvaluationState> {
  EvaluationNotifier() : super(const EvaluationState());

  final AnesthesiaRepository _anesthesiaRepository = AnesthesiaRepository();

  /// Load evaluation by ID
  Future<void> loadEvaluation(String evaluationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final evaluation = await _anesthesiaRepository.getEvaluationById(evaluationId);
      state = state.copyWith(
        currentEvaluation: evaluation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Load evaluation for a case
  Future<void> loadEvaluationForCase(String caseId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final evaluation = await _anesthesiaRepository.getEvaluationByCaseId(caseId);
      state = state.copyWith(
        currentEvaluation: evaluation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Create new evaluation
  Future<String?> createEvaluation(AnesthesiaEvaluation evaluation) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = await _anesthesiaRepository.createEvaluation(evaluation);
      final created = await _anesthesiaRepository.getEvaluationById(id);
      state = state.copyWith(
        currentEvaluation: created,
        isLoading: false,
      );
      return id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création: $e',
      );
      return null;
    }
  }

  /// Update evaluation
  Future<bool> updateEvaluation(AnesthesiaEvaluation evaluation) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _anesthesiaRepository.updateEvaluation(evaluation);
      state = state.copyWith(
        currentEvaluation: evaluation,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour: $e',
      );
      return false;
    }
  }

  /// Validate evaluation for surgery
  Future<bool> validateForSurgery(String evaluationId) async {
    try {
      await _anesthesiaRepository.validateEvaluation(evaluationId);
      await loadEvaluation(evaluationId);
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

/// Provider for evaluation management
final evaluationProvider =
    StateNotifierProvider<EvaluationNotifier, EvaluationState>((ref) {
  return EvaluationNotifier();
});

/// Provider for dashboard stats
class AnesthesiaDashboardStats {
  final int triageCount;
  final int planningCount;
  final int clearedCount;
  final int pendingCount;

  const AnesthesiaDashboardStats({
    this.triageCount = 0,
    this.planningCount = 0,
    this.clearedCount = 0,
    this.pendingCount = 0,
  });

  int get total => triageCount + planningCount + clearedCount + pendingCount;
}

final anesthesiaDashboardStatsProvider = FutureProvider<AnesthesiaDashboardStats>((ref) async {
  final caseRepository = HospitalCaseRepository();
  final anesthesiaRepository = AnesthesiaRepository();
  final surgeryRepository = SurgeryRepository();
  final currentUser = ref.watch(currentUserProvider);
  final anesthesiologistId = currentUser?.id;

  try {
    var preopCases = await caseRepository.getCasesByStatus(CaseStatus.preop);
    var surgeryCases = await caseRepository.getCasesByStatus(CaseStatus.surgery);

    // Filter by assigned anesthesiologist if ID is provided
    if (anesthesiologistId != null && anesthesiologistId.isNotEmpty) {
      final assignedPreopIds = <String>{};
      final assignedSurgeryIds = <String>{};

      for (final c in preopCases) {
        final surgeries = await surgeryRepository.getSurgeriesByCaseId(c.id);
        if (surgeries.any((s) => s.anesthesiologistId == anesthesiologistId)) {
          assignedPreopIds.add(c.id);
        }
      }

      for (final c in surgeryCases) {
        final surgeries = await surgeryRepository.getSurgeriesByCaseId(c.id);
        if (surgeries.any((s) => s.anesthesiologistId == anesthesiologistId)) {
          assignedSurgeryIds.add(c.id);
        }
      }

      preopCases = preopCases.where((c) => assignedPreopIds.contains(c.id)).toList();
      surgeryCases = surgeryCases.where((c) => assignedSurgeryIds.contains(c.id)).toList();
    }

    int clearedCount = 0;
    int pendingCount = 0;

    for (final c in preopCases) {
      final evaluation = await anesthesiaRepository.getEvaluationByCaseId(c.id);
      if (evaluation?.isValidated == true) {
        clearedCount++;
      } else {
        pendingCount++;
      }
    }

    return AnesthesiaDashboardStats(
      triageCount: pendingCount,
      planningCount: preopCases.length + surgeryCases.length,
      clearedCount: clearedCount,
      pendingCount: pendingCount,
    );
  } catch (e) {
    return const AnesthesiaDashboardStats();
  }
});

/// Provider for evaluation by case ID
final evaluationByCaseProvider = FutureProvider.family<AnesthesiaEvaluation?, String>((ref, caseId) async {
  final repository = AnesthesiaRepository();
  return await repository.getEvaluationByCaseId(caseId);
});

/// Provider for consultation details
final consultationDetailsProvider = FutureProvider.family<AnesthesiaConsultationData?, String>((ref, caseId) async {
  final caseRepository = HospitalCaseRepository();
  final patientRepository = PatientRepository();
  final anesthesiaRepository = AnesthesiaRepository();
  final checklistRepository = ChecklistRepository();

  try {
    final hospitalCase = await caseRepository.getCaseById(caseId);
    if (hospitalCase == null) return null;

    final patient = await patientRepository.getPatientById(hospitalCase.patientId);
    final evaluation = await anesthesiaRepository.getEvaluationByCaseId(caseId);
    final checklist = await checklistRepository.getChecklistByCaseAndType(
      caseId,
      ChecklistType.preop,
    );

    return AnesthesiaConsultationData(
      hospitalCase: hospitalCase,
      patient: patient,
      evaluation: evaluation,
      preopChecklist: checklist,
    );
  } catch (e) {
    return null;
  }
});
