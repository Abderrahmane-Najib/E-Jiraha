/// Surgery urgency level
enum SurgeryUrgency {
  elective,
  urgent,
  emergency,
}

extension SurgencyExtension on SurgeryUrgency {
  String get label {
    switch (this) {
      case SurgeryUrgency.elective:
        return 'Programmée';
      case SurgeryUrgency.urgent:
        return 'Urgente';
      case SurgeryUrgency.emergency:
        return 'Urgence vitale';
    }
  }

  int get priority {
    switch (this) {
      case SurgeryUrgency.elective:
        return 3;
      case SurgeryUrgency.urgent:
        return 2;
      case SurgeryUrgency.emergency:
        return 1;
    }
  }
}

/// Surgery status
enum SurgeryStatus {
  scheduled,
  preparing,
  inProgress,
  completed,
  cancelled,
  postponed,
}

extension SurgeryStatusExtension on SurgeryStatus {
  String get label {
    switch (this) {
      case SurgeryStatus.scheduled:
        return 'Programmée';
      case SurgeryStatus.preparing:
        return 'En préparation';
      case SurgeryStatus.inProgress:
        return 'En cours';
      case SurgeryStatus.completed:
        return 'Terminée';
      case SurgeryStatus.cancelled:
        return 'Annulée';
      case SurgeryStatus.postponed:
        return 'Reportée';
    }
  }
}

