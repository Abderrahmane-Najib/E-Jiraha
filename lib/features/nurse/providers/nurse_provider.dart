import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/hospital_case.dart';
import '../../../models/patient.dart';
import '../../../models/checklist.dart';
import '../../../services/hospital_case_repository.dart';
import '../../../services/patient_repository.dart';
import '../../../services/checklist_repository.dart';
import '../../../services/surgery_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Triage data with patient info
class TriageData {
  final HospitalCase hospitalCase;
  final Patient? patient;

  const TriageData({
    required this.hospitalCase,
    this.patient,
  });
}

/// State for nurse triage queue
class TriageQueueState {
  final List<TriageData> triageQueue;
  final bool isLoading;
  final String? error;

  const TriageQueueState({
    this.triageQueue = const [],
    this.isLoading = false,
    this.error,
  });

  TriageQueueState copyWith({
    List<TriageData>? triageQueue,
    bool? isLoading,
    String? error,
  }) {
    return TriageQueueState(
      triageQueue: triageQueue ?? this.triageQueue,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Triage queue notifier
class TriageQueueNotifier extends StateNotifier<TriageQueueState> {
  final String? nurseId;

  TriageQueueNotifier(this.nurseId) : super(const TriageQueueState()) {
    loadTriageQueue();
  }

  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();
  final SurgeryRepository _surgeryRepository = SurgeryRepository();

  /// Load triage queue (cases assigned to this nurse via surgery)
  Future<void> loadTriageQueue() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get cases that need triage (admission or consultation status)
      final admissionCases = await _caseRepository.getCasesByStatus(CaseStatus.admission);
      final consultationCases = await _caseRepository.getCasesByStatus(CaseStatus.consultation);
      var allCases = [...admissionCases, ...consultationCases];

      // Filter by assigned nurse if nurseId is provided
      if (nurseId != null && nurseId!.isNotEmpty) {
        // Get all surgeries to check nurse assignments
        final assignedCaseIds = <String>{};
        for (final c in allCases) {
          final surgeries = await _surgeryRepository.getSurgeriesByCaseId(c.id);
          for (final surgery in surgeries) {
            if (surgery.nurseIds.contains(nurseId)) {
              assignedCaseIds.add(c.id);
              break;
            }
          }
        }
        allCases = allCases.where((c) => assignedCaseIds.contains(c.id)).toList();
      }

      // Load patient data for each case
      final triageQueue = await Future.wait(
        allCases.map((c) async {
          final patient = await _patientRepository.getPatientById(c.patientId);
          return TriageData(hospitalCase: c, patient: patient);
        }),
      );

      // Sort by entry date (most recent first)
      triageQueue.sort((a, b) => b.hospitalCase.entryDate.compareTo(a.hospitalCase.entryDate));

      state = state.copyWith(
        triageQueue: triageQueue,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Update case status after triage
  Future<bool> completeTriage(String caseId) async {
    try {
      await _caseRepository.updateCaseStatus(caseId, CaseStatus.preop);
      await loadTriageQueue();
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

/// Provider for triage queue (filtered by current nurse)
final triageQueueProvider =
    StateNotifierProvider<TriageQueueNotifier, TriageQueueState>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return TriageQueueNotifier(currentUser?.id);
});

/// Planning data with patient and checklist info
class PlanningData {
  final HospitalCase hospitalCase;
  final Patient? patient;
  final Checklist? preopChecklist;

  const PlanningData({
    required this.hospitalCase,
    this.patient,
    this.preopChecklist,
  });
}

/// State for nurse planning
class PlanningState {
  final List<PlanningData> planningList;
  final bool isLoading;
  final String? error;

  const PlanningState({
    this.planningList = const [],
    this.isLoading = false,
    this.error,
  });

  PlanningState copyWith({
    List<PlanningData>? planningList,
    bool? isLoading,
    String? error,
  }) {
    return PlanningState(
      planningList: planningList ?? this.planningList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Planning notifier
class PlanningNotifier extends StateNotifier<PlanningState> {
  final String? nurseId;

  PlanningNotifier(this.nurseId) : super(const PlanningState()) {
    loadPlanning();
  }

  final HospitalCaseRepository _caseRepository = HospitalCaseRepository();
  final PatientRepository _patientRepository = PatientRepository();
  final ChecklistRepository _checklistRepository = ChecklistRepository();
  final SurgeryRepository _surgeryRepository = SurgeryRepository();

  /// Load planning (cases in preop status assigned to this nurse)
  Future<void> loadPlanning() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get cases in preop status
      var preopCases = await _caseRepository.getCasesByStatus(CaseStatus.preop);

      // Filter by assigned nurse if nurseId is provided
      if (nurseId != null && nurseId!.isNotEmpty) {
        final assignedCaseIds = <String>{};
        for (final c in preopCases) {
          final surgeries = await _surgeryRepository.getSurgeriesByCaseId(c.id);
          for (final surgery in surgeries) {
            if (surgery.nurseIds.contains(nurseId)) {
              assignedCaseIds.add(c.id);
              break;
            }
          }
        }
        preopCases = preopCases.where((c) => assignedCaseIds.contains(c.id)).toList();
      }

      // Load patient and checklist data for each case
      final allPlanningData = await Future.wait(
        preopCases.map((c) async {
          final patient = await _patientRepository.getPatientById(c.patientId);
          final checklist = await _checklistRepository.getChecklistByCaseAndType(
            c.id,
            ChecklistType.preop,
          );
          return PlanningData(
            hospitalCase: c,
            patient: patient,
            preopChecklist: checklist,
          );
        }),
      );

      // Filter out cases where checklist is already completed
      // Only show cases that need work (no checklist yet, or checklist not complete)
      final planningList = allPlanningData
          .where((d) => d.preopChecklist == null || !d.preopChecklist!.isCompleted)
          .toList();

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

/// Provider for planning (filtered by current nurse)
final planningProvider =
    StateNotifierProvider<PlanningNotifier, PlanningState>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return PlanningNotifier(currentUser?.id);
});

/// State for checklist management
class ChecklistState {
  final Checklist? currentChecklist;
  final List<Checklist> caseChecklists;
  final bool isLoading;
  final String? error;

  const ChecklistState({
    this.currentChecklist,
    this.caseChecklists = const [],
    this.isLoading = false,
    this.error,
  });

  ChecklistState copyWith({
    Checklist? currentChecklist,
    List<Checklist>? caseChecklists,
    bool? isLoading,
    String? error,
  }) {
    return ChecklistState(
      currentChecklist: currentChecklist ?? this.currentChecklist,
      caseChecklists: caseChecklists ?? this.caseChecklists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Checklist notifier
class ChecklistNotifier extends StateNotifier<ChecklistState> {
  ChecklistNotifier() : super(const ChecklistState());

  final ChecklistRepository _checklistRepository = ChecklistRepository();

  /// Load checklist by ID
  Future<void> loadChecklist(String checklistId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final checklist = await _checklistRepository.getChecklistById(checklistId);
      state = state.copyWith(
        currentChecklist: checklist,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Load checklists for a case
  Future<void> loadChecklistsForCase(String caseId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final checklists = await _checklistRepository.getChecklistsByCaseId(caseId);
      state = state.copyWith(
        caseChecklists: checklists,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Create a preop checklist for a case
  Future<String?> createPreopChecklist(String caseId, String createdBy) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final checklist = Checklist.createPreopChecklist(
        id: '', // Will be set by Firestore
        caseId: caseId,
        createdBy: createdBy,
      );
      final id = await _checklistRepository.createChecklist(checklist);
      await loadChecklistsForCase(caseId);
      return id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création: $e',
      );
      return null;
    }
  }

  /// Update a checklist item
  Future<bool> updateChecklistItem(String checklistId, ChecklistItem item) async {
    try {
      await _checklistRepository.updateChecklistItem(checklistId, item);
      await loadChecklist(checklistId);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
      return false;
    }
  }

  /// Mark checklist as completed
  Future<bool> markAsCompleted(String checklistId, String completedBy) async {
    try {
      await _checklistRepository.markAsCompleted(checklistId, completedBy);
      await loadChecklist(checklistId);
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

/// Provider for checklist management
final checklistProvider =
    StateNotifierProvider<ChecklistNotifier, ChecklistState>((ref) {
  return ChecklistNotifier();
});

/// Provider for checklist by ID
final checklistByIdProvider = FutureProvider.family<Checklist?, String>((ref, id) async {
  final repository = ChecklistRepository();
  return await repository.getChecklistById(id);
});

/// Provider for checklists by case
final checklistsByCaseProvider = FutureProvider.family<List<Checklist>, String>((ref, caseId) async {
  final repository = ChecklistRepository();
  return await repository.getChecklistsByCaseId(caseId);
});

/// Provider for dashboard stats
class NurseDashboardStats {
  final int triageCount;
  final int planningCount;
  final int blocReadyCount;
  final int waitingCount;

  const NurseDashboardStats({
    this.triageCount = 0,
    this.planningCount = 0,
    this.blocReadyCount = 0,
    this.waitingCount = 0,
  });

  int get total => triageCount + planningCount + blocReadyCount + waitingCount;
}

final nurseDashboardStatsProvider = FutureProvider<NurseDashboardStats>((ref) async {
  final caseRepository = HospitalCaseRepository();
  final surgeryRepository = SurgeryRepository();
  final checklistRepository = ChecklistRepository();
  final currentUser = ref.watch(currentUserProvider);
  final nurseId = currentUser?.id;

  try {
    final admissionCases = await caseRepository.getCasesByStatus(CaseStatus.admission);
    final consultationCases = await caseRepository.getCasesByStatus(CaseStatus.consultation);
    final preopCases = await caseRepository.getCasesByStatus(CaseStatus.preop);
    final surgeryCases = await caseRepository.getCasesByStatus(CaseStatus.surgery);

    // Filter by assigned nurse if nurseId is provided
    int triageCount = 0;
    int planningCount = 0;
    int blocReadyCount = 0;

    if (nurseId != null && nurseId.isNotEmpty) {
      // Count triage cases assigned to this nurse
      for (final c in [...admissionCases, ...consultationCases]) {
        final surgeries = await surgeryRepository.getSurgeriesByCaseId(c.id);
        if (surgeries.any((s) => s.nurseIds.contains(nurseId))) {
          triageCount++;
        }
      }

      // Count preop cases assigned to this nurse WITH INCOMPLETE checklists
      for (final c in preopCases) {
        final surgeries = await surgeryRepository.getSurgeriesByCaseId(c.id);
        if (surgeries.any((s) => s.nurseIds.contains(nurseId))) {
          // Check if checklist is completed
          final checklist = await checklistRepository.getChecklistByCaseAndType(
            c.id,
            ChecklistType.preop,
          );
          // Only count if no checklist or checklist not completed
          if (checklist == null || !checklist.isCompleted) {
            planningCount++;
          }
        }
      }

      // Count surgery cases assigned to this nurse
      for (final c in surgeryCases) {
        final surgeries = await surgeryRepository.getSurgeriesByCaseId(c.id);
        if (surgeries.any((s) => s.nurseIds.contains(nurseId))) {
          blocReadyCount++;
        }
      }
    } else {
      // No nurse logged in, show all counts (also filter completed checklists)
      triageCount = admissionCases.length + consultationCases.length;
      for (final c in preopCases) {
        final checklist = await checklistRepository.getChecklistByCaseAndType(
          c.id,
          ChecklistType.preop,
        );
        if (checklist == null || !checklist.isCompleted) {
          planningCount++;
        }
      }
      blocReadyCount = surgeryCases.length;
    }

    return NurseDashboardStats(
      triageCount: triageCount,
      planningCount: planningCount,
      blocReadyCount: blocReadyCount,
      waitingCount: 0,
    );
  } catch (e) {
    return const NurseDashboardStats();
  }
});
