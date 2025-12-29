import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import '../../../models/user.dart';
import '../../../models/activity_log.dart';
import '../../../services/user_repository.dart';
import '../../../services/firebase_service.dart';
import '../../../services/activity_log_repository.dart';

/// State for user management
class UserManagementState {
  final List<User> users;
  final bool isLoading;
  final String? error;

  const UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserManagementState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// User management notifier
class UserManagementNotifier extends StateNotifier<UserManagementState> {
  UserManagementNotifier() : super(const UserManagementState()) {
    loadUsers();
  }

  final UserRepository _userRepository = UserRepository();
  final FirebaseService _firebaseService = FirebaseService();
  final ActivityLogRepository _logRepository = ActivityLogRepository();

  /// Load all users from Firestore
  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _userRepository.getAllUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des utilisateurs: $e',
      );
    }
  }

  /// Create a new user (Firebase Auth + Firestore)
  /// Uses a secondary Firebase App to avoid logging out the current admin
  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? service,
    bool isActive = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    FirebaseApp? secondaryApp;

    try {
      // Create a secondary Firebase App instance to create users
      // without affecting the current admin session
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = fb.FirebaseAuth.instanceFor(app: secondaryApp);

      // Create user in Firebase Auth using secondary instance
      final credential = await secondaryAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        final now = DateTime.now();
        final user = User(
          id: credential.user!.uid,
          fullName: fullName,
          email: email,
          role: role,
          phone: phone,
          service: service,
          isActive: isActive,
          createdAt: now,
        );

        // Sign out from secondary auth and delete the secondary app
        await secondaryAuth.signOut();
        await secondaryApp.delete();

        // Save to Firestore
        await _userRepository.createUser(user);

        // Log the activity
        await _logRepository.logActivity(
          type: ActivityType.userCreated,
          description: 'Utilisateur ${user.fullName} créé (${user.role.title})',
          targetId: user.id,
          targetName: user.fullName,
        );

        // Reload users
        await loadUsers();
        return true;
      }

      state = state.copyWith(isLoading: false, error: 'Erreur lors de la création');
      return false;
    } on fb.FirebaseAuthException catch (e) {
      // Clean up secondary app if it exists
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Cet email est déjà utilisé';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide';
          break;
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible (min 6 caractères)';
          break;
        default:
          errorMessage = 'Erreur: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      // Clean up secondary app if it exists
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }

      state = state.copyWith(isLoading: false, error: 'Erreur: $e');
      return false;
    }
  }

  /// Update user in Firestore
  Future<bool> updateUser(User user) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _userRepository.updateUser(user);

      // Log the activity
      await _logRepository.logActivity(
        type: ActivityType.userUpdated,
        description: 'Utilisateur ${user.fullName} modifié',
        targetId: user.id,
        targetName: user.fullName,
      );

      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  /// Toggle user active status
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _userRepository.setUserActive(userId, isActive);

      // Log the activity
      await _logRepository.logActivity(
        type: ActivityType.userUpdated,
        description: 'Utilisateur ${isActive ? "activé" : "désactivé"}',
        targetId: userId,
      );

      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
      return false;
    }
  }

  /// Delete user (only from Firestore, Firebase Auth user remains)
  Future<bool> deleteUser(String userId) async {
    try {
      // Get user name before deleting
      final user = state.users.firstWhere((u) => u.id == userId, orElse: () => User(id: '', fullName: 'Inconnu', email: '', role: UserRole.secretary, createdAt: DateTime.now()));

      await _userRepository.deleteUser(userId);

      // Log the activity
      await _logRepository.logActivity(
        type: ActivityType.userDeleted,
        description: 'Utilisateur ${user.fullName} supprimé',
        targetId: userId,
        targetName: user.fullName,
      );

      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      return await _userRepository.getUserById(userId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for user management
final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  return UserManagementNotifier();
});

/// Provider for a single user by ID
final userByIdProvider = FutureProvider.family<User?, String>((ref, userId) async {
  final userRepository = UserRepository();
  return await userRepository.getUserById(userId);
});

/// Admin dashboard stats
class AdminDashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final List<User> recentUsers;

  const AdminDashboardStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.inactiveUsers = 0,
    this.recentUsers = const [],
  });
}

/// Provider for admin dashboard stats
final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((ref) async {
  final userRepository = UserRepository();

  try {
    final users = await userRepository.getAllUsers();
    final activeUsers = users.where((u) => u.isActive).length;
    final inactiveUsers = users.where((u) => !u.isActive).length;

    // Get recent users (last 5 created)
    final sortedUsers = List<User>.from(users)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentUsers = sortedUsers.take(5).toList();

    return AdminDashboardStats(
      totalUsers: users.length,
      activeUsers: activeUsers,
      inactiveUsers: inactiveUsers,
      recentUsers: recentUsers,
    );
  } catch (e) {
    return const AdminDashboardStats();
  }
});

/// Provider for recent activity logs
final recentActivityLogsProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final logRepository = ActivityLogRepository();
  return await logRepository.getRecentLogs(limit: 20);
});

/// Provider for today's activity logs
final todayActivityLogsProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final logRepository = ActivityLogRepository();
  return await logRepository.getTodayLogs();
});

/// Stream provider for real-time activity logs
final activityLogsStreamProvider = StreamProvider<List<ActivityLog>>((ref) {
  final logRepository = ActivityLogRepository();
  return logRepository.watchRecentLogs(limit: 20);
});