/// Surgery model
class Surgery {
  final String id;
  final String caseId;
  final String patientId;
  final String surgeryType;
  final String? ccamCode;
  final SurgeryUrgency urgency;
  final SurgeryStatus status;
  final DateTime scheduledDate;
  final String? room;
  final String leadSurgeonId;
  final List<String> assistantIds;
  final String? anesthesiologistId;
  final List<String> nurseIds;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String? technique;
  final String? operativeReport;
  final String? complications;
  final List<String> consumables;
  final String? notes;
  final bool consentSigned;
  final String? consentImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const Surgery({
    required this.id,
    required this.caseId,
    required this.patientId,
    required this.surgeryType,
    this.ccamCode,
    required this.urgency,
    required this.status,
    required this.scheduledDate,
    this.room,
    required this.leadSurgeonId,
    this.assistantIds = const [],
    this.anesthesiologistId,
    this.nurseIds = const [],
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.technique,
    this.operativeReport,
    this.complications,
    this.consumables = const [],
    this.notes,
    this.consentSigned = false,
    this.consentImagePath,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  bool get isCompleted => status == SurgeryStatus.completed;

  int get actualDuration {
    if (startTime == null || endTime == null) return 0;
    return endTime!.difference(startTime!).inMinutes;
  }

  Surgery copyWith({
    String? id,
    String? caseId,
    String? patientId,
    String? surgeryType,
    String? ccamCode,
    SurgeryUrgency? urgency,
    SurgeryStatus? status,
    DateTime? scheduledDate,
    String? room,
    String? leadSurgeonId,
    List<String>? assistantIds,
    String? anesthesiologistId,
    List<String>? nurseIds,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? technique,
    String? operativeReport,
    String? complications,
    List<String>? consumables,
    String? notes,
    bool? consentSigned,
    String? consentImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Surgery(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      patientId: patientId ?? this.patientId,
      surgeryType: surgeryType ?? this.surgeryType,
      ccamCode: ccamCode ?? this.ccamCode,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      room: room ?? this.room,
      leadSurgeonId: leadSurgeonId ?? this.leadSurgeonId,
      assistantIds: assistantIds ?? this.assistantIds,
      anesthesiologistId: anesthesiologistId ?? this.anesthesiologistId,
      nurseIds: nurseIds ?? this.nurseIds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      technique: technique ?? this.technique,
      operativeReport: operativeReport ?? this.operativeReport,
      complications: complications ?? this.complications,
      consumables: consumables ?? this.consumables,
      notes: notes ?? this.notes,
      consentSigned: consentSigned ?? this.consentSigned,
      consentImagePath: consentImagePath ?? this.consentImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caseId': caseId,
      'patientId': patientId,
      'surgeryType': surgeryType,
      'ccamCode': ccamCode,
      'urgency': urgency.name,
      'status': status.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'room': room,
      'leadSurgeonId': leadSurgeonId,
      'assistantIds': assistantIds.join(','),
      'anesthesiologistId': anesthesiologistId,
      'nurseIds': nurseIds.join(','),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'technique': technique,
      'operativeReport': operativeReport,
      'complications': complications,
      'consumables': consumables.join(','),
      'notes': notes,
      'consentSigned': consentSigned ? 1 : 0,
      'consentImagePath': consentImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Surgery.fromMap(Map<String, dynamic> map) {
    return Surgery(
      id: map['id'] as String,
      caseId: map['caseId'] as String,
      patientId: map['patientId'] as String,
      surgeryType: map['surgeryType'] as String,
      ccamCode: map['ccamCode'] as String?,
      urgency: SurgeryUrgency.values.firstWhere(
        (u) => u.name == map['urgency'],
        orElse: () => SurgeryUrgency.elective,
      ),
      status: SurgeryStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SurgeryStatus.scheduled,
      ),
      scheduledDate: DateTime.parse(map['scheduledDate'] as String),
      room: map['room'] as String?,
      leadSurgeonId: map['leadSurgeonId'] as String,
      assistantIds: (map['assistantIds'] as String?)?.isNotEmpty == true
          ? (map['assistantIds'] as String).split(',')
          : [],
      anesthesiologistId: map['anesthesiologistId'] as String?,
      nurseIds: (map['nurseIds'] as String?)?.isNotEmpty == true
          ? (map['nurseIds'] as String).split(',')
          : [],
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'] as String)
          : null,
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      durationMinutes: map['durationMinutes'] as int?,
      technique: map['technique'] as String?,
      operativeReport: map['operativeReport'] as String?,
      complications: map['complications'] as String?,
      consumables: (map['consumables'] as String?)?.isNotEmpty == true
          ? (map['consumables'] as String).split(',')
          : [],
      notes: map['notes'] as String?,
      consentSigned: map['consentSigned'] == 1,
      consentImagePath: map['consentImagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      createdBy: map['createdBy'] as String,
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'caseId': caseId,
      'patientId': patientId,
      'surgeryType': surgeryType,
      'ccamCode': ccamCode,
      'urgency': urgency.name,
      'status': status.name,
      'scheduledDate': scheduledDate,
      'room': room,
      'leadSurgeonId': leadSurgeonId,
      'assistantIds': assistantIds,
      'anesthesiologistId': anesthesiologistId,
      'nurseIds': nurseIds,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'technique': technique,
      'operativeReport': operativeReport,
      'complications': complications,
      'consumables': consumables,
      'notes': notes,
      'consentSigned': consentSigned,
      'consentImagePath': consentImagePath,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
    };
  }

  /// Create from Firestore document
  factory Surgery.fromFirestore(String docId, Map<String, dynamic> data) {
    return Surgery(
      id: docId,
      caseId: data['caseId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      surgeryType: data['surgeryType'] as String? ?? '',
      ccamCode: data['ccamCode'] as String?,
      urgency: SurgeryUrgency.values.firstWhere(
        (u) => u.name == data['urgency'],
        orElse: () => SurgeryUrgency.elective,
      ),
      status: SurgeryStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => SurgeryStatus.scheduled,
      ),
      scheduledDate: (data['scheduledDate'] as dynamic)?.toDate() ?? DateTime.now(),
      room: data['room'] as String?,
      leadSurgeonId: data['leadSurgeonId'] as String? ?? '',
      assistantIds: List<String>.from(data['assistantIds'] ?? []),
      anesthesiologistId: data['anesthesiologistId'] as String?,
      nurseIds: List<String>.from(data['nurseIds'] ?? []),
      startTime: (data['startTime'] as dynamic)?.toDate(),
      endTime: (data['endTime'] as dynamic)?.toDate(),
      durationMinutes: data['durationMinutes'] as int?,
      technique: data['technique'] as String?,
      operativeReport: data['operativeReport'] as String?,
      complications: data['complications'] as String?,
      consumables: List<String>.from(data['consumables'] ?? []),
      notes: data['notes'] as String?,
      consentSigned: data['consentSigned'] as bool? ?? false,
      consentImagePath: data['consentImagePath'] as String?,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'Surgery(id: $id, type: $surgeryType, status: ${status.label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Surgery && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
