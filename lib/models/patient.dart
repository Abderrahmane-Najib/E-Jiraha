/// Gender enumeration
enum Gender {
  male,
  female,
}

extension GenderExtension on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Masculin';
      case Gender.female:
        return 'Féminin';
    }
  }

  String get abbreviation {
    switch (this) {
      case Gender.male:
        return 'M';
      case Gender.female:
        return 'F';
    }
  }
}

/// Blood type enumeration
enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
  unknown,
}

extension BloodTypeExtension on BloodType {
  String get label {
    switch (this) {
      case BloodType.aPositive:
        return 'A+';
      case BloodType.aNegative:
        return 'A-';
      case BloodType.bPositive:
        return 'B+';
      case BloodType.bNegative:
        return 'B-';
      case BloodType.abPositive:
        return 'AB+';
      case BloodType.abNegative:
        return 'AB-';
      case BloodType.oPositive:
        return 'O+';
      case BloodType.oNegative:
        return 'O-';
      case BloodType.unknown:
        return 'Inconnu';
    }
  }
}

/// Patient model
class Patient {
  final String id;
  final String fullName;
  final String cin;
  final Gender gender;
  final DateTime dateOfBirth;
  final String address;
  final String phone;
  final String? email;
  final BloodType? bloodType;
  final List<String> allergies;
  final List<String> antecedents;
  final List<String> currentTreatments;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? insuranceNumber;
  final String? cinImageFront;
  final String? cinImageBack;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const Patient({
    required this.id,
    required this.fullName,
    required this.cin,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.phone,
    this.email,
    this.bloodType,
    this.allergies = const [],
    this.antecedents = const [],
    this.currentTreatments = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.insuranceNumber,
    this.cinImageFront,
    this.cinImageBack,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }

  Patient copyWith({
    String? id,
    String? fullName,
    String? cin,
    Gender? gender,
    DateTime? dateOfBirth,
    String? address,
    String? phone,
    String? email,
    BloodType? bloodType,
    List<String>? allergies,
    List<String>? antecedents,
    List<String>? currentTreatments,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? insuranceNumber,
    String? cinImageFront,
    String? cinImageBack,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      cin: cin ?? this.cin,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      antecedents: antecedents ?? this.antecedents,
      currentTreatments: currentTreatments ?? this.currentTreatments,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      cinImageFront: cinImageFront ?? this.cinImageFront,
      cinImageBack: cinImageBack ?? this.cinImageBack,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'cin': cin,
      'gender': gender.name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'address': address,
      'phone': phone,
      'email': email,
      'bloodType': bloodType?.name,
      'allergies': allergies.join(','),
      'antecedents': antecedents.join(','),
      'currentTreatments': currentTreatments.join(','),
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'insuranceNumber': insuranceNumber,
      'cinImageFront': cinImageFront,
      'cinImageBack': cinImageBack,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      cin: map['cin'] as String,
      gender: Gender.values.firstWhere(
        (g) => g.name == map['gender'],
        orElse: () => Gender.male,
      ),
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
      address: map['address'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      bloodType: map['bloodType'] != null
          ? BloodType.values.firstWhere(
              (b) => b.name == map['bloodType'],
              orElse: () => BloodType.unknown,
            )
          : null,
      allergies: (map['allergies'] as String?)?.isNotEmpty == true
          ? (map['allergies'] as String).split(',')
          : [],
      antecedents: (map['antecedents'] as String?)?.isNotEmpty == true
          ? (map['antecedents'] as String).split(',')
          : [],
      currentTreatments:
          (map['currentTreatments'] as String?)?.isNotEmpty == true
              ? (map['currentTreatments'] as String).split(',')
              : [],
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      insuranceNumber: map['insuranceNumber'] as String?,
      cinImageFront: map['cinImageFront'] as String?,
      cinImageBack: map['cinImageBack'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      createdBy: map['createdBy'] as String,
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'cin': cin,
      'gender': gender.name,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'phone': phone,
      'email': email,
      'bloodType': bloodType?.name,
      'allergies': allergies,
      'antecedents': antecedents,
      'currentTreatments': currentTreatments,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'insuranceNumber': insuranceNumber,
      'cinImageFront': cinImageFront,
      'cinImageBack': cinImageBack,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
    };
  }

  /// Create from Firestore document
  factory Patient.fromFirestore(String docId, Map<String, dynamic> data) {
    return Patient(
      id: docId,
      fullName: data['fullName'] as String? ?? '',
      cin: data['cin'] as String? ?? '',
      gender: Gender.values.firstWhere(
        (g) => g.name == data['gender'],
        orElse: () => Gender.male,
      ),
      dateOfBirth: (data['dateOfBirth'] as dynamic)?.toDate() ?? DateTime.now(),
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String?,
      bloodType: data['bloodType'] != null
          ? BloodType.values.firstWhere(
              (b) => b.name == data['bloodType'],
              orElse: () => BloodType.unknown,
            )
          : null,
      allergies: List<String>.from(data['allergies'] ?? []),
      antecedents: List<String>.from(data['antecedents'] ?? []),
      currentTreatments: List<String>.from(data['currentTreatments'] ?? []),
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      insuranceNumber: data['insuranceNumber'] as String?,
      cinImageFront: data['cinImageFront'] as String?,
      cinImageBack: data['cinImageBack'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'Patient(id: $id, fullName: $fullName, cin: $cin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Patient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
