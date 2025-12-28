import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/role_selection_screen.dart';
import '../features/secretary/presentation/secretary_dashboard_screen.dart';
import '../features/secretary/presentation/new_patient_screen.dart';
import '../features/secretary/presentation/patient_list_screen.dart';
import '../features/secretary/presentation/secretary_profil_screen.dart';
import '../features/secretary/presentation/new_admission_screen.dart';
import '../features/secretary/presentation/admission_ouverture_screen.dart';
import '../features/nurse/presentation/nurse_dashboard_screen.dart';
import '../features/nurse/presentation/triage_queue_screen.dart';
import '../features/nurse/presentation/triage_screen.dart';
import '../features/nurse/presentation/planning_screen.dart';
import '../features/nurse/presentation/checklist_screen.dart';
import '../features/nurse/presentation/nurse_profil_screen.dart';
import '../features/surgeon/presentation/surgeon_dashboard_screen.dart';
import '../features/surgeon/presentation/surgeon_patients_screen.dart';
import '../features/surgeon/presentation/surgeon_patient_detail_screen.dart';
import '../features/surgeon/presentation/surgeon_demande_screen.dart';
import '../features/surgeon/presentation/surgeon_decisions_screen.dart';
import '../features/surgeon/presentation/surgeon_bloquants_screen.dart';
import '../features/surgeon/presentation/surgeon_profil_screen.dart';
import '../features/anesthesiologist/presentation/anesthesiologist_dashboard_screen.dart';
import '../features/anesthesiologist/presentation/anesthesiologist_triage_queue_screen.dart';
import '../features/anesthesiologist/presentation/anesthesiologist_triage_screen.dart';
import '../features/anesthesiologist/presentation/anesthesiologist_planning_screen.dart';
import '../features/anesthesiologist/presentation/anesthesiologist_checklist_view_screen.dart';
import '../features/anesthesiologist/presentation/anesthesiologist_profil_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_users_screen.dart';
import '../features/admin/presentation/admin_user_form_screen.dart';
import '../features/admin/presentation/admin_profil_screen.dart';
import '../models/user.dart';

/// Route names
class AppRoutes {
  static const String login = '/';
  static const String roleSelection = '/role-selection';
  static const String secretaryDashboard = '/secretary';
  static const String newPatient = '/secretary/new-patient';
  static const String newAdmission = '/secretary/new-admission';
  static const String admissionOuverture = '/secretary/admission-ouverture';
  static const String secretaryProfil = '/secretary/profil';
  static const String patientList = '/secretary/patients';
  static const String patientDetails = '/secretary/patients/:id';
  static const String nurseDashboard = '/nurse';
  static const String nurseTriageQueue = '/nurse/triage-queue';
  static const String nurseTriage = '/nurse/triage';
  static const String nursePlanning = '/nurse/planning';
  static const String nurseChecklist = '/nurse/checklist';
  static const String nurseProfil = '/nurse/profil';
  static const String surgeonDashboard = '/surgeon';
  static const String surgeonPatients = '/surgeon/patients';
  static const String surgeonPatientDetail = '/surgeon/patient/:id';
  static const String surgeonDemande = '/surgeon/demande';
  static const String surgeonDecisions = '/surgeon/decisions';
  static const String surgeonBloquants = '/surgeon/bloquants';
  static const String surgeonProfil = '/surgeon/profil';
  static const String anesthesiologistDashboard = '/anesthesiologist';
  static const String anesthesiologistTriageQueue = '/anesthesiologist/triage-queue';
  static const String anesthesiologistTriage = '/anesthesiologist/triage';
  static const String anesthesiologistPlanning = '/anesthesiologist/planning';
  static const String anesthesiologistChecklistView = '/anesthesiologist/checklist-view';
  static const String anesthesiologistProfil = '/anesthesiologist/profil';
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminUserAdd = '/admin/users/add';
  static const String adminUserEdit = '/admin/users/:id';
  static const String adminProfil = '/admin/profil';
}

