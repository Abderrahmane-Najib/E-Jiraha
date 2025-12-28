import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';

/// Core Firebase service providing access to Firebase instances
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// Firestore instance
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Firebase Auth instance
  fb.FirebaseAuth get auth => fb.FirebaseAuth.instance;

  /// Firebase Storage instance
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Collection references
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get patientsCollection =>
      firestore.collection('patients');

  CollectionReference<Map<String, dynamic>> get hospitalCasesCollection =>
      firestore.collection('hospital_cases');

  CollectionReference<Map<String, dynamic>> get surgeriesCollection =>
      firestore.collection('surgeries');

  CollectionReference<Map<String, dynamic>> get checklistsCollection =>
      firestore.collection('checklists');

  CollectionReference<Map<String, dynamic>> get anesthesiaEvaluationsCollection =>
      firestore.collection('anesthesia_evaluations');
}
