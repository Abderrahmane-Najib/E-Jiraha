import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';

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

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Login with role (simplified for prototype)
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

  /// Logout
  Future<void> logout() async {
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
