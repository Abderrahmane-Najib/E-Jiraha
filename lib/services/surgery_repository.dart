import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/surgery.dart';
import 'firebase_service.dart';

/// Repository for surgery operations
class SurgeryRepository {
  final FirebaseService _firebaseService = FirebaseService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firebaseService.surgeriesCollection;

  /// Get all surgeries
  Future<List<Surgery>> getAllSurgeries() async {
    final snapshot = await _collection.orderBy('scheduledDate', descending: true).get();
    return snapshot.docs
        .map((doc) => Surgery.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get surgery by ID
  Future<Surgery?> getSurgeryById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Surgery.fromFirestore(doc.id, doc.data()!);
    }
    return null;
  }

  /// Get surgeries by case ID
  Future<List<Surgery>> getSurgeriesByCaseId(String caseId) async {
    final snapshot = await _collection
        .where('caseId', isEqualTo: caseId)
        .get();
    final surgeries = snapshot.docs
        .map((doc) => Surgery.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    surgeries.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return surgeries;
  }

  /// Get surgeries by patient ID
  Future<List<Surgery>> getSurgeriesByPatientId(String patientId) async {
    final snapshot = await _collection
        .where('patientId', isEqualTo: patientId)
        .get();
    final surgeries = snapshot.docs
        .map((doc) => Surgery.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    surgeries.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return surgeries;
  }

  /// Get surgeries by surgeon
  Future<List<Surgery>> getSurgeriesBySurgeon(String surgeonId) async {
    final snapshot = await _collection
        .where('leadSurgeonId', isEqualTo: surgeonId)
        .get();
    final surgeries = snapshot.docs
        .map((doc) => Surgery.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    surgeries.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return surgeries;
  }

  /// Get today's surgeries
  Future<List<Surgery>> getTodaySurgeries() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _collection
        .where('scheduledDate', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledDate', isLessThan: endOfDay)
        .get();
    final surgeries = snapshot.docs
        .map((doc) => Surgery.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side
    surgeries.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return surgeries;
  }

  /// Get scheduled surgeries
  Future<List<Surgery>> getScheduledSurgeries() async {
    final snapshot = await _collection
        .where('status', isEqualTo: SurgeryStatus.scheduled.name)
        .get();
    final surgeries = snapshot.docs
        .map((doc) => Surgery.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    surgeries.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return surgeries;
  }

  /// Get surgeries by status
  Future<List<Surgery>> getSurgeriesByStatus(SurgeryStatus status) async {
    final snapshot = await _collection
        .where('status', isEqualTo: status.name)
        .get();
    final surgeries = snapshot.docs
        .map((doc) => Surgery.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    surgeries.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return surgeries;
  }

  /// Create surgery
  Future<String> createSurgery(Surgery surgery) async {
    final docRef = await _collection.add(surgery.toFirestore());
    return docRef.id;
  }

  /// Update surgery
  Future<void> updateSurgery(Surgery surgery) async {
    await _collection.doc(surgery.id).update(surgery.toFirestore());
  }

  /// Update surgery status
  Future<void> updateSurgeryStatus(String surgeryId, SurgeryStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == SurgeryStatus.inProgress) {
      updates['startTime'] = FieldValue.serverTimestamp();
    } else if (status == SurgeryStatus.completed) {
      updates['endTime'] = FieldValue.serverTimestamp();
    }

    await _collection.doc(surgeryId).update(updates);
  }

  /// Delete surgery
  Future<void> deleteSurgery(String id) async {
    await _collection.doc(id).delete();
  }

  /// Stream of today's surgeries
  Stream<List<Surgery>> watchTodaySurgeries() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _collection
        .where('scheduledDate', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledDate', isLessThan: endOfDay)
        .snapshots()
        .map((snapshot) {
          final surgeries = snapshot.docs
              .map((doc) => Surgery.fromFirestore(doc.id, doc.data()))
              .toList();
          // Sort client-side
          surgeries.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
          return surgeries;
        });
  }

  /// Stream of a single surgery
  Stream<Surgery?> watchSurgery(String id) {
    return _collection.doc(id).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? Surgery.fromFirestore(doc.id, doc.data()!)
              : null,
        );
  }
}
