/// ASA Physical Status Classification
enum AsaScore {
  asa1,
  asa2,
  asa3,
  asa4,
  asa5,
  asa6,
}

extension AsaScoreExtension on AsaScore {
  String get label {
    switch (this) {
      case AsaScore.asa1:
        return 'ASA I';
      case AsaScore.asa2:
        return 'ASA II';
      case AsaScore.asa3:
        return 'ASA III';
      case AsaScore.asa4:
        return 'ASA IV';
      case AsaScore.asa5:
        return 'ASA V';
      case AsaScore.asa6:
        return 'ASA VI';
    }
  }

  String get description {
    switch (this) {
      case AsaScore.asa1:
        return 'Patient en bonne santé';
      case AsaScore.asa2:
        return 'Maladie systémique légère';
      case AsaScore.asa3:
        return 'Maladie systémique sévère';
      case AsaScore.asa4:
        return 'Maladie systémique menaçant le pronostic vital';
      case AsaScore.asa5:
        return 'Patient moribond';
      case AsaScore.asa6:
        return 'Patient en état de mort cérébrale';
    }
  }

  int get riskLevel {
    switch (this) {
      case AsaScore.asa1:
        return 1;
      case AsaScore.asa2:
        return 2;
      case AsaScore.asa3:
        return 3;
      case AsaScore.asa4:
        return 4;
      case AsaScore.asa5:
        return 5;
      case AsaScore.asa6:
        return 6;
    }
  }
}

/// Anesthesia type
enum AnesthesiaType {
  general,
  spinal,
  epidural,
  regional,
  local,
  sedation,
}

extension AnesthesiaTypeExtension on AnesthesiaType {
  String get label {
    switch (this) {
      case AnesthesiaType.general:
        return 'Anesthésie générale';
      case AnesthesiaType.spinal:
        return 'Rachianesthésie';
      case AnesthesiaType.epidural:
        return 'Péridurale';
      case AnesthesiaType.regional:
        return 'Anesthésie locorégionale';
      case AnesthesiaType.local:
        return 'Anesthésie locale';
      case AnesthesiaType.sedation:
        return 'Sédation';
    }
  }
}

/// Mallampati classification for airway assessment
enum MallampatiScore {
  class1,
  class2,
  class3,
  class4,
}

extension MallampatiScoreExtension on MallampatiScore {
  String get label {
    switch (this) {
      case MallampatiScore.class1:
        return 'Classe I';
      case MallampatiScore.class2:
        return 'Classe II';
      case MallampatiScore.class3:
        return 'Classe III';
      case MallampatiScore.class4:
        return 'Classe IV';
    }
  }

  String get description {
    switch (this) {
      case MallampatiScore.class1:
        return 'Palais mou, luette, piliers visibles';
      case MallampatiScore.class2:
        return 'Palais mou, luette partiellement visible';
      case MallampatiScore.class3:
        return 'Palais mou, base de la luette visible';
      case MallampatiScore.class4:
        return 'Palais mou non visible';
    }
  }
}

/// Pre-anesthesia evaluation model
class AnesthesiaEvaluation {
  final String id;
  final String caseId;
  final String patientId;
  final String anesthesiologistId;
  final AsaScore asaScore;
  final AnesthesiaType? proposedAnesthesiaType;
  final MallampatiScore? mallampatiScore;
  final double? weight;
  final double? height;
  final double? bmi;

  // Medical history
  final List<String> comorbidities;
  final List<String> previousSurgeries;
  final List<String> previousAnesthesiaComplications;
  final bool difficultIntubationHistory;

  // Current assessment
  final String? cardiacEvaluation;
  final String? respiratoryEvaluation;
  final String? renalFunction;
  final String? hepaticFunction;
  final String? coagulationStatus;

  // Preop orders
  final bool fastingConfirmed;
  final String? premedication;
  final String? antibioticProphylaxis;
  final String? thromboprophylaxis;

  // Risk assessment
  final String? riskAssessment;
  final String? specificPrecautions;

