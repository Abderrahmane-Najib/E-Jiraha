import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

/// User roles in the application
enum UserRole {
  secretary,
  nurse,
  surgeon,
  anesthesiologist,
  admin,
}

extension UserRoleExtension on UserRole {
  String get title {
    switch (this) {
      case UserRole.secretary:
        return AppStrings.secretary;
      case UserRole.nurse:
        return AppStrings.nurse;
      case UserRole.surgeon:
        return AppStrings.surgeon;
      case UserRole.anesthesiologist:
        return AppStrings.anesthesiologist;
      case UserRole.admin:
        return AppStrings.admin;
    }
  }

  String get description {
    switch (this) {
      case UserRole.secretary:
        return AppStrings.secretaryDesc;
      case UserRole.nurse:
        return AppStrings.nurseDesc;
      case UserRole.surgeon:
        return AppStrings.surgeonDesc;
      case UserRole.anesthesiologist:
        return AppStrings.anesthesiologistDesc;
      case UserRole.admin:
        return AppStrings.adminDesc;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.secretary:
        return AppColors.secretaryColor;
      case UserRole.nurse:
        return AppColors.nurseColor;
      case UserRole.surgeon:
        return AppColors.surgeonColor;
      case UserRole.anesthesiologist:
        return AppColors.anesthesiologistColor;
      case UserRole.admin:
        return AppColors.adminColor;
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.secretary:
        return Icons.assignment_ind_outlined;
      case UserRole.nurse:
        return Icons.medical_services_outlined;
      case UserRole.surgeon:
        return Icons.healing_outlined;
      case UserRole.anesthesiologist:
        return Icons.monitor_heart_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}

/// User model
class User {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? service;
  final String? phone;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.service,
    this.phone,
    this.profileImageUrl,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    UserRole? role,
    String? service,
    String? phone,
    String? profileImageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      service: service ?? this.service,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role.name,
      'service': service,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.secretary,
      ),
      service: map['service'] as String?,
      phone: map['phone'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, role: ${role.title})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
