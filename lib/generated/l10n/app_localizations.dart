import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'SafeMind'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcome;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @orWith.
  ///
  /// In fr, this message translates to:
  /// **'Ou se connecter avec'**
  String get orWith;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas de compte ?'**
  String get noAccount;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte'**
  String get createAccount;

  /// No description provided for @emailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le mot de passe'**
  String get confirmPassword;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @signUpUsing.
  ///
  /// In fr, this message translates to:
  /// **'Ou s\'inscrire avec'**
  String get signUpUsing;

  /// No description provided for @whoAreYou.
  ///
  /// In fr, this message translates to:
  /// **'Qui êtes-vous ?'**
  String get whoAreYou;

  /// No description provided for @selectProfile.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre profil pour commencer'**
  String get selectProfile;

  /// No description provided for @doctor.
  ///
  /// In fr, this message translates to:
  /// **'Médecin'**
  String get doctor;

  /// No description provided for @patient.
  ///
  /// In fr, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @caregiver.
  ///
  /// In fr, this message translates to:
  /// **'Aide-soignant'**
  String get caregiver;

  /// No description provided for @patientProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil Patient'**
  String get patientProfile;

  /// No description provided for @identification.
  ///
  /// In fr, this message translates to:
  /// **'Identification'**
  String get identification;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get name;

  /// No description provided for @age.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get age;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @gender.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get male;

  /// No description provided for @female.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get female;

  /// No description provided for @diagnosis.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic'**
  String get diagnosis;

  /// No description provided for @symptoms.
  ///
  /// In fr, this message translates to:
  /// **'Symptômes'**
  String get symptoms;

  /// No description provided for @symptomsParkinson.
  ///
  /// In fr, this message translates to:
  /// **'Symptômes Parkinson :'**
  String get symptomsParkinson;

  /// No description provided for @symptomsAlzheimer.
  ///
  /// In fr, this message translates to:
  /// **'Symptômes Alzheimer :'**
  String get symptomsAlzheimer;

  /// No description provided for @rigidity.
  ///
  /// In fr, this message translates to:
  /// **'Rigidité musculaire'**
  String get rigidity;

  /// No description provided for @bradykinesia.
  ///
  /// In fr, this message translates to:
  /// **'Bradykinésie (Lenteur)'**
  String get bradykinesia;

  /// No description provided for @posturalInstability.
  ///
  /// In fr, this message translates to:
  /// **'Instabilité posturale'**
  String get posturalInstability;

  /// No description provided for @spatialDisorientation.
  ///
  /// In fr, this message translates to:
  /// **'Désorientation spatiale'**
  String get spatialDisorientation;

  /// No description provided for @memoryDisorder.
  ///
  /// In fr, this message translates to:
  /// **'Troubles de mémoire'**
  String get memoryDisorder;

  /// No description provided for @moodChanges.
  ///
  /// In fr, this message translates to:
  /// **'Changements d\'humeur'**
  String get moodChanges;

  /// No description provided for @sendToDoctor.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer au Médecin'**
  String get sendToDoctor;

  /// No description provided for @doctorCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Demandez le code au médecin depuis sa page \"Mon Profil\".'**
  String get doctorCodeHint;

  /// No description provided for @doctorCodeHint2.
  ///
  /// In fr, this message translates to:
  /// **'Code du médecin (ex: AB12CD34)'**
  String get doctorCodeHint2;

  /// No description provided for @requestSentConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée ! Le médecin va examiner le dossier.'**
  String get requestSentConfirm;

  /// No description provided for @doctorBtn.
  ///
  /// In fr, this message translates to:
  /// **'Médecin'**
  String get doctorBtn;

  /// No description provided for @continueBtn.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueBtn;

  /// No description provided for @sendDoctor.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée au médecin !'**
  String get sendDoctor;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire'**
  String get required;

  /// No description provided for @invalidAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge invalide (30–100)'**
  String get invalidAge;

  /// No description provided for @invalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide (ex: 0651234567)'**
  String get invalidPhone;

  /// No description provided for @dailyFollowUp.
  ///
  /// In fr, this message translates to:
  /// **'Suivi quotidien'**
  String get dailyFollowUp;

  /// No description provided for @medications.
  ///
  /// In fr, this message translates to:
  /// **'Médicaments'**
  String get medications;

  /// No description provided for @location.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get location;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter ?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @accompanying.
  ///
  /// In fr, this message translates to:
  /// **'Accompagnant de'**
  String get accompanying;

  /// No description provided for @noPatient.
  ///
  /// In fr, this message translates to:
  /// **'Aucun patient lié'**
  String get noPatient;

  /// No description provided for @notConnected.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous connecter'**
  String get notConnected;

  /// No description provided for @noPatientLinked.
  ///
  /// In fr, this message translates to:
  /// **'Aucun patient lié'**
  String get noPatientLinked;

  /// No description provided for @patientNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Données patient introuvables'**
  String get patientNotFound;

  /// No description provided for @connectionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion — réessayez'**
  String get connectionError;

  /// No description provided for @scanBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le code-barres'**
  String get scanBarcode;

  /// No description provided for @medicines.
  ///
  /// In fr, this message translates to:
  /// **'Médicaments'**
  String get medicines;

  /// No description provided for @noMedicineFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun médicament trouvé'**
  String get noMedicineFound;

  /// No description provided for @day.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get day;

  /// No description provided for @medicineFound.
  ///
  /// In fr, this message translates to:
  /// **'Médicament trouvé'**
  String get medicineFound;

  /// No description provided for @barcodeNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun médicament trouvé pour ce code'**
  String get barcodeNotFound;

  /// No description provided for @list.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get list;

  /// No description provided for @fillMedicine.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer le nom du médicament'**
  String get fillMedicine;

  /// No description provided for @addSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Ajout réussi'**
  String get addSuccess;

  /// No description provided for @inputFor.
  ///
  /// In fr, this message translates to:
  /// **'Saisie pour'**
  String get inputFor;

  /// No description provided for @medicineName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du médicament'**
  String get medicineName;

  /// No description provided for @dose.
  ///
  /// In fr, this message translates to:
  /// **'Dose'**
  String get dose;

  /// No description provided for @timesPerDay.
  ///
  /// In fr, this message translates to:
  /// **'fois par jour'**
  String get timesPerDay;

  /// No description provided for @addMore.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addMore;

  /// No description provided for @finish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get finish;

  /// No description provided for @planTasks.
  ///
  /// In fr, this message translates to:
  /// **'Planifier les tâches'**
  String get planTasks;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @noTasks.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche'**
  String get noTasks;

  /// No description provided for @addTask.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle tâche'**
  String get addTask;

  /// No description provided for @editTask.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la tâche'**
  String get editTask;

  /// No description provided for @title.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get title;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @sendToPatient.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer au patient'**
  String get sendToPatient;

  /// No description provided for @followUp.
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get followUp;

  /// No description provided for @errorLoading.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get errorLoading;

  /// No description provided for @patientTracking.
  ///
  /// In fr, this message translates to:
  /// **'Suivi du patient'**
  String get patientTracking;

  /// No description provided for @noTasksForDay.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche pour ce jour'**
  String get noTasksForDay;

  /// No description provided for @mon.
  ///
  /// In fr, this message translates to:
  /// **'Lun'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In fr, this message translates to:
  /// **'Ven'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In fr, this message translates to:
  /// **'Sam'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In fr, this message translates to:
  /// **'Dim'**
  String get sun;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @services.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @alzheimer.
  ///
  /// In fr, this message translates to:
  /// **'Alzheimer'**
  String get alzheimer;

  /// No description provided for @parkinson.
  ///
  /// In fr, this message translates to:
  /// **'Parkinson'**
  String get parkinson;

  /// No description provided for @nutrition.
  ///
  /// In fr, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @appointments.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous'**
  String get appointments;

  /// No description provided for @exercises.
  ///
  /// In fr, this message translates to:
  /// **'Exercices'**
  String get exercises;

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get myProfile;

  /// No description provided for @map.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get map;

  /// No description provided for @messages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @patientFollowUp.
  ///
  /// In fr, this message translates to:
  /// **'Suivi du patient'**
  String get patientFollowUp;

  /// No description provided for @addEmergency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence'**
  String get addEmergency;

  /// No description provided for @selectDisease.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la maladie'**
  String get selectDisease;

  /// No description provided for @searchMedicine.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un médicament'**
  String get searchMedicine;

  /// No description provided for @noMedicines.
  ///
  /// In fr, this message translates to:
  /// **'Aucun médicament'**
  String get noMedicines;

  /// No description provided for @noName.
  ///
  /// In fr, this message translates to:
  /// **'Sans nom'**
  String get noName;

  /// No description provided for @noLinkedPatient.
  ///
  /// In fr, this message translates to:
  /// **'Aucun patient lié'**
  String get noLinkedPatient;

  /// No description provided for @myTasks.
  ///
  /// In fr, this message translates to:
  /// **'Mes tâches'**
  String get myTasks;

  /// No description provided for @attempt.
  ///
  /// In fr, this message translates to:
  /// **'Tentative'**
  String get attempt;

  /// No description provided for @caregiver_profile_title.
  ///
  /// In fr, this message translates to:
  /// **'Profil aidant'**
  String get caregiver_profile_title;

  /// No description provided for @caregiver_welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue 👋'**
  String get caregiver_welcome;

  /// No description provided for @caregiver_welcome_sub.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez compléter vos informations'**
  String get caregiver_welcome_sub;

  /// No description provided for @caregiver_full_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get caregiver_full_name;

  /// No description provided for @caregiver_name_hint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre nom...'**
  String get caregiver_name_hint;

  /// No description provided for @caregiver_save_name.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get caregiver_save_name;

  /// No description provided for @caregiver_saving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get caregiver_saving;

  /// No description provided for @caregiver_account_info.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get caregiver_account_info;

  /// No description provided for @caregiver_email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get caregiver_email;

  /// No description provided for @caregiver_disease.
  ///
  /// In fr, this message translates to:
  /// **'Maladie suivie'**
  String get caregiver_disease;

  /// No description provided for @caregiver_disease_choose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get caregiver_disease_choose;

  /// No description provided for @caregiver_my_code.
  ///
  /// In fr, this message translates to:
  /// **'Mon code'**
  String get caregiver_my_code;

  /// No description provided for @caregiver_code_hint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez ce code'**
  String get caregiver_code_hint;

  /// No description provided for @caregiver_code_copied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get caregiver_code_copied;

  /// No description provided for @caregiver_linked_patient.
  ///
  /// In fr, this message translates to:
  /// **'Patient lié'**
  String get caregiver_linked_patient;

  /// No description provided for @caregiver_linked_doctor.
  ///
  /// In fr, this message translates to:
  /// **'Médecin lié'**
  String get caregiver_linked_doctor;

  /// No description provided for @caregiver_doctor_code_hint.
  ///
  /// In fr, this message translates to:
  /// **'Code médecin'**
  String get caregiver_doctor_code_hint;

  /// No description provided for @caregiver_link_doctor.
  ///
  /// In fr, this message translates to:
  /// **'Lier médecin'**
  String get caregiver_link_doctor;

  /// No description provided for @caregiver_name_required.
  ///
  /// In fr, this message translates to:
  /// **'Nom requis'**
  String get caregiver_name_required;

  /// No description provided for @caregiver_disease_required.
  ///
  /// In fr, this message translates to:
  /// **'Maladie requise'**
  String get caregiver_disease_required;

  /// No description provided for @caregiver_name_saved.
  ///
  /// In fr, this message translates to:
  /// **'Nom enregistré'**
  String get caregiver_name_saved;

  /// No description provided for @caregiver_profile_saved.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour'**
  String get caregiver_profile_saved;

  /// No description provided for @caregiver_save_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get caregiver_save_error;

  /// No description provided for @caregiver_image_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur image'**
  String get caregiver_image_error;

  /// No description provided for @caregiver_doctor_code_required.
  ///
  /// In fr, this message translates to:
  /// **'Code médecin requis'**
  String get caregiver_doctor_code_required;

  /// No description provided for @caregiver_doctor_not_found.
  ///
  /// In fr, this message translates to:
  /// **'Médecin introuvable'**
  String get caregiver_doctor_not_found;

  /// No description provided for @caregiver_doctor_linked.
  ///
  /// In fr, this message translates to:
  /// **'Médecin lié'**
  String get caregiver_doctor_linked;

  /// No description provided for @caregiver_link_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur liaison'**
  String get caregiver_link_error;

  /// No description provided for @caregiver_save_changes.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get caregiver_save_changes;

  /// No description provided for @caregiver_next_patient.
  ///
  /// In fr, this message translates to:
  /// **'Suivi patient'**
  String get caregiver_next_patient;

  /// No description provided for @caregiver_camera.
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
  String get caregiver_camera;

  /// No description provided for @caregiver_gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get caregiver_gallery;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @patient_profile_title.
  ///
  /// In fr, this message translates to:
  /// **'Profil patient'**
  String get patient_profile_title;

  /// No description provided for @patient_welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, complétez votre profil'**
  String get patient_welcome;

  /// No description provided for @patient_full_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get patient_full_name;

  /// No description provided for @patient_name_hint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre nom...'**
  String get patient_name_hint;

  /// No description provided for @patient_save_name.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get patient_save_name;

  /// No description provided for @patient_account_info.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get patient_account_info;

  /// No description provided for @patient_my_code.
  ///
  /// In fr, this message translates to:
  /// **'Mon code'**
  String get patient_my_code;

  /// No description provided for @patient_code_hint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez ce code'**
  String get patient_code_hint;

  /// No description provided for @patient_code_copied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get patient_code_copied;

  /// No description provided for @patient_doctor_section.
  ///
  /// In fr, this message translates to:
  /// **'Médecin'**
  String get patient_doctor_section;

  /// No description provided for @patient_doctor_hint.
  ///
  /// In fr, this message translates to:
  /// **'Exemple'**
  String get patient_doctor_hint;

  /// No description provided for @patient_doctor_code_label.
  ///
  /// In fr, this message translates to:
  /// **'Code médecin'**
  String get patient_doctor_code_label;

  /// No description provided for @patient_link_doctor.
  ///
  /// In fr, this message translates to:
  /// **'Lier médecin'**
  String get patient_link_doctor;

  /// No description provided for @patient_linking.
  ///
  /// In fr, this message translates to:
  /// **'Liaison...'**
  String get patient_linking;

  /// No description provided for @patient_doctor_linked.
  ///
  /// In fr, this message translates to:
  /// **'Médecin lié'**
  String get patient_doctor_linked;

  /// No description provided for @patient_doctor_unlink.
  ///
  /// In fr, this message translates to:
  /// **'Délier'**
  String get patient_doctor_unlink;

  /// No description provided for @patient_doctor_unlink_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer ?'**
  String get patient_doctor_unlink_confirm;

  /// No description provided for @patient_doctor_unlinked.
  ///
  /// In fr, this message translates to:
  /// **'Délié'**
  String get patient_doctor_unlinked;

  /// No description provided for @patient_doctor_unlinked_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get patient_doctor_unlinked_error;

  /// No description provided for @patient_linked_caregiver.
  ///
  /// In fr, this message translates to:
  /// **'Aidant lié'**
  String get patient_linked_caregiver;

  /// No description provided for @patient_caregiver_sub.
  ///
  /// In fr, this message translates to:
  /// **'Assistant'**
  String get patient_caregiver_sub;

  /// No description provided for @patient_go_home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get patient_go_home;

  /// No description provided for @patient_disconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get patient_disconnect;

  /// No description provided for @patient_name_required.
  ///
  /// In fr, this message translates to:
  /// **'Nom requis'**
  String get patient_name_required;

  /// No description provided for @patient_saved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get patient_saved;

  /// No description provided for @patient_save_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get patient_save_error;

  /// No description provided for @patient_image_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur image'**
  String get patient_image_error;

  /// No description provided for @patient_code_required.
  ///
  /// In fr, this message translates to:
  /// **'Code requis'**
  String get patient_code_required;

  /// No description provided for @patient_code_length.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères'**
  String get patient_code_length;

  /// No description provided for @patient_doctor_not_found.
  ///
  /// In fr, this message translates to:
  /// **'Médecin introuvable'**
  String get patient_doctor_not_found;

  /// No description provided for @patient_not_doctor_role.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide'**
  String get patient_not_doctor_role;

  /// No description provided for @patient_link_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur liaison'**
  String get patient_link_error;

  /// No description provided for @patient_unlink_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get patient_unlink_error;

  /// No description provided for @patient_role.
  ///
  /// In fr, this message translates to:
  /// **'Patient'**
  String get patient_role;

  /// No description provided for @doctor_linked_label.
  ///
  /// In fr, this message translates to:
  /// **'Médecin lié'**
  String get doctor_linked_label;

  /// No description provided for @unlink.
  ///
  /// In fr, this message translates to:
  /// **'Délier'**
  String get unlink;

  /// No description provided for @nutrition_title.
  ///
  /// In fr, this message translates to:
  /// **'Nutrition'**
  String get nutrition_title;

  /// No description provided for @nutrition_analysis.
  ///
  /// In fr, this message translates to:
  /// **'ANALYSE NUTRITIONNELLE'**
  String get nutrition_analysis;

  /// No description provided for @nutrition_analyze_btn.
  ///
  /// In fr, this message translates to:
  /// **'ANALYSER'**
  String get nutrition_analyze_btn;

  /// No description provided for @nutrition_age.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get nutrition_age;

  /// No description provided for @nutrition_age_unit.
  ///
  /// In fr, this message translates to:
  /// **'ans'**
  String get nutrition_age_unit;

  /// No description provided for @nutrition_weight.
  ///
  /// In fr, this message translates to:
  /// **'Poids'**
  String get nutrition_weight;

  /// No description provided for @nutrition_weight_unit.
  ///
  /// In fr, this message translates to:
  /// **'kg'**
  String get nutrition_weight_unit;

  /// No description provided for @nutrition_height.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get nutrition_height;

  /// No description provided for @nutrition_height_unit.
  ///
  /// In fr, this message translates to:
  /// **'cm'**
  String get nutrition_height_unit;

  /// No description provided for @nutrition_pressure.
  ///
  /// In fr, this message translates to:
  /// **'Pression'**
  String get nutrition_pressure;

  /// No description provided for @nutrition_pressure_unit.
  ///
  /// In fr, this message translates to:
  /// **'mmHg'**
  String get nutrition_pressure_unit;

  /// No description provided for @nutrition_glucose.
  ///
  /// In fr, this message translates to:
  /// **'Glucose'**
  String get nutrition_glucose;

  /// No description provided for @nutrition_glucose_unit.
  ///
  /// In fr, this message translates to:
  /// **'mg/dL'**
  String get nutrition_glucose_unit;

  /// No description provided for @nutrition_comorbidities.
  ///
  /// In fr, this message translates to:
  /// **'Maladies associées'**
  String get nutrition_comorbidities;

  /// No description provided for @nutrition_diabetes.
  ///
  /// In fr, this message translates to:
  /// **'Diabète'**
  String get nutrition_diabetes;

  /// No description provided for @nutrition_hta.
  ///
  /// In fr, this message translates to:
  /// **'HTA'**
  String get nutrition_hta;

  /// No description provided for @nutrition_dysphagia.
  ///
  /// In fr, this message translates to:
  /// **'Dysphagie'**
  String get nutrition_dysphagia;

  /// No description provided for @nutrition_malnutrition.
  ///
  /// In fr, this message translates to:
  /// **'Dénutrition'**
  String get nutrition_malnutrition;

  /// No description provided for @nutrition_constipation.
  ///
  /// In fr, this message translates to:
  /// **'Constipation'**
  String get nutrition_constipation;

  /// No description provided for @nutrition_avc.
  ///
  /// In fr, this message translates to:
  /// **'AVC'**
  String get nutrition_avc;

  /// No description provided for @nutrition_depression.
  ///
  /// In fr, this message translates to:
  /// **'Dépression'**
  String get nutrition_depression;

  /// No description provided for @nutrition_epilepsy.
  ///
  /// In fr, this message translates to:
  /// **'Épilepsie'**
  String get nutrition_epilepsy;

  /// No description provided for @nutrition_subtitle_alzheimer.
  ///
  /// In fr, this message translates to:
  /// **'Adoptez une alimentation saine pour améliorer la mémoire et protéger le cerveau'**
  String get nutrition_subtitle_alzheimer;

  /// No description provided for @nutrition_subtitle_parkinson.
  ///
  /// In fr, this message translates to:
  /// **'Une alimentation équilibrée peut atténuer les symptômes de la maladie de Parkinson'**
  String get nutrition_subtitle_parkinson;

  /// No description provided for @nutrition_subtitle_both.
  ///
  /// In fr, this message translates to:
  /// **'Programme nutritionnel combiné Alzheimer + Parkinson : protéines contrôlées, texture adaptée'**
  String get nutrition_subtitle_both;

  /// No description provided for @nutrition_imc_label.
  ///
  /// In fr, this message translates to:
  /// **'IMC'**
  String get nutrition_imc_label;

  /// No description provided for @nutrition_water.
  ///
  /// In fr, this message translates to:
  /// **'Boire de l\'eau'**
  String get nutrition_water;

  /// No description provided for @nutrition_water_desc.
  ///
  /// In fr, this message translates to:
  /// **'6-8 Verres/jour'**
  String get nutrition_water_desc;

  /// No description provided for @nutrition_walk.
  ///
  /// In fr, this message translates to:
  /// **'Marche'**
  String get nutrition_walk;

  /// No description provided for @nutrition_walk_desc_normal.
  ///
  /// In fr, this message translates to:
  /// **'20 min/jour'**
  String get nutrition_walk_desc_normal;

  /// No description provided for @nutrition_walk_desc_heavy.
  ///
  /// In fr, this message translates to:
  /// **'15 min/jour'**
  String get nutrition_walk_desc_heavy;

  /// No description provided for @nutrition_tips_title.
  ///
  /// In fr, this message translates to:
  /// **'Conseils & Avertissements'**
  String get nutrition_tips_title;

  /// No description provided for @nutrition_meal_plan_title.
  ///
  /// In fr, this message translates to:
  /// **'Programme repas personnalisé'**
  String get nutrition_meal_plan_title;

  /// No description provided for @nutrition_avoid_title.
  ///
  /// In fr, this message translates to:
  /// **'Aliments à éviter'**
  String get nutrition_avoid_title;

  /// No description provided for @nutrition_tab_morning.
  ///
  /// In fr, this message translates to:
  /// **'Matin'**
  String get nutrition_tab_morning;

  /// No description provided for @nutrition_tab_snack.
  ///
  /// In fr, this message translates to:
  /// **'Collation'**
  String get nutrition_tab_snack;

  /// No description provided for @nutrition_tab_lunch.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner'**
  String get nutrition_tab_lunch;

  /// No description provided for @nutrition_tab_dinner.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get nutrition_tab_dinner;

  /// No description provided for @nutrition_imc_underweight.
  ///
  /// In fr, this message translates to:
  /// **'Dénutrition'**
  String get nutrition_imc_underweight;

  /// No description provided for @nutrition_imc_risk.
  ///
  /// In fr, this message translates to:
  /// **'Risque dénutrition'**
  String get nutrition_imc_risk;

  /// No description provided for @nutrition_imc_normal.
  ///
  /// In fr, this message translates to:
  /// **'Normal'**
  String get nutrition_imc_normal;

  /// No description provided for @nutrition_imc_overweight.
  ///
  /// In fr, this message translates to:
  /// **'Surpoids'**
  String get nutrition_imc_overweight;

  /// No description provided for @nutrition_imc_obese.
  ///
  /// In fr, this message translates to:
  /// **'Obésité'**
  String get nutrition_imc_obese;

  /// No description provided for @nutrition_score_good.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get nutrition_score_good;

  /// No description provided for @nutrition_score_medium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get nutrition_score_medium;

  /// No description provided for @nutrition_score_low.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get nutrition_score_low;

  /// No description provided for @nutrition_score_balanced.
  ///
  /// In fr, this message translates to:
  /// **'Équilibré'**
  String get nutrition_score_balanced;

  /// No description provided for @nutrition_score_circle_label.
  ///
  /// In fr, this message translates to:
  /// **'Nutrition\nScore Global'**
  String get nutrition_score_circle_label;

  /// No description provided for @nutrition_imc_circle_label.
  ///
  /// In fr, this message translates to:
  /// **'IMC\nIndice Corporel'**
  String get nutrition_imc_circle_label;

  /// No description provided for @nutrition_pressure_low.
  ///
  /// In fr, this message translates to:
  /// **'Bas'**
  String get nutrition_pressure_low;

  /// No description provided for @nutrition_pressure_normal.
  ///
  /// In fr, this message translates to:
  /// **'Normal'**
  String get nutrition_pressure_normal;

  /// No description provided for @nutrition_pressure_high.
  ///
  /// In fr, this message translates to:
  /// **'Élevé'**
  String get nutrition_pressure_high;

  /// No description provided for @nutrition_fast_food.
  ///
  /// In fr, this message translates to:
  /// **'Fast-food'**
  String get nutrition_fast_food;

  /// No description provided for @nutrition_fast_food_desc.
  ///
  /// In fr, this message translates to:
  /// **'Inflammation'**
  String get nutrition_fast_food_desc;

  /// No description provided for @nutrition_sweets.
  ///
  /// In fr, this message translates to:
  /// **'Sucreries'**
  String get nutrition_sweets;

  /// No description provided for @nutrition_sweets_desc.
  ///
  /// In fr, this message translates to:
  /// **'Glycémie'**
  String get nutrition_sweets_desc;

  /// No description provided for @nutrition_fried.
  ///
  /// In fr, this message translates to:
  /// **'Fritures'**
  String get nutrition_fried;

  /// No description provided for @nutrition_fried_desc.
  ///
  /// In fr, this message translates to:
  /// **'Graisses'**
  String get nutrition_fried_desc;

  /// No description provided for @nutrition_charcuterie.
  ///
  /// In fr, this message translates to:
  /// **'Charcuterie'**
  String get nutrition_charcuterie;

  /// No description provided for @nutrition_charcuterie_desc.
  ///
  /// In fr, this message translates to:
  /// **'Sel'**
  String get nutrition_charcuterie_desc;

  /// No description provided for @nutrition_salt.
  ///
  /// In fr, this message translates to:
  /// **'Sel'**
  String get nutrition_salt;

  /// No description provided for @nutrition_salt_desc.
  ///
  /// In fr, this message translates to:
  /// **'HTA'**
  String get nutrition_salt_desc;

  /// No description provided for @nutrition_protein_morning.
  ///
  /// In fr, this message translates to:
  /// **'Protéines matin'**
  String get nutrition_protein_morning;

  /// No description provided for @nutrition_protein_morning_desc.
  ///
  /// In fr, this message translates to:
  /// **'Bloque médicament'**
  String get nutrition_protein_morning_desc;

  /// No description provided for @linkError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de liaison'**
  String get linkError;

  /// No description provided for @codePatient.
  ///
  /// In fr, this message translates to:
  /// **'Code patient'**
  String get codePatient;

  /// No description provided for @codeCaregiver.
  ///
  /// In fr, this message translates to:
  /// **'Code aidant'**
  String get codeCaregiver;

  /// No description provided for @linkedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Liaison réussie'**
  String get linkedSuccess;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @locating.
  ///
  /// In fr, this message translates to:
  /// **'Localisation en cours...'**
  String get locating;

  /// No description provided for @connecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion...'**
  String get connecting;

  /// No description provided for @inSafeZone.
  ///
  /// In fr, this message translates to:
  /// **'Dans la zone sécurisée'**
  String get inSafeZone;

  /// No description provided for @outSafeZone.
  ///
  /// In fr, this message translates to:
  /// **'Hors de la zone sécurisée'**
  String get outSafeZone;

  /// No description provided for @safeZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone sécurisée'**
  String get safeZone;

  /// No description provided for @safe.
  ///
  /// In fr, this message translates to:
  /// **'En sécurité'**
  String get safe;

  /// No description provided for @outZone.
  ///
  /// In fr, this message translates to:
  /// **'Hors zone'**
  String get outZone;

  /// No description provided for @sharingActive.
  ///
  /// In fr, this message translates to:
  /// **'Partage actif'**
  String get sharingActive;

  /// No description provided for @sharingInactive.
  ///
  /// In fr, this message translates to:
  /// **'Partage inactif'**
  String get sharingInactive;

  /// No description provided for @sosButton.
  ///
  /// In fr, this message translates to:
  /// **'Appel de détresse à l\'accompagnateur'**
  String get sosButton;

  /// No description provided for @sosSent.
  ///
  /// In fr, this message translates to:
  /// **'Appel envoyé ✓'**
  String get sosSent;

  /// No description provided for @sosTitle.
  ///
  /// In fr, this message translates to:
  /// **'Appel de détresse'**
  String get sosTitle;

  /// No description provided for @sosSentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Appel envoyé à votre accompagnateur !'**
  String get sosSentSuccess;

  /// No description provided for @sosFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec — réessayez'**
  String get sosFailed;

  /// No description provided for @noCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Aucun accompagnateur associé'**
  String get noCompanion;

  /// No description provided for @outZoneWarning.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes hors de la zone sécurisée !'**
  String get outZoneWarning;

  /// No description provided for @permissionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Permission requise'**
  String get permissionRequired;

  /// No description provided for @permissionContent.
  ///
  /// In fr, this message translates to:
  /// **'Pour que votre accompagnateur vous localise même quand l\'app est fermée, autorisez \"Toujours\" dans les paramètres.'**
  String get permissionContent;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir paramètres'**
  String get openSettings;

  /// No description provided for @distance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @speed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse'**
  String get speed;

  /// No description provided for @arrival.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get arrival;

  /// No description provided for @updatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Màj : {time}'**
  String updatedAt(String time);

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher...'**
  String get search;

  /// No description provided for @dest.
  ///
  /// In fr, this message translates to:
  /// **'Dest : {label}'**
  String dest(String label);

  /// No description provided for @placeNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Lieu introuvable'**
  String get placeNotFound;

  /// No description provided for @searchError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur recherche'**
  String get searchError;

  /// No description provided for @locatePatient.
  ///
  /// In fr, this message translates to:
  /// **'Voir la position du patient'**
  String get locatePatient;

  /// No description provided for @locating2.
  ///
  /// In fr, this message translates to:
  /// **'Recherche...'**
  String get locating2;

  /// No description provided for @patientLocated.
  ///
  /// In fr, this message translates to:
  /// **'{name} localisé'**
  String patientLocated(String name);

  /// No description provided for @waitingPatient.
  ///
  /// In fr, this message translates to:
  /// **'En attente de la première position de {name}...'**
  String waitingPatient(String name);

  /// No description provided for @follow.
  ///
  /// In fr, this message translates to:
  /// **'Suivre →'**
  String get follow;

  /// No description provided for @zoneExit.
  ///
  /// In fr, this message translates to:
  /// **'A quitté la zone'**
  String get zoneExit;

  /// No description provided for @zoneEnter.
  ///
  /// In fr, this message translates to:
  /// **'Retour en zone'**
  String get zoneEnter;

  /// No description provided for @sosAlert.
  ///
  /// In fr, this message translates to:
  /// **'Appel de détresse !'**
  String get sosAlert;

  /// No description provided for @lastAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Dernières alertes'**
  String get lastAlerts;

  /// No description provided for @locateNow.
  ///
  /// In fr, this message translates to:
  /// **'Localiser maintenant'**
  String get locateNow;

  /// No description provided for @ignore.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get ignore;

  /// No description provided for @distanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Distance: {dist}'**
  String distanceLabel(String dist);

  /// No description provided for @justNow.
  ///
  /// In fr, this message translates to:
  /// **'À l\'instant'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {m} min'**
  String minutesAgo(int m);

  /// No description provided for @hoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {h} h'**
  String hoursAgo(int h);

  /// No description provided for @min.
  ///
  /// In fr, this message translates to:
  /// **'min'**
  String get min;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
