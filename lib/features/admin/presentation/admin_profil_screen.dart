import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../core/constants/app_colors.dart';
import '../../../models/activity_log.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/user_management_provider.dart';

class AdminProfilScreen extends ConsumerStatefulWidget {
  const AdminProfilScreen({super.key});

  @override
  ConsumerState<AdminProfilScreen> createState() => _AdminProfilScreenState();
}

class _AdminProfilScreenState extends ConsumerState<AdminProfilScreen> {
  bool _notificationsEnabled = true;

  void _logout() {
    ref.read(authProvider.notifier).logout();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final logsAsync = ref.watch(recentActivityLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Bar
          _buildTopBar(context),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminDashboardStatsProvider);
                ref.invalidate(recentActivityLogsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Header
                    _buildProfileHeader(user?.fullName ?? 'Admin'),

                    const SizedBox(height: 24),

                    // Info Card
                    _buildInfoCard(user),

                    const SizedBox(height: 16),

                    // Stats Card
                    statsAsync.when(
                      data: (stats) => _buildStatsCard(stats),
                      loading: () => _buildStatsCard(const AdminDashboardStats()),
                      error: (_, __) => _buildStatsCard(const AdminDashboardStats()),
                    ),

                    const SizedBox(height: 16),

                    // Activity Logs Section
                    logsAsync.when(
                      data: (logs) => _buildActivityLogsSection(logs),
                      loading: () => _buildActivityLogsSection([]),
                      error: (_, __) => _buildActivityLogsSection([]),
                    ),

                    const SizedBox(height: 16),

                    // Settings Section
                    _buildSettingsSection(),

                    const SizedBox(height: 24),

                    // Logout Button
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Mon Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.adminColor, AppColors.adminColor.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.adminColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _getInitials(name),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.adminColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 14,
                color: AppColors.adminColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Administrateur',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.adminColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? 'admin@chu.ma',
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            value: user?.phone ?? '0600000000',
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.local_hospital_outlined,
            label: 'Service',
            value: 'Administration',
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Membre depuis',
            value: user?.createdAt != null
                ? '${_getMonthName(user!.createdAt.month)} ${user.createdAt.year}'
                : 'Janvier 2024',
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  Widget _buildStatsCard(AdminDashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques de gestion',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.people,
                  value: stats.totalUsers.toString(),
                  label: 'Utilisateurs',
                  color: AppColors.adminColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.check_circle,
                  value: stats.activeUsers.toString(),
                  label: 'Actifs',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.block,
                  value: stats.inactiveUsers.toString(),
                  label: 'Inactifs',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogsSection(List<ActivityLog> logs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activité récente',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAllLogsDialog(logs),
                  child: Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune activité récente',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.take(5).length,
              separatorBuilder: (context, index) => Divider(height: 1, indent: 60),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _ActivityLogTile(log: log);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAllLogsDialog(List<ActivityLog> logs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.history, color: AppColors.adminColor),
                  const SizedBox(width: 12),
                  Text(
                    'Journal d\'activité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Logs list
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune activité enregistrée',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: logs.length,
                      separatorBuilder: (context, index) => Divider(height: 1, indent: 60),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _ActivityLogTile(log: log);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Changer le mot de passe',
            onTap: _showChangePasswordDialog,
          ),
          Divider(height: 1, indent: 60),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? 'Notifications activées' : 'Notifications désactivées'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              activeColor: AppColors.primary,
            ),
            onTap: () {
              setState(() {
                _notificationsEnabled = !_notificationsEnabled;
              });
            },
          ),
          Divider(height: 1, indent: 60),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'À propos',
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.lock_outline, color: AppColors.adminColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Changer le mot de passe'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe actuel',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'Minimum 6 caractères',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate
                      if (currentPasswordController.text.isEmpty ||
                          newPasswordController.text.isEmpty ||
                          confirmPasswordController.text.isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Veuillez remplir tous les champs';
                        });
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        setDialogState(() {
                          errorMessage = 'Le mot de passe doit contenir au moins 6 caractères';
                        });
                        return;
                      }

                      if (newPasswordController.text != confirmPasswordController.text) {
                        setDialogState(() {
                          errorMessage = 'Les mots de passe ne correspondent pas';
                        });
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        final user = fb.FirebaseAuth.instance.currentUser;
                        if (user != null && user.email != null) {
                          // Re-authenticate
                          final credential = fb.EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentPasswordController.text,
                          );
                          await user.reauthenticateWithCredential(credential);

                          // Update password
                          await user.updatePassword(newPasswordController.text);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Mot de passe modifié avec succès'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      } on fb.FirebaseAuthException catch (e) {
                        String message;
                        switch (e.code) {
                          case 'wrong-password':
                            message = 'Mot de passe actuel incorrect';
                            break;
                          case 'weak-password':
                            message = 'Le nouveau mot de passe est trop faible';
                            break;
                          default:
                            message = 'Erreur: ${e.message}';
                        }
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = message;
                        });
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = 'Une erreur est survenue';
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'ej',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'e-jiraha',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Application de gestion du parcours pré-opératoire des patients',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _AboutInfoRow(
                    icon: Icons.local_hospital,
                    label: 'CHU Mohammed VI',
                  ),
                  const SizedBox(height: 8),
                  _AboutInfoRow(
                    icon: Icons.location_on,
                    label: 'Marrakech, Maroc',
                  ),
                  const SizedBox(height: 8),
                  _AboutInfoRow(
                    icon: Icons.copyright,
                    label: '2024 Tous droits réservés',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Se déconnecter',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'AD';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'AD';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.adminColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.adminColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textTertiary,
          ),
      onTap: onTap,
    );
  }
}

class _ActivityLogTile extends StatelessWidget {
  final ActivityLog log;

  const _ActivityLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: log.type.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(log.type.icon, size: 18, color: log.type.color),
      ),
      title: Text(
        log.description,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        log.timeAgo,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: log.type.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          log.type.label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: log.type.color,
          ),
        ),
      ),
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AboutInfoRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
