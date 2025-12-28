import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital_case.dart';
import 'firebase_service.dart';

/// Repository for hospital case operations
class HospitalCaseRepository {
  final FirebaseService _firebaseService = FirebaseService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firebaseService.hospitalCasesCollection;

  /// Get all hospital cases
  Future<List<HospitalCase>> getAllCases() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => HospitalCase.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get case by ID
  Future<HospitalCase?> getCaseById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return HospitalCase.fromFirestore(doc.id, doc.data()!);
    }
    return null;
  }

  /// Get cases by patient ID
  Future<List<HospitalCase>> getCasesByPatientId(String patientId) async {
    final snapshot = await _collection
        .where('patientId', isEqualTo: patientId)
        .get();
    final cases = snapshot.docs
        .map((doc) => HospitalCase.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    cases.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return cases;
  }

  /// Get active cases (not completed or cancelled)
  Future<List<HospitalCase>> getActiveCases() async {
    final snapshot = await _collection
        .where('status', whereNotIn: [CaseStatus.completed.name, CaseStatus.cancelled.name])
        .get();
    final cases = snapshot.docs
        .map((doc) => HospitalCase.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    cases.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return cases;
  }

  /// Get cases by status
  Future<List<HospitalCase>> getCasesByStatus(CaseStatus status) async {
    final snapshot = await _collection
        .where('status', isEqualTo: status.name)
        .get();
    final cases = snapshot.docs
        .map((doc) => HospitalCase.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    cases.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return cases;
  }

  /// Get cases by doctor
  Future<List<HospitalCase>> getCasesByDoctor(String doctorId) async {
    final snapshot = await _collection
        .where('responsibleDoctorId', isEqualTo: doctorId)
        .get();
    final cases = snapshot.docs
        .map((doc) => HospitalCase.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    cases.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return cases;
  }

  /// Create hospital case
  Future<String> createCase(HospitalCase hospitalCase) async {
    final docRef = await _collection.add(hospitalCase.toFirestore());
    return docRef.id;
  }

  /// Update hospital case
  Future<void> updateCase(HospitalCase hospitalCase) async {
    await _collection.doc(hospitalCase.id).update(hospitalCase.toFirestore());
  }

  /// Update case status
  Future<void> updateCaseStatus(String caseId, CaseStatus status) async {
    await _collection.doc(caseId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update vital signs
  Future<void> updateVitalSigns(String caseId, Map<String, dynamic> vitalSigns) async {
    await _collection.doc(caseId).update({
      'vitalSigns': vitalSigns,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete hospital case
  Future<void> deleteCase(String id) async {
    await _collection.doc(id).delete();
  }

  /// Get today's admissions
  Future<List<HospitalCase>> getTodayAdmissions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _collection
        .where('entryDate', isGreaterThanOrEqualTo: startOfDay)
        .where('entryDate', isLessThan: endOfDay)
        .get();
    return snapshot.docs
        .map((doc) => HospitalCase.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Stream of active cases
  Stream<List<HospitalCase>> watchActiveCases() {
    return _collection
        .where('status', whereNotIn: [CaseStatus.completed.name, CaseStatus.cancelled.name])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HospitalCase.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Stream of a single case
  Stream<HospitalCase?> watchCase(String id) {
    return _collection.doc(id).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? HospitalCase.fromFirestore(doc.id, doc.data()!)
              : null,
        );
  }
}
