import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'firebase_service.dart';

/// Authentication repository for Firebase Auth
class AuthRepository {
  final FirebaseService _firebaseService = FirebaseService();

  fb.FirebaseAuth get _auth => _firebaseService.auth;
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firebaseService.usersCollection;

  /// Get current Firebase user
  fb.User? get currentFirebaseUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Fetch user data from Firestore
        final user = await getUserById(credential.user!.uid);

        if (user != null) {
          // Update last login time (use set with merge to avoid errors)
          await _usersCollection.doc(credential.user!.uid).set({
            'lastLoginAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        return user;
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Create user with email and password
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? service,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final now = DateTime.now();
        final user = User(
          id: credential.user!.uid,
          fullName: fullName,
          email: email,
          role: role,
          phone: phone,
          service: service,
          isActive: true,
          createdAt: now,
          lastLoginAt: now,
        );

        // Save user data to Firestore
        await _usersCollection.doc(user.id).set(user.toFirestore());

        return user;
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user by ID from Firestore
  Future<User?> getUserById(String userId) async {
    try {
      print('DEBUG: Fetching user with ID: $userId');
      final doc = await _usersCollection.doc(userId).get();
      print('DEBUG: Document exists: ${doc.exists}');
      print('DEBUG: Document data: ${doc.data()}');
      if (doc.exists && doc.data() != null) {
        return User.fromFirestore(doc.id, doc.data()!);
      }
      print('DEBUG: Document not found or data is null');
      return null;
    } catch (e) {
      print('DEBUG: Error fetching user: $e');
      return null;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'invalid-email':
        return 'Email invalide.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
