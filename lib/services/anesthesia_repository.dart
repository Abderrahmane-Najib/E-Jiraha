import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/anesthesia.dart';
import 'firebase_service.dart';

/// Repository for anesthesia evaluation operations
class AnesthesiaRepository {
  final FirebaseService _firebaseService = FirebaseService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firebaseService.anesthesiaEvaluationsCollection;

  /// Get all evaluations
  Future<List<AnesthesiaEvaluation>> getAllEvaluations() async {
    final snapshot =
        await _collection.orderBy('evaluationDate', descending: true).get();
    return snapshot.docs
        .map((doc) => AnesthesiaEvaluation.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get evaluation by ID
  Future<AnesthesiaEvaluation?> getEvaluationById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return AnesthesiaEvaluation.fromFirestore(doc.id, doc.data()!);
    }
    return null;
  }

  /// Get evaluation by case ID
  Future<AnesthesiaEvaluation?> getEvaluationByCaseId(String caseId) async {
    final snapshot = await _collection
        .where('caseId', isEqualTo: caseId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return AnesthesiaEvaluation.fromFirestore(doc.id, doc.data());
    }
    return null;
  }

  /// Get all evaluations by case ID
  Future<List<AnesthesiaEvaluation>> getEvaluationsByCaseId(String caseId) async {
    final snapshot = await _collection
        .where('caseId', isEqualTo: caseId)
        .get();
    return snapshot.docs
        .map((doc) => AnesthesiaEvaluation.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get evaluations by patient ID
  Future<List<AnesthesiaEvaluation>> getEvaluationsByPatientId(
      String patientId) async {
    final snapshot = await _collection
        .where('patientId', isEqualTo: patientId)
        .get();
    final evaluations = snapshot.docs
        .map((doc) => AnesthesiaEvaluation.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    evaluations.sort((a, b) => b.evaluationDate.compareTo(a.evaluationDate));
    return evaluations;
  }

  /// Get evaluations by anesthesiologist
  Future<List<AnesthesiaEvaluation>> getEvaluationsByAnesthesiologist(
      String anesthesiologistId) async {
    final snapshot = await _collection
        .where('anesthesiologistId', isEqualTo: anesthesiologistId)
        .get();
    final evaluations = snapshot.docs
        .map((doc) => AnesthesiaEvaluation.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    evaluations.sort((a, b) => b.evaluationDate.compareTo(a.evaluationDate));
    return evaluations;
  }

  /// Get pending evaluations (not validated)
  Future<List<AnesthesiaEvaluation>> getPendingEvaluations() async {
    final snapshot = await _collection
        .where('isValidated', isEqualTo: false)
        .get();
    final evaluations = snapshot.docs
        .map((doc) => AnesthesiaEvaluation.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    evaluations.sort((a, b) => b.evaluationDate.compareTo(a.evaluationDate));
    return evaluations;
  }

  /// Get evaluations by ASA score
  Future<List<AnesthesiaEvaluation>> getEvaluationsByAsaScore(
      AsaScore asaScore) async {
    final snapshot = await _collection
        .where('asaScore', isEqualTo: asaScore.name)
        .get();
    final evaluations = snapshot.docs
        .map((doc) => AnesthesiaEvaluation.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    evaluations.sort((a, b) => b.evaluationDate.compareTo(a.evaluationDate));
    return evaluations;
  }

  /// Create evaluation
  Future<String> createEvaluation(AnesthesiaEvaluation evaluation) async {
    final docRef = await _collection.add(evaluation.toFirestore());
    return docRef.id;
  }

  /// Update evaluation
  Future<void> updateEvaluation(AnesthesiaEvaluation evaluation) async {
    await _collection.doc(evaluation.id).update(evaluation.toFirestore());
  }

  /// Validate evaluation
  Future<void> validateEvaluation(String evaluationId) async {
    await _collection.doc(evaluationId).update({
      'isValidated': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update consent status
  Future<void> updateConsentStatus(
    String evaluationId, {
    required bool consentObtained,
    String? consentImagePath,
  }) async {
    await _collection.doc(evaluationId).update({
      'consentObtained': consentObtained,
      'consentImagePath': consentImagePath,
      'consentDate': consentObtained ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete evaluation
  Future<void> deleteEvaluation(String id) async {
    await _collection.doc(id).delete();
  }

  /// Stream of evaluations by anesthesiologist
  Stream<List<AnesthesiaEvaluation>> watchEvaluationsByAnesthesiologist(
      String anesthesiologistId) {
    return _collection
        .where('anesthesiologistId', isEqualTo: anesthesiologistId)
        .snapshots()
        .map((snapshot) {
          final evaluations = snapshot.docs
              .map((doc) => AnesthesiaEvaluation.fromFirestore(doc.id, doc.data()))
              .toList();
          // Sort client-side to avoid composite index requirement
          evaluations.sort((a, b) => b.evaluationDate.compareTo(a.evaluationDate));
          return evaluations;
        });
  }

  /// Stream of a single evaluation
  Stream<AnesthesiaEvaluation?> watchEvaluation(String id) {
    return _collection.doc(id).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? AnesthesiaEvaluation.fromFirestore(doc.id, doc.data()!)
              : null,
        );
  }
}
