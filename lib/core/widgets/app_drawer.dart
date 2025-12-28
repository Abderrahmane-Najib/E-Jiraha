import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/user.dart';
import '../../routing/app_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) return const SizedBox.shrink();

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        user.fullName.split(' ').map((n) => n[0]).take(2).join(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.role.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: AppStrings.home,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(_getDashboardRoute(user.role));
                    },
                  ),
                  if (user.role == UserRole.secretary) ...[
                    _DrawerItem(
                      icon: Icons.person_add_outlined,
                      label: AppStrings.newPatient,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRoutes.newPatient);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.people_outline,
                      label: AppStrings.patientList,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRoutes.patientList);
                      },
                    ),
                  ],
                  if (user.role == UserRole.nurse) ...[
                    _DrawerItem(
                      icon: Icons.checklist_outlined,
                      label: AppStrings.checklist,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                  if (user.role == UserRole.surgeon) ...[
                    _DrawerItem(
                      icon: Icons.medical_information_outlined,
                      label: AppStrings.consultation,
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerItem(
                      icon: Icons.calendar_month_outlined,
                      label: AppStrings.bloc,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                  if (user.role == UserRole.anesthesiologist) ...[
                    _DrawerItem(
                      icon: Icons.assignment_outlined,
                      label: AppStrings.preOpConsultation,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                  const Divider(height: 32),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Paramètres',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Logout button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go(AppRoutes.login);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text(AppStrings.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDashboardRoute(UserRole role) {
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
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
