/// Checklist type
enum ChecklistType {
  preop,
  timeout,
  postop,
  discharge,
  daily,
}

extension ChecklistTypeExtension on ChecklistType {
  String get label {
    switch (this) {
      case ChecklistType.preop:
        return 'Checklist Pré-opératoire';
      case ChecklistType.timeout:
        return 'Time-out Sécurité';
      case ChecklistType.postop:
        return 'Checklist Post-opératoire';
      case ChecklistType.discharge:
        return 'Checklist Sortie';
      case ChecklistType.daily:
        return 'Checklist Journalière';
    }
  }
}

/// Checklist item status
enum ChecklistItemStatus {
  pending,
  done,
  notApplicable,
  notDone,
}

extension ChecklistItemStatusExtension on ChecklistItemStatus {
  String get label {
    switch (this) {
      case ChecklistItemStatus.pending:
        return 'En attente';
      case ChecklistItemStatus.done:
        return 'Fait';
      case ChecklistItemStatus.notApplicable:
        return 'Non applicable';
      case ChecklistItemStatus.notDone:
        return 'Non fait';
    }
  }
}

/// Individual checklist item
class ChecklistItem {
  final String id;
  final String label;
  final String? description;
  final ChecklistItemStatus status;
  final DateTime? completedAt;
  final String? completedBy;
  final String? notes;
  final bool isRequired;

  const ChecklistItem({
    required this.id,
    required this.label,
    this.description,
    this.status = ChecklistItemStatus.pending,
    this.completedAt,
    this.completedBy,
    this.notes,
    this.isRequired = true,
  });

  bool get isCompleted =>
      status == ChecklistItemStatus.done ||
      status == ChecklistItemStatus.notApplicable;

  ChecklistItem copyWith({
    String? id,
    String? label,
    String? description,
    ChecklistItemStatus? status,
    DateTime? completedAt,
    String? completedBy,
    String? notes,
    bool? isRequired,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      notes: notes ?? this.notes,
      isRequired: isRequired ?? this.isRequired,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'description': description,
      'status': status.name,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
      'notes': notes,
      'isRequired': isRequired ? 1 : 0,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      label: map['label'] as String,
      description: map['description'] as String?,
      status: ChecklistItemStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ChecklistItemStatus.pending,
      ),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      completedBy: map['completedBy'] as String?,
      notes: map['notes'] as String?,
      isRequired: map['isRequired'] == 1,
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'label': label,
      'description': description,
      'status': status.name,
      'completedAt': completedAt,
      'completedBy': completedBy,
      'notes': notes,
      'isRequired': isRequired,
    };
  }

  /// Create from Firestore data
  factory ChecklistItem.fromFirestore(Map<String, dynamic> data) {
    return ChecklistItem(
      id: data['id'] as String? ?? '',
      label: data['label'] as String? ?? '',
      description: data['description'] as String?,
      status: ChecklistItemStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ChecklistItemStatus.pending,
      ),
      completedAt: (data['completedAt'] as dynamic)?.toDate(),
      completedBy: data['completedBy'] as String?,
      notes: data['notes'] as String?,
      isRequired: data['isRequired'] as bool? ?? true,
    );
  }
}

/// Complete checklist model
class Checklist {
  final String id;
  final String caseId;
  final ChecklistType type;
  final List<ChecklistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;

  const Checklist({
    required this.id,
    required this.caseId,
    required this.type,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
  });

  double get completionPercentage {
    if (items.isEmpty) return 0;
    final completedItems = items.where((item) => item.isCompleted).length;
    return completedItems / items.length;
  }

  int get pendingCount =>
      items.where((item) => !item.isCompleted && item.isRequired).length;

  Checklist copyWith({
    String? id,
    String? caseId,
    ChecklistType? type,
    List<ChecklistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return Checklist(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      type: type ?? this.type,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caseId': caseId,
      'type': type.name,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'isCompleted': isCompleted ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
    };
  }

  factory Checklist.fromMap(Map<String, dynamic> map) {
    return Checklist(
      id: map['id'] as String,
      caseId: map['caseId'] as String,
      type: ChecklistType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ChecklistType.preop,
      ),
      items: (map['items'] as List)
          .map((e) => ChecklistItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      createdBy: map['createdBy'] as String,
      isCompleted: map['isCompleted'] == 1,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      completedBy: map['completedBy'] as String?,
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'caseId': caseId,
      'type': type.name,
      'items': items.map((e) => e.toFirestore()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'completedBy': completedBy,
    };
  }

  /// Create from Firestore document
  factory Checklist.fromFirestore(String docId, Map<String, dynamic> data) {
    return Checklist(
      id: docId,
      caseId: data['caseId'] as String? ?? '',
      type: ChecklistType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ChecklistType.preop,
      ),
      items: (data['items'] as List?)
              ?.map((e) => ChecklistItem.fromFirestore(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
      completedAt: (data['completedAt'] as dynamic)?.toDate(),
      completedBy: data['completedBy'] as String?,
    );
  }

  /// Factory to create a pre-op checklist with standard items
  factory Checklist.createPreopChecklist({
    required String id,
    required String caseId,
    required String createdBy,
  }) {
    return Checklist(
      id: id,
      caseId: caseId,
      type: ChecklistType.preop,
      items: [
        ChecklistItem(
          id: '${id}_1',
          label: 'Jeûne vérifié (≥6h solides, ≥2h liquides clairs)',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_2',
          label: 'Bilan biologique validé',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_3',
          label: 'ECG validé (si indiqué)',
          isRequired: false,
        ),
        ChecklistItem(
          id: '${id}_4',
          label: 'Radiographie thoracique validée (si indiquée)',
          isRequired: false,
        ),
        ChecklistItem(
          id: '${id}_5',
          label: 'Groupe sanguin et RAI',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_6',
          label: 'Prophylaxie antibiotique prescrite',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_7',
          label: 'Préparation cutanée effectuée',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_8',
          label: 'Prémédication administrée',
          isRequired: false,
        ),
        ChecklistItem(
          id: '${id}_9',
          label: 'Voie veineuse périphérique posée',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_10',
          label: 'Consentement éclairé signé',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_11',
          label: 'Bracelet d\'identification vérifié',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_12',
          label: 'Bijoux/prothèses retirés',
          isRequired: true,
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  /// Factory to create a time-out checklist with standard items
  factory Checklist.createTimeoutChecklist({
    required String id,
    required String caseId,
    required String createdBy,
  }) {
    return Checklist(
      id: id,
      caseId: caseId,
      type: ChecklistType.timeout,
      items: [
        ChecklistItem(
          id: '${id}_1',
          label: 'Identité du patient vérifiée',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_2',
          label: 'Site opératoire marqué et confirmé',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_3',
          label: 'Acte chirurgical prévu confirmé',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_4',
          label: 'Position du patient correcte',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_5',
          label: 'Matériel spécifique disponible',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_6',
          label: 'Antibioprophylaxie administrée',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_7',
          label: 'Allergie vérifiée',
          isRequired: true,
        ),
        ChecklistItem(
          id: '${id}_8',
          label: 'Imagerie affichée',
          isRequired: false,
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );
  }
}
