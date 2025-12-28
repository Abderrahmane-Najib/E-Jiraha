/// Entry mode for hospital admission
enum EntryMode {
  scheduled,
  emergency,
}

extension EntryModeExtension on EntryMode {
  String get label {
    switch (this) {
      case EntryMode.scheduled:
        return 'Programmée';
      case EntryMode.emergency:
        return 'Urgence';
    }
  }
}

/// Case status in the patient journey
enum CaseStatus {
  admission,
  consultation,
  preop,
  surgery,
  postop,
  discharge,
  completed,
  cancelled,
}

extension CaseStatusExtension on CaseStatus {
  String get label {
    switch (this) {
      case CaseStatus.admission:
        return 'Admission';
      case CaseStatus.consultation:
        return 'Consultation';
      case CaseStatus.preop:
        return 'Pré-opératoire';
      case CaseStatus.surgery:
        return 'Bloc opératoire';
      case CaseStatus.postop:
        return 'Post-opératoire';
      case CaseStatus.discharge:
        return 'Sortie';
      case CaseStatus.completed:
        return 'Terminé';
      case CaseStatus.cancelled:
        return 'Annulé';
    }
  }

  int get order {
    switch (this) {
      case CaseStatus.admission:
        return 1;
      case CaseStatus.consultation:
        return 2;
      case CaseStatus.preop:
        return 3;
      case CaseStatus.surgery:
        return 4;
      case CaseStatus.postop:
        return 5;
      case CaseStatus.discharge:
        return 6;
      case CaseStatus.completed:
        return 7;
      case CaseStatus.cancelled:
        return -1;
    }
  }
}

/// Hospital case/dossier model
class HospitalCase {
  final String id;
  final String patientId;
  final String service;
  final EntryMode entryMode;
  final CaseStatus status;
  final DateTime entryDate;
  final DateTime? exitDate;
  final String? mainDiagnosis;
  final String? diagnosisCode; // CIM-10
  final String? roomNumber;
  final String? bedNumber;
  final String? responsibleDoctorId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  // Vital signs (filled by nurse during triage)
  final Map<String, dynamic>? vitalSigns;

  const HospitalCase({
    required this.id,
    required this.patientId,
    required this.service,
    required this.entryMode,
    required this.status,
    required this.entryDate,
    this.exitDate,
    this.mainDiagnosis,
    this.diagnosisCode,
    this.roomNumber,
    this.bedNumber,
    this.responsibleDoctorId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.vitalSigns,
  });

  bool get isActive =>
      status != CaseStatus.completed && status != CaseStatus.cancelled;

  int get stayDuration {
    final end = exitDate ?? DateTime.now();
    return end.difference(entryDate).inDays;
  }

  HospitalCase copyWith({
    String? id,
    String? patientId,
    String? service,
    EntryMode? entryMode,
    CaseStatus? status,
    DateTime? entryDate,
    DateTime? exitDate,
    String? mainDiagnosis,
    String? diagnosisCode,
    String? roomNumber,
    String? bedNumber,
    String? responsibleDoctorId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? vitalSigns,
  }) {
    return HospitalCase(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      service: service ?? this.service,
      entryMode: entryMode ?? this.entryMode,
      status: status ?? this.status,
      entryDate: entryDate ?? this.entryDate,
      exitDate: exitDate ?? this.exitDate,
      mainDiagnosis: mainDiagnosis ?? this.mainDiagnosis,
      diagnosisCode: diagnosisCode ?? this.diagnosisCode,
      roomNumber: roomNumber ?? this.roomNumber,
      bedNumber: bedNumber ?? this.bedNumber,
      responsibleDoctorId: responsibleDoctorId ?? this.responsibleDoctorId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      vitalSigns: vitalSigns ?? this.vitalSigns,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'service': service,
      'entryMode': entryMode.name,
      'status': status.name,
      'entryDate': entryDate.toIso8601String(),
      'exitDate': exitDate?.toIso8601String(),
      'mainDiagnosis': mainDiagnosis,
      'diagnosisCode': diagnosisCode,
      'roomNumber': roomNumber,
      'bedNumber': bedNumber,
      'responsibleDoctorId': responsibleDoctorId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'vitalSigns': vitalSigns,
    };
  }

  factory HospitalCase.fromMap(Map<String, dynamic> map) {
    return HospitalCase(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      service: map['service'] as String,
      entryMode: EntryMode.values.firstWhere(
        (e) => e.name == map['entryMode'],
        orElse: () => EntryMode.scheduled,
      ),
      status: CaseStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => CaseStatus.admission,
      ),
      entryDate: DateTime.parse(map['entryDate'] as String),
      exitDate: map['exitDate'] != null
          ? DateTime.parse(map['exitDate'] as String)
          : null,
      mainDiagnosis: map['mainDiagnosis'] as String?,
      diagnosisCode: map['diagnosisCode'] as String?,
      roomNumber: map['roomNumber'] as String?,
      bedNumber: map['bedNumber'] as String?,
      responsibleDoctorId: map['responsibleDoctorId'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      createdBy: map['createdBy'] as String,
      vitalSigns: map['vitalSigns'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'service': service,
      'entryMode': entryMode.name,
      'status': status.name,
      'entryDate': entryDate,
      'exitDate': exitDate,
      'mainDiagnosis': mainDiagnosis,
      'diagnosisCode': diagnosisCode,
      'roomNumber': roomNumber,
      'bedNumber': bedNumber,
      'responsibleDoctorId': responsibleDoctorId,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'vitalSigns': vitalSigns,
    };
  }

  /// Create from Firestore document
  factory HospitalCase.fromFirestore(String docId, Map<String, dynamic> data) {
    return HospitalCase(
      id: docId,
      patientId: data['patientId'] as String? ?? '',
      service: data['service'] as String? ?? '',
      entryMode: EntryMode.values.firstWhere(
        (e) => e.name == data['entryMode'],
        orElse: () => EntryMode.scheduled,
      ),
      status: CaseStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => CaseStatus.admission,
      ),
      entryDate: (data['entryDate'] as dynamic)?.toDate() ?? DateTime.now(),
      exitDate: (data['exitDate'] as dynamic)?.toDate(),
      mainDiagnosis: data['mainDiagnosis'] as String?,
      diagnosisCode: data['diagnosisCode'] as String?,
      roomNumber: data['roomNumber'] as String?,
      bedNumber: data['bedNumber'] as String?,
      responsibleDoctorId: data['responsibleDoctorId'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      vitalSigns: data['vitalSigns'] != null
          ? Map<String, dynamic>.from(data['vitalSigns'] as Map)
          : null,
    );
  }

  @override
  String toString() {
    return 'HospitalCase(id: $id, patientId: $patientId, status: ${status.label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HospitalCase && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
