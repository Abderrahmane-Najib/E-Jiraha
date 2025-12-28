import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'firebase_service.dart';

/// Repository for user management operations
class UserRepository {
  final FirebaseService _firebaseService = FirebaseService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firebaseService.usersCollection;

  /// Get all users
  Future<List<User>> getAllUsers() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => User.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async {
    final snapshot = await _collection
        .where('role', isEqualTo: role.name)
        .get();
    final users = snapshot.docs
        .map((doc) => User.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    users.sort((a, b) => a.fullName.compareTo(b.fullName));
    return users;
  }

  /// Get active users only
  Future<List<User>> getActiveUsers() async {
    final snapshot = await _collection
        .where('isActive', isEqualTo: true)
        .orderBy('fullName')
        .get();
    return snapshot.docs
        .map((doc) => User.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get user by ID
  Future<User?> getUserById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return User.fromFirestore(doc.id, doc.data()!);
    }
    return null;
  }

  /// Create user (for admin)
  Future<void> createUser(User user) async {
    await _collection.doc(user.id).set(user.toFirestore());
  }

  /// Update user
  Future<void> updateUser(User user) async {
    await _collection.doc(user.id).update(user.toFirestore());
  }

  /// Update user role
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _collection.doc(userId).update({'role': newRole.name});
  }

  /// Activate/Deactivate user
  Future<void> setUserActive(String userId, bool isActive) async {
    await _collection.doc(userId).update({'isActive': isActive});
  }

  /// Delete user (soft delete by deactivating)
  Future<void> deleteUser(String userId) async {
    await _collection.doc(userId).delete();
  }

  /// Search users by name
  Future<List<User>> searchUsers(String query) async {
    final queryLower = query.toLowerCase();
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => User.fromFirestore(doc.id, doc.data()))
        .where((user) => user.fullName.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Stream of all users
  Stream<List<User>> watchAllUsers() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => User.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }
}
