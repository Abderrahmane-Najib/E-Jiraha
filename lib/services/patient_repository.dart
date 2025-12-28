import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import 'firebase_service.dart';

/// Repository for patient operations
class PatientRepository {
  final FirebaseService _firebaseService = FirebaseService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firebaseService.patientsCollection;

  /// Get all patients
  Future<List<Patient>> getAllPatients() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Patient.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get patient by ID
  Future<Patient?> getPatientById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Patient.fromFirestore(doc.id, doc.data()!);
    }
    return null;
  }

  /// Get patient by CIN
  Future<Patient?> getPatientByCin(String cin) async {
    final snapshot = await _collection.where('cin', isEqualTo: cin).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return Patient.fromFirestore(doc.id, doc.data());
    }
    return null;
  }

  /// Create patient
  Future<String> createPatient(Patient patient) async {
    final docRef = await _collection.add(patient.toFirestore());
    return docRef.id;
  }

  /// Update patient
  Future<void> updatePatient(Patient patient) async {
    await _collection.doc(patient.id).update(patient.toFirestore());
  }

  /// Delete patient
  Future<void> deletePatient(String id) async {
    await _collection.doc(id).delete();
  }

  /// Search patients by name or CIN
  Future<List<Patient>> searchPatients(String query) async {
    final queryLower = query.toLowerCase();
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => Patient.fromFirestore(doc.id, doc.data()))
        .where((patient) =>
            patient.fullName.toLowerCase().contains(queryLower) ||
            patient.cin.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Get recent patients
  Future<List<Patient>> getRecentPatients({int limit = 10}) async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => Patient.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Stream of all patients
  Stream<List<Patient>> watchAllPatients() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Patient.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Stream of a single patient
  Stream<Patient?> watchPatient(String id) {
    return _collection.doc(id).snapshots().map(
          (doc) =>
              doc.exists && doc.data() != null ? Patient.fromFirestore(doc.id, doc.data()!) : null,
        );
  }
}