/// App router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final hasUser = authState.currentUser != null;
      final isOnLogin = state.matchedLocation == AppRoutes.login;
      final isOnRoleSelection = state.matchedLocation == AppRoutes.roleSelection;

      // If not authenticated and not on login, redirect to login
      if (!isAuthenticated && !isOnLogin) {
        return AppRoutes.login;
      }

      // If authenticated but no role selected, go to role selection
      if (isAuthenticated && !hasUser && !isOnRoleSelection) {
        return AppRoutes.roleSelection;
      }

      // If authenticated with role and on login/role selection, go to dashboard
      if (isAuthenticated && hasUser && (isOnLogin || isOnRoleSelection)) {
        return _getDashboardRoute(authState.currentUser?.role);
      }

      return null;
    },
    routes: [
      // Login
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Role Selection
      GoRoute(
        path: AppRoutes.roleSelection,
        name: 'roleSelection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Secretary Routes
      GoRoute(
        path: AppRoutes.secretaryDashboard,
        name: 'secretaryDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SecretaryDashboardScreen(),
          transitionsBuilder: _slideTransition,
        ),
        routes: [
          GoRoute(
            path: 'new-patient',
            name: 'newPatient',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NewPatientScreen(),
              transitionsBuilder: _slideTransition,
            ),
          ),
          GoRoute(
            path: 'new-admission',
            name: 'newAdmission',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NewAdmissionScreen(),
              transitionsBuilder: _slideTransition,
            ),
          ),
          GoRoute(
            path: 'admission-ouverture',
            name: 'admissionOuverture',
            pageBuilder: (context, state) {
              final queryParams = state.uri.queryParameters;
              return CustomTransitionPage(
                key: state.pageKey,
                child: AdmissionOuvertureScreen(
                  patientId: queryParams['patientId'] ?? '',
                  patientName: queryParams['patientName'] ?? '',
                  patientInitials: queryParams['patientInitials'] ?? '',
                  patientCin: queryParams['patientCin'] ?? '',
                  patientAge: int.tryParse(queryParams['patientAge'] ?? '0') ?? 0,
                ),
                transitionsBuilder: _slideTransition,
              );
            },
          ),
          GoRoute(
            path: 'profil',
            name: 'secretaryProfil',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SecretaryProfilScreen(),
              transitionsBuilder: _slideTransition,
            ),
          ),
          GoRoute(
            path: 'patients',
            name: 'patientList',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const PatientListScreen(),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),

      // Nurse Routes
      GoRoute(
        path: AppRoutes.nurseDashboard,
        name: 'nurseDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NurseDashboardScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.nurseTriageQueue,
        name: 'nurseTriageQueue',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TriageQueueScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.nurseTriage,
        name: 'nurseTriage',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: TriageScreen(
              caseId: extra?['caseId'] ?? '',
              patientId: extra?['patientId'] ?? '',
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.nursePlanning,
        name: 'nursePlanning',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlanningScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.nurseChecklist,
        name: 'nurseChecklist',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ChecklistScreen(
              caseId: extra?['caseId'] ?? '',
              patientId: extra?['patientId'] ?? '',
              checklistId: extra?['checklistId'],
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.nurseProfil,
        name: 'nurseProfil',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NurseProfilScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // Surgeon Routes
      GoRoute(
        path: AppRoutes.surgeonDashboard,
        name: 'surgeonDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SurgeonDashboardScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.surgeonPatients,
        name: 'surgeonPatients',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SurgeonPatientsScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/surgeon/patient/:id',
        name: 'surgeonPatientDetail',
        pageBuilder: (context, state) {
          final patientId = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: SurgeonPatientDetailScreen(patientId: patientId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.surgeonDemande,
        name: 'surgeonDemande',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: SurgeonDemandeScreen(
              caseId: extra?['caseId'],
              patientId: extra?['patientId'],
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.surgeonDecisions,
        name: 'surgeonDecisions',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SurgeonDecisionsScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.surgeonBloquants,
        name: 'surgeonBloquants',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SurgeonBloquantsScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.surgeonProfil,
        name: 'surgeonProfil',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SurgeonProfilScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // Anesthesiologist Routes
      GoRoute(
        path: AppRoutes.anesthesiologistDashboard,
        name: 'anesthesiologistDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AnesthesiologistDashboardScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.anesthesiologistTriageQueue,
        name: 'anesthesiologistTriageQueue',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AnesthesiologistTriageQueueScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.anesthesiologistTriage,
        name: 'anesthesiologistTriage',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AnesthesiologistTriageScreen(
              caseId: extra?['caseId'] ?? '',
              patientId: extra?['patientId'] ?? '',
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.anesthesiologistPlanning,
        name: 'anesthesiologistPlanning',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AnesthesiologistPlanningScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.anesthesiologistChecklistView,
        name: 'anesthesiologistChecklistView',
        pageBuilder: (context, state) {
          final queryParams = state.uri.queryParameters;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AnesthesiologistChecklistViewScreen(
              patientId: queryParams['patientId'] ?? '',
              patientName: queryParams['patientName'] ?? '',
              patientInitials: queryParams['patientInitials'] ?? '',
              dossierNumber: queryParams['dossierNumber'] ?? '',
              room: queryParams['room'] ?? '',
              progress: int.tryParse(queryParams['progress'] ?? '0') ?? 0,
              total: int.tryParse(queryParams['total'] ?? '5') ?? 5,
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.anesthesiologistProfil,
        name: 'anesthesiologistProfil',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AnesthesiologistProfilScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // Admin Routes
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'adminDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        name: 'adminUsers',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminUsersScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminUserAdd,
        name: 'adminUserAdd',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminUserFormScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminUserEdit,
        name: 'adminUserEdit',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: AdminUserFormScreen(userId: userId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminProfil,
        name: 'adminProfil',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminProfilScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page non trouvée',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(state.error?.message ?? 'Erreur inconnue'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

/// Get dashboard route based on user role
String _getDashboardRoute(UserRole? role) {
  switch (role) {
    case UserRole.secretary:
      return AppRoutes.secretaryDashboard;
    case UserRole.nurse:
      return AppRoutes.nurseDashboard;
    case UserRole.surgeon:
      return AppRoutes.surgeonDashboard;
    case UserRole.anesthesiologist:
      return AppRoutes.anesthesiologistDashboard;
    case UserRole.admin:
      return AppRoutes.adminDashboard;
    default:
      return AppRoutes.login;
  }
}

/// Slide transition builder
Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    )),
    child: child,
  );
}
