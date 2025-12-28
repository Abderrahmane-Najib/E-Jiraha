import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../models/user.dart';
import '../../../services/auth_repository.dart';

/// Auth state
class AuthState {
  final User? currentUser;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.currentUser,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? currentUser,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth notifier with Firebase integration
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    // Listen to Firebase auth state changes
    _authRepository.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthRepository _authRepository = AuthRepository();

  // Store username for prototype mode
  String? _currentUsername;

  // Enable/disable Firebase mode (set to false for prototype mode)
  static const bool _useFirebase = true;

  /// Handle Firebase auth state changes
  Future<void> _onAuthStateChanged(fb.User? firebaseUser) async {
    if (!_useFirebase) return;

    if (firebaseUser != null) {
      final user = await _authRepository.getUserById(firebaseUser.uid);
      if (user != null) {
        state = state.copyWith(
          currentUser: user,
          isAuthenticated: true,
          isLoading: false,
        );
      }
    } else {
      state = const AuthState();
    }
  }

  /// Login with email and password (Firebase mode)
  Future<bool> loginWithFirebase(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email,
        password,
      );

      if (user != null) {
        state = state.copyWith(
          currentUser: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Utilisateur non trouvé.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Login with username and password (prototype mode)
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (_useFirebase) {
        // Use Firebase authentication
        await loginWithFirebase(username, password);
      } else {
        // Prototype mode - accept any credentials
        await Future.delayed(const Duration(milliseconds: 800));
        _currentUsername = username;

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de connexion. Veuillez réessayer.',
      );
    }
  }

  /// Login with role (after initial login - prototype mode)
  Future<void> loginWithRole(UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Create mock user based on role
      final user = User(
        id: 'user_${role.name}',
        fullName: _getMockName(role),
        email: '${role.name}@chu.ma',
        role: role,
        service: 'Chirurgie Générale',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      state = state.copyWith(
        currentUser: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Register new user (Firebase mode)
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
    String? service,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.createUserWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
        service: service,
      );

      if (user != null) {
        state = state.copyWith(
          currentUser: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Erreur lors de la création du compte.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Set error message
  void setError(String message) {
    state = state.copyWith(error: message);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Logout
  Future<void> logout() async {
    _currentUsername = null;
    if (_useFirebase) {
      await _authRepository.signOut();
    }
    state = const AuthState();
  }

  /// Get mock name based on role
  String _getMockName(UserRole role) {
    switch (role) {
      case UserRole.secretary:
        return 'Fatima Zahra';
      case UserRole.nurse:
        return 'Khadija Benali';
      case UserRole.surgeon:
        return 'Dr. Ahmed Mansouri';
      case UserRole.anesthesiologist:
        return 'Dr. Youssef Alami';
      case UserRole.admin:
        return 'Admin Système';
    }
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).currentUser;
});

/// Current user role provider
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
