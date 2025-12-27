/// Ejiraha app strings - French localization
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'e-jiraha';
  static const String appTagline = 'Parcours Patient Chirurgie';

  // Auth & Roles
  static const String selectRole = 'Sélectionner votre rôle';
  static const String selectRoleSubtitle = 'Choisissez votre profil pour accéder à l\'application';
  static const String secretary = 'Secrétaire';
  static const String secretaryDesc = 'Admissions et dossiers patients';
  static const String nurse = 'Infirmier(ère)';
  static const String nurseDesc = 'Triage et préparation pré-op';
  static const String surgeon = 'Chirurgien';
  static const String surgeonDesc = 'Consultations et interventions';
  static const String anesthesiologist = 'Anesthésiste';
  static const String anesthesiologistDesc = 'Évaluation pré-opératoire';
  static const String admin = 'Administrateur';
  static const String adminDesc = 'Gestion des utilisateurs et paramètres';
  static const String login = 'Se connecter';
  static const String logout = 'Se déconnecter';
  static const String email = 'Email';
  static const String password = 'Mot de passe';

  // Navigation
  static const String home = 'Accueil';
  static const String admission = 'Admission';
  static const String bloc = 'Bloc';
  static const String postop = 'Postop';
  static const String discharge = 'Sortie';
  static const String consultation = 'Consultation';
  static const String checklist = 'Checklist';

  // Dashboard
  static const String admissionDashboard = 'Admission Dashboard';
  static const String todayPatients = 'Patients du jour';
  static const String pendingAdmissions = 'Admissions en attente';
  static const String scheduledSurgeries = 'Interventions programmées';
  static const String urgentCases = 'Cas urgents';

  // Patient
  static const String newPatient = 'Nouveau Patient';
  static const String patientFile = 'Fiche Patient (Civil)';
  static const String identitySection = 'Identité & État Civil';
  static const String identitySubtitle = 'Création de l\'identité permanente au CHU';
  static const String idDocument = 'DOCUMENTS D\'IDENTITÉ (CIN)';
  static const String scanCIN = 'Scanner ou Importer la carte CIN (Recto/Verso)';
  static const String fullName = 'NOM & PRÉNOM';
  static const String fullNameHint = 'Ex: Amina Mansouri';
  static const String cinNumber = 'N° CIN';
  static const String cinHint = 'AB123456';
  static const String sex = 'SEXE';
  static const String male = 'Masculin';
  static const String female = 'Féminin';
  static const String dateOfBirth = 'DATE DE NAISSANCE';
  static const String address = 'ADRESSE DE RÉSIDENCE';
  static const String addressHint = 'N°, Rue, Quartier, Ville...';
  static const String phone = 'TÉLÉPHONE MOBILE';
  static const String phoneHint = '06XXXXXXXX';
  static const String savePatient = 'Enregistrer le Profil Patient';
  static const String patientList = 'Liste des Patients';
  static const String searchPatient = 'Rechercher un patient...';
  static const String patientDetails = 'Détails du Patient';
  static const String allergies = 'Allergies';
  static const String antecedents = 'Antécédents';
  static const String currentTreatments = 'Traitements en cours';

  // Medical File
  static const String hospitalFile = 'Dossier Hospitalier';
  static const String admissionMode = 'Mode d\'entrée';
  static const String scheduled = 'Programmée';
  static const String emergency = 'Urgence';
  static const String service = 'Service';
  static const String entryDate = 'Date d\'entrée';
  static const String exitDate = 'Date de sortie';
  static const String mainDiagnosis = 'Diagnostic principal';

  // Consultation
  static const String anamnesis = 'Anamnèse';
  static const String clinicalExam = 'Examen clinique';
  static const String hypothesis = 'Hypothèse diagnostique';
  static const String examPlan = 'Plan d\'examens';
  static const String reason = 'Motif de consultation';

  // Exams
  static const String examResults = 'Résultats d\'examens';
  static const String pending = 'En attente';
  static const String received = 'Reçu';
  static const String validated = 'Validé';
  static const String biology = 'Biologie';
  static const String imaging = 'Imagerie';

  // Surgery
  static const String surgeryIndication = 'Indication opératoire';
  static const String surgeryType = 'Type d\'acte';
  static const String surgeryDate = 'Date d\'intervention';
  static const String surgeryRoom = 'Salle';
  static const String surgeryTeam = 'Équipe';
  static const String surgeryReport = 'Compte rendu opératoire';
  static const String consent = 'Consentement';

  // Anesthesia
  static const String asaScore = 'Score ASA';
  static const String preOpConsultation = 'Consultation pré-anesthésique';
  static const String preOpChecklist = 'Checklist pré-opératoire';
  static const String fasting = 'Jeûne';
  static const String antibioticProphylaxis = 'Prophylaxie ATB';
  static const String skinPreparation = 'Préparation cutanée';

  // Postop
  static const String vitalSigns = 'Constantes vitales';
  static const String painScore = 'Score douleur';
  static const String woundCare = 'Cicatrisation';
  static const String drains = 'Drains';
  static const String diuresis = 'Diurèse';
  static const String mobilization = 'Mobilisation';
  static const String nutrition = 'Alimentation';

  // Discharge
  static const String dischargeLetter = 'Lettre de sortie';
  static const String prescriptions = 'Ordonnances';
  static const String followUpAppointment = 'RDV de contrôle';
  static const String patientInstructions = 'Instructions patient';
  static const String warningSignsTitle = 'Signes d\'alerte';

  // Common Actions
  static const String save = 'Enregistrer';
  static const String cancel = 'Annuler';
  static const String edit = 'Modifier';
  static const String delete = 'Supprimer';
  static const String confirm = 'Confirmer';
  static const String back = 'Retour';
  static const String next = 'Suivant';
  static const String validate = 'Valider';
  static const String print = 'Imprimer';
  static const String export = 'Exporter';
  static const String search = 'Rechercher';
  static const String filter = 'Filtrer';
  static const String refresh = 'Actualiser';
  static const String add = 'Ajouter';
  static const String view = 'Voir';
  static const String done = 'Fait';
  static const String notDone = 'Non fait';

  // Messages
  static const String success = 'Succès';
  static const String error = 'Erreur';
  static const String warning = 'Attention';
  static const String info = 'Information';
  static const String loading = 'Chargement...';
  static const String noData = 'Aucune donnée';
  static const String requiredField = 'Ce champ est obligatoire';
  static const String savedSuccessfully = 'Enregistré avec succès';
  static const String deletedSuccessfully = 'Supprimé avec succès';
  static const String confirmDelete = 'Confirmer la suppression ?';

  // Time
  static const String today = 'Aujourd\'hui';
  static const String yesterday = 'Hier';
  static const String thisWeek = 'Cette semaine';
  static const String thisMonth = 'Ce mois';
}
