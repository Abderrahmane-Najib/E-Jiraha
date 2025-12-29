import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Activity log types
enum ActivityType {
  userCreated,
  userUpdated,
  userDeleted,
  userLogin,
  userLogout,
  patientCreated,
  patientUpdated,
  admissionCreated,
  admissionUpdated,
  triageCompleted,
  checklistCompleted,
  surgeryScheduled,
  surgeryCompleted,
  anesthesiaCleared,
  systemEvent,
}

extension ActivityTypeExtension on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.userCreated:
        return 'Utilisateur créé';
      case ActivityType.userUpdated:
        return 'Utilisateur modifié';
      case ActivityType.userDeleted:
        return 'Utilisateur supprimé';
      case ActivityType.userLogin:
        return 'Connexion';
      case ActivityType.userLogout:
        return 'Déconnexion';
      case ActivityType.patientCreated:
        return 'Patient créé';
      case ActivityType.patientUpdated:
        return 'Patient modifié';
      case ActivityType.admissionCreated:
        return 'Admission créée';
      case ActivityType.admissionUpdated:
        return 'Admission modifiée';
      case ActivityType.triageCompleted:
        return 'Triage complété';
      case ActivityType.checklistCompleted:
        return 'Checklist complétée';
      case ActivityType.surgeryScheduled:
        return 'Chirurgie planifiée';
      case ActivityType.surgeryCompleted:
        return 'Chirurgie terminée';
      case ActivityType.anesthesiaCleared:
        return 'Anesthésie validée';
      case ActivityType.systemEvent:
        return 'Événement système';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.userCreated:
        return Icons.person_add;
      case ActivityType.userUpdated:
        return Icons.edit;
      case ActivityType.userDeleted:
        return Icons.person_remove;
      case ActivityType.userLogin:
        return Icons.login;
      case ActivityType.userLogout:
        return Icons.logout;
      case ActivityType.patientCreated:
        return Icons.person_add_alt_1;
      case ActivityType.patientUpdated:
        return Icons.person_outline;
      case ActivityType.admissionCreated:
        return Icons.folder_open;
      case ActivityType.admissionUpdated:
        return Icons.folder;
      case ActivityType.triageCompleted:
        return Icons.fact_check;
      case ActivityType.checklistCompleted:
        return Icons.checklist;
      case ActivityType.surgeryScheduled:
        return Icons.calendar_today;
      case ActivityType.surgeryCompleted:
        return Icons.check_circle;
      case ActivityType.anesthesiaCleared:
        return Icons.monitor_heart;
      case ActivityType.systemEvent:
        return Icons.settings;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.userCreated:
      case ActivityType.patientCreated:
      case ActivityType.admissionCreated:
        return AppColors.success;
      case ActivityType.userUpdated:
      case ActivityType.patientUpdated:
      case ActivityType.admissionUpdated:
        return AppColors.primary;
      case ActivityType.userDeleted:
        return AppColors.error;
      case ActivityType.userLogin:
        return AppColors.success;
      case ActivityType.userLogout:
        return AppColors.warning;
      case ActivityType.triageCompleted:
      case ActivityType.checklistCompleted:
      case ActivityType.anesthesiaCleared:
        return AppColors.success;
      case ActivityType.surgeryScheduled:
        return AppColors.primary;
      case ActivityType.surgeryCompleted:
        return AppColors.success;
      case ActivityType.systemEvent:
        return AppColors.textSecondary;
    }
  }
}

/// Activity log model for tracking system activities
class ActivityLog {
  final String id;
  final ActivityType type;
  final String description;
  final String? userId;
  final String? userName;
  final String? targetId;
  final String? targetName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.type,
    required this.description,
    this.userId,
    this.userName,
    this.targetId,
    this.targetName,
    this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'description': description,
      'userId': userId,
      'userName': userName,
      'targetId': targetId,
      'targetName': targetName,
      'metadata': metadata,
      'createdAt': createdAt,
    };
  }

  factory ActivityLog.fromFirestore(String docId, Map<String, dynamic> data) {
    return ActivityLog(
      id: docId,
      type: ActivityType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ActivityType.systemEvent,
      ),
      description: data['description'] ?? '',
      userId: data['userId'],
      userName: data['userName'],
      targetId: data['targetId'],
      targetName: data['targetName'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