  // Consent
  final bool consentObtained;
  final String? consentImagePath;
  final DateTime? consentDate;

  final String? notes;
  final DateTime evaluationDate;
  final bool isValidated;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnesthesiaEvaluation({
    required this.id,
    required this.caseId,
    required this.patientId,
    required this.anesthesiologistId,
    required this.asaScore,
    this.proposedAnesthesiaType,
    this.mallampatiScore,
    this.weight,
    this.height,
    this.bmi,
    this.comorbidities = const [],
    this.previousSurgeries = const [],
    this.previousAnesthesiaComplications = const [],
    this.difficultIntubationHistory = false,
    this.cardiacEvaluation,
    this.respiratoryEvaluation,
    this.renalFunction,
    this.hepaticFunction,
    this.coagulationStatus,
    this.fastingConfirmed = false,
    this.premedication,
    this.antibioticProphylaxis,
    this.thromboprophylaxis,
    this.riskAssessment,
    this.specificPrecautions,
    this.consentObtained = false,
    this.consentImagePath,
    this.consentDate,
    this.notes,
    required this.evaluationDate,
    this.isValidated = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double? get calculatedBmi {
    if (weight != null && height != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return bmi;
  }

  AnesthesiaEvaluation copyWith({
    String? id,
    String? caseId,
    String? patientId,
    String? anesthesiologistId,
    AsaScore? asaScore,
    AnesthesiaType? proposedAnesthesiaType,
    MallampatiScore? mallampatiScore,
    double? weight,
    double? height,
    double? bmi,
    List<String>? comorbidities,
    List<String>? previousSurgeries,
    List<String>? previousAnesthesiaComplications,
    bool? difficultIntubationHistory,
    String? cardiacEvaluation,
    String? respiratoryEvaluation,
    String? renalFunction,
    String? hepaticFunction,
    String? coagulationStatus,
    bool? fastingConfirmed,
    String? premedication,
    String? antibioticProphylaxis,
    String? thromboprophylaxis,
    String? riskAssessment,
    String? specificPrecautions,
    bool? consentObtained,
    String? consentImagePath,
    DateTime? consentDate,
    String? notes,
    DateTime? evaluationDate,
    bool? isValidated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnesthesiaEvaluation(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      patientId: patientId ?? this.patientId,
      anesthesiologistId: anesthesiologistId ?? this.anesthesiologistId,
      asaScore: asaScore ?? this.asaScore,
      proposedAnesthesiaType:
          proposedAnesthesiaType ?? this.proposedAnesthesiaType,
      mallampatiScore: mallampatiScore ?? this.mallampatiScore,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      comorbidities: comorbidities ?? this.comorbidities,
      previousSurgeries: previousSurgeries ?? this.previousSurgeries,
      previousAnesthesiaComplications:
          previousAnesthesiaComplications ?? this.previousAnesthesiaComplications,
      difficultIntubationHistory:
          difficultIntubationHistory ?? this.difficultIntubationHistory,
      cardiacEvaluation: cardiacEvaluation ?? this.cardiacEvaluation,
      respiratoryEvaluation:
          respiratoryEvaluation ?? this.respiratoryEvaluation,
      renalFunction: renalFunction ?? this.renalFunction,
      hepaticFunction: hepaticFunction ?? this.hepaticFunction,
      coagulationStatus: coagulationStatus ?? this.coagulationStatus,
      fastingConfirmed: fastingConfirmed ?? this.fastingConfirmed,
      premedication: premedication ?? this.premedication,
      antibioticProphylaxis:
          antibioticProphylaxis ?? this.antibioticProphylaxis,
      thromboprophylaxis: thromboprophylaxis ?? this.thromboprophylaxis,
      riskAssessment: riskAssessment ?? this.riskAssessment,
      specificPrecautions: specificPrecautions ?? this.specificPrecautions,
      consentObtained: consentObtained ?? this.consentObtained,
      consentImagePath: consentImagePath ?? this.consentImagePath,
      consentDate: consentDate ?? this.consentDate,
      notes: notes ?? this.notes,
      evaluationDate: evaluationDate ?? this.evaluationDate,
      isValidated: isValidated ?? this.isValidated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caseId': caseId,
      'patientId': patientId,
      'anesthesiologistId': anesthesiologistId,
      'asaScore': asaScore.name,
      'proposedAnesthesiaType': proposedAnesthesiaType?.name,
      'mallampatiScore': mallampatiScore?.name,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'comorbidities': comorbidities.join(','),
      'previousSurgeries': previousSurgeries.join(','),
      'previousAnesthesiaComplications': previousAnesthesiaComplications.join(','),
      'difficultIntubationHistory': difficultIntubationHistory ? 1 : 0,
      'cardiacEvaluation': cardiacEvaluation,
      'respiratoryEvaluation': respiratoryEvaluation,
      'renalFunction': renalFunction,
      'hepaticFunction': hepaticFunction,
      'coagulationStatus': coagulationStatus,
      'fastingConfirmed': fastingConfirmed ? 1 : 0,
      'premedication': premedication,
      'antibioticProphylaxis': antibioticProphylaxis,
      'thromboprophylaxis': thromboprophylaxis,
      'riskAssessment': riskAssessment,
      'specificPrecautions': specificPrecautions,
      'consentObtained': consentObtained ? 1 : 0,
      'consentImagePath': consentImagePath,
      'consentDate': consentDate?.toIso8601String(),
      'notes': notes,
      'evaluationDate': evaluationDate.toIso8601String(),
      'isValidated': isValidated ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AnesthesiaEvaluation.fromMap(Map<String, dynamic> map) {
    return AnesthesiaEvaluation(
      id: map['id'] as String,
      caseId: map['caseId'] as String,
      patientId: map['patientId'] as String,
      anesthesiologistId: map['anesthesiologistId'] as String,
      asaScore: AsaScore.values.firstWhere(
        (a) => a.name == map['asaScore'],
        orElse: () => AsaScore.asa1,
      ),
      proposedAnesthesiaType: map['proposedAnesthesiaType'] != null
          ? AnesthesiaType.values.firstWhere(
              (t) => t.name == map['proposedAnesthesiaType'],
              orElse: () => AnesthesiaType.general,
            )
          : null,
      mallampatiScore: map['mallampatiScore'] != null
          ? MallampatiScore.values.firstWhere(
              (m) => m.name == map['mallampatiScore'],
              orElse: () => MallampatiScore.class1,
            )
          : null,
      weight: map['weight'] as double?,
      height: map['height'] as double?,
      bmi: map['bmi'] as double?,
      comorbidities: (map['comorbidities'] as String?)?.isNotEmpty == true
          ? (map['comorbidities'] as String).split(',')
          : [],
      previousSurgeries: (map['previousSurgeries'] as String?)?.isNotEmpty == true
          ? (map['previousSurgeries'] as String).split(',')
          : [],
      previousAnesthesiaComplications:
          (map['previousAnesthesiaComplications'] as String?)?.isNotEmpty == true
              ? (map['previousAnesthesiaComplications'] as String).split(',')
              : [],
      difficultIntubationHistory: map['difficultIntubationHistory'] == 1,
      cardiacEvaluation: map['cardiacEvaluation'] as String?,
      respiratoryEvaluation: map['respiratoryEvaluation'] as String?,
      renalFunction: map['renalFunction'] as String?,
      hepaticFunction: map['hepaticFunction'] as String?,
      coagulationStatus: map['coagulationStatus'] as String?,
      fastingConfirmed: map['fastingConfirmed'] == 1,
      premedication: map['premedication'] as String?,
      antibioticProphylaxis: map['antibioticProphylaxis'] as String?,
      thromboprophylaxis: map['thromboprophylaxis'] as String?,
      riskAssessment: map['riskAssessment'] as String?,
      specificPrecautions: map['specificPrecautions'] as String?,
      consentObtained: map['consentObtained'] == 1,
      consentImagePath: map['consentImagePath'] as String?,
      consentDate: map['consentDate'] != null
          ? DateTime.parse(map['consentDate'] as String)
          : null,
      notes: map['notes'] as String?,
      evaluationDate: DateTime.parse(map['evaluationDate'] as String),
      isValidated: map['isValidated'] == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'caseId': caseId,
      'patientId': patientId,
      'anesthesiologistId': anesthesiologistId,
      'asaScore': asaScore.name,
      'proposedAnesthesiaType': proposedAnesthesiaType?.name,
      'mallampatiScore': mallampatiScore?.name,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'comorbidities': comorbidities,
      'previousSurgeries': previousSurgeries,
      'previousAnesthesiaComplications': previousAnesthesiaComplications,
      'difficultIntubationHistory': difficultIntubationHistory,
      'cardiacEvaluation': cardiacEvaluation,
      'respiratoryEvaluation': respiratoryEvaluation,
      'renalFunction': renalFunction,
      'hepaticFunction': hepaticFunction,
      'coagulationStatus': coagulationStatus,
      'fastingConfirmed': fastingConfirmed,
      'premedication': premedication,
      'antibioticProphylaxis': antibioticProphylaxis,
      'thromboprophylaxis': thromboprophylaxis,
      'riskAssessment': riskAssessment,
      'specificPrecautions': specificPrecautions,
      'consentObtained': consentObtained,
      'consentImagePath': consentImagePath,
      'consentDate': consentDate,
      'notes': notes,
      'evaluationDate': evaluationDate,
      'isValidated': isValidated,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create from Firestore document
  factory AnesthesiaEvaluation.fromFirestore(String docId, Map<String, dynamic> data) {
    return AnesthesiaEvaluation(
      id: docId,
      caseId: data['caseId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      anesthesiologistId: data['anesthesiologistId'] as String? ?? '',
      asaScore: AsaScore.values.firstWhere(
        (a) => a.name == data['asaScore'],
        orElse: () => AsaScore.asa1,
      ),
      proposedAnesthesiaType: data['proposedAnesthesiaType'] != null
          ? AnesthesiaType.values.firstWhere(
              (t) => t.name == data['proposedAnesthesiaType'],
              orElse: () => AnesthesiaType.general,
            )
          : null,
      mallampatiScore: data['mallampatiScore'] != null
          ? MallampatiScore.values.firstWhere(
              (m) => m.name == data['mallampatiScore'],
              orElse: () => MallampatiScore.class1,
            )
          : null,
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      bmi: (data['bmi'] as num?)?.toDouble(),
      comorbidities: List<String>.from(data['comorbidities'] ?? []),
      previousSurgeries: List<String>.from(data['previousSurgeries'] ?? []),
      previousAnesthesiaComplications: List<String>.from(data['previousAnesthesiaComplications'] ?? []),
      difficultIntubationHistory: data['difficultIntubationHistory'] as bool? ?? false,
      cardiacEvaluation: data['cardiacEvaluation'] as String?,
      respiratoryEvaluation: data['respiratoryEvaluation'] as String?,
      renalFunction: data['renalFunction'] as String?,
      hepaticFunction: data['hepaticFunction'] as String?,
      coagulationStatus: data['coagulationStatus'] as String?,
      fastingConfirmed: data['fastingConfirmed'] as bool? ?? false,
      premedication: data['premedication'] as String?,
      antibioticProphylaxis: data['antibioticProphylaxis'] as String?,
      thromboprophylaxis: data['thromboprophylaxis'] as String?,
      riskAssessment: data['riskAssessment'] as String?,
      specificPrecautions: data['specificPrecautions'] as String?,
      consentObtained: data['consentObtained'] as bool? ?? false,
      consentImagePath: data['consentImagePath'] as String?,
      consentDate: (data['consentDate'] as dynamic)?.toDate(),
      notes: data['notes'] as String?,
      evaluationDate: (data['evaluationDate'] as dynamic)?.toDate() ?? DateTime.now(),
      isValidated: data['isValidated'] as bool? ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AnesthesiaEvaluation(id: $id, asaScore: ${asaScore.label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnesthesiaEvaluation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
