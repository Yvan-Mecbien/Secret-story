import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Secret Story'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Secret Story'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @pseudo.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get pseudo;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @secret.
  ///
  /// In fr, this message translates to:
  /// **'Votre secret'**
  String get secret;

  /// No description provided for @secretHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : J\'ai peur des papillons...'**
  String get secretHint;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre le jeu'**
  String get registerButton;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore inscrit ? '**
  String get noAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? '**
  String get alreadyAccount;

  /// No description provided for @pseudoRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre pseudo'**
  String get pseudoRequired;

  /// No description provided for @pseudoTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 3 caractères'**
  String get pseudoTooShort;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un mot de passe'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get passwordTooShort;

  /// No description provided for @passwordsNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsNoMatch;

  /// No description provided for @secretRequired.
  ///
  /// In fr, this message translates to:
  /// **'Votre secret ne peut pas être vide'**
  String get secretRequired;

  /// No description provided for @secretTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Secret trop court (min 10 caractères)'**
  String get secretTooShort;

  /// No description provided for @loginError.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo ou mot de passe incorrect.'**
  String get loginError;

  /// No description provided for @registerError.
  ///
  /// In fr, this message translates to:
  /// **'Ce pseudo est peut-être déjà utilisé.'**
  String get registerError;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans Secret Story !'**
  String get welcome;

  /// No description provided for @welcomeSub.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre secret pour rejoindre le jeu.'**
  String get welcomeSub;

  /// No description provided for @secretInfo.
  ///
  /// In fr, this message translates to:
  /// **'Votre secret restera caché aux autres joueurs jusqu\'à la fin.'**
  String get secretInfo;

  /// No description provided for @waitingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le jeu n\'a pas encore commencé'**
  String get waitingTitle;

  /// No description provided for @waitingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Merci de patienter...\nL\'administrateur lancera la partie prochainement.'**
  String get waitingSubtitle;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @leaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get leaderboard;

  /// No description provided for @games.
  ///
  /// In fr, this message translates to:
  /// **'Jeux'**
  String get games;

  /// No description provided for @votes.
  ///
  /// In fr, this message translates to:
  /// **'Votes'**
  String get votes;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @rankingTitle.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Classement'**
  String get rankingTitle;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout ({count})'**
  String seeAll(int count);

  /// No description provided for @points.
  ///
  /// In fr, this message translates to:
  /// **'points'**
  String get points;

  /// No description provided for @pts.
  ///
  /// In fr, this message translates to:
  /// **'pts'**
  String get pts;

  /// No description provided for @me.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get me;

  /// No description provided for @eliminated.
  ///
  /// In fr, this message translates to:
  /// **'Éliminé'**
  String get eliminated;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active;

  /// No description provided for @group.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get group;

  /// No description provided for @podiumTitle.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Podium'**
  String get podiumTitle;

  /// No description provided for @tabActive.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get tabActive;

  /// No description provided for @tabAll.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get tabAll;

  /// No description provided for @noPlayers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur encore'**
  String get noPlayers;

  /// No description provided for @gamesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Jeux disponibles'**
  String get gamesAvailable;

  /// No description provided for @gamesSoon.
  ///
  /// In fr, this message translates to:
  /// **'Prochainement'**
  String get gamesSoon;

  /// No description provided for @noGames.
  ///
  /// In fr, this message translates to:
  /// **'Aucun jeu disponible'**
  String get noGames;

  /// No description provided for @noGamesSub.
  ///
  /// In fr, this message translates to:
  /// **'L\'administrateur activera les jeux\npendant la partie.'**
  String get noGamesSub;

  /// No description provided for @alreadyPlayed.
  ///
  /// In fr, this message translates to:
  /// **'Déjà joué'**
  String get alreadyPlayed;

  /// No description provided for @play.
  ///
  /// In fr, this message translates to:
  /// **'Jouer'**
  String get play;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @voteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vote d\'élimination'**
  String get voteTitle;

  /// No description provided for @votePhaseHeader.
  ///
  /// In fr, this message translates to:
  /// **'Phase de vote'**
  String get votePhaseHeader;

  /// No description provided for @voteInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un joueur à éliminer.\nVous ne pouvez voter qu\'une seule fois.'**
  String get voteInstruction;

  /// No description provided for @voteButton.
  ///
  /// In fr, this message translates to:
  /// **'🗳️ Voter pour ce joueur'**
  String get voteButton;

  /// No description provided for @voteSelectFirst.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un joueur'**
  String get voteSelectFirst;

  /// No description provided for @voteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le vote'**
  String get voteConfirmTitle;

  /// No description provided for @voteConfirmText.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr ? Vous ne pouvez voter que trois  fois par session.'**
  String get voteConfirmText;

  /// No description provided for @voteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'✅ Vote enregistré !'**
  String get voteSuccess;

  /// No description provided for @voteDone.
  ///
  /// In fr, this message translates to:
  /// **'Vote enregistré !'**
  String get voteDone;

  /// No description provided for @voteDoneSub.
  ///
  /// In fr, this message translates to:
  /// **'Votre vote a été pris en compte.\nLes résultats seront annoncés prochainement.'**
  String get voteDoneSub;

  /// No description provided for @voteNotOpen.
  ///
  /// In fr, this message translates to:
  /// **'Vote non disponible'**
  String get voteNotOpen;

  /// No description provided for @voteNotOpenSub.
  ///
  /// In fr, this message translates to:
  /// **'Les votes ne sont pas ouverts pour le moment.\nPhase actuelle : {phase}'**
  String voteNotOpenSub(String phase);

  /// No description provided for @gameNotStartedLock.
  ///
  /// In fr, this message translates to:
  /// **'La partie n\'a pas encore commencé'**
  String get gameNotStartedLock;

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

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get myProfile;

  /// No description provided for @mySecret.
  ///
  /// In fr, this message translates to:
  /// **'Mon secret 🤫'**
  String get mySecret;

  /// No description provided for @reveal.
  ///
  /// In fr, this message translates to:
  /// **'Révéler'**
  String get reveal;

  /// No description provided for @hide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get hide;

  /// No description provided for @pointHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des points'**
  String get pointHistory;

  /// No description provided for @noHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun point encore gagné'**
  String get noHistory;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmText.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter ?'**
  String get logoutConfirmText;

  /// No description provided for @phaseWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get phaseWaiting;

  /// No description provided for @phaseGame.
  ///
  /// In fr, this message translates to:
  /// **'Phase de jeu'**
  String get phaseGame;

  /// No description provided for @phaseVote.
  ///
  /// In fr, this message translates to:
  /// **'Phase de vote'**
  String get phaseVote;

  /// No description provided for @phaseElimination.
  ///
  /// In fr, this message translates to:
  /// **'Élimination en cours'**
  String get phaseElimination;

  /// No description provided for @phaseFinished.
  ///
  /// In fr, this message translates to:
  /// **'Partie terminée'**
  String get phaseFinished;

  /// No description provided for @questionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Question {current}/{total}'**
  String questionLabel(int current, int total);

  /// No description provided for @nextQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Question suivante →'**
  String get nextQuestion;

  /// No description provided for @seeResults.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes résultats'**
  String get seeResults;

  /// No description provided for @goodAnswers.
  ///
  /// In fr, this message translates to:
  /// **'{score} / {total} bonnes réponses'**
  String goodAnswers(int score, int total);

  /// No description provided for @submitScore.
  ///
  /// In fr, this message translates to:
  /// **'Valider et récupérer mes points'**
  String get submitScore;

  /// No description provided for @pointsEarned.
  ///
  /// In fr, this message translates to:
  /// **'+{points} points gagnés !'**
  String pointsEarned(int points);

  /// No description provided for @backToGames.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux jeux'**
  String get backToGames;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @gameActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get gameActive;

  /// No description provided for @pointsReward.
  ///
  /// In fr, this message translates to:
  /// **'+{pts} pts'**
  String pointsReward(int pts);

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir'**
  String get refresh;

  /// No description provided for @voteGameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vote — Devinez les secrets'**
  String get voteGameTitle;

  /// No description provided for @voteSelectSecret.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un secret'**
  String get voteSelectSecret;

  /// No description provided for @voteSelectPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un joueur'**
  String get voteSelectPlayer;

  /// No description provided for @voteSearchPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un joueur...'**
  String get voteSearchPlayer;

  /// No description provided for @voteSecretDropdownHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un secret'**
  String get voteSecretDropdownHint;

  /// No description provided for @votePlayerDropdownHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un joueur'**
  String get votePlayerDropdownHint;

  /// No description provided for @voteSubmitGuess.
  ///
  /// In fr, this message translates to:
  /// **'🗳️ Soumettre le vote'**
  String get voteSubmitGuess;

  /// No description provided for @voteAttemptsLeft.
  ///
  /// In fr, this message translates to:
  /// **'{n} vote(s) restant(s) aujourd\'hui'**
  String voteAttemptsLeft(int n);

  /// No description provided for @voteNoAttemptsLeft.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez utilisé vos 3 votes aujourd\'hui'**
  String get voteNoAttemptsLeft;

  /// No description provided for @voteCorrect.
  ///
  /// In fr, this message translates to:
  /// **'🎉 Bonne réponse ! Le joueur est éliminé !'**
  String get voteCorrect;

  /// No description provided for @voteWrong.
  ///
  /// In fr, this message translates to:
  /// **'❌ Mauvais ! -10 pts de pénalité.'**
  String get voteWrong;

  /// No description provided for @voteResultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résultat du vote'**
  String get voteResultTitle;

  /// No description provided for @votePenaltyWarning.
  ///
  /// In fr, this message translates to:
  /// **'Attention : un mauvais vote vous coûte 10 points, et deux mauvais votes révèlent un indice sur vous !'**
  String get votePenaltyWarning;

  /// No description provided for @indicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Indices révélés'**
  String get indicesTitle;

  /// No description provided for @noIndices.
  ///
  /// In fr, this message translates to:
  /// **'Aucun indice révélé pour le moment'**
  String get noIndices;

  /// No description provided for @voteCompleteSelectBoth.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un secret et un joueur'**
  String get voteCompleteSelectBoth;

  /// No description provided for @voteSectionSecret.
  ///
  /// In fr, this message translates to:
  /// **'1. Choisissez un secret'**
  String get voteSectionSecret;

  /// No description provided for @voteSectionPlayer.
  ///
  /// In fr, this message translates to:
  /// **'2. Choisissez le joueur'**
  String get voteSectionPlayer;

  /// No description provided for @voteRandomSecrets.
  ///
  /// In fr, this message translates to:
  /// **'Les secrets sont affichés aléatoirement'**
  String get voteRandomSecrets;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get send;

  /// No description provided for @indice.
  ///
  /// In fr, this message translates to:
  /// **'Indices'**
  String get indice;

  /// No description provided for @messenger.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get messenger;

  /// No description provided for @registerClose.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions fermées'**
  String get registerClose;

  /// No description provided for @jeuStart.
  ///
  /// In fr, this message translates to:
  /// **'Le jeu a déjà commencé'**
  String get jeuStart;

  /// No description provided for @registerNo.
  ///
  /// In fr, this message translates to:
  /// **'Les nouvelles inscriptions ne sont plus autorisées.'**
  String get registerNo;

  /// No description provided for @backlogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion\''**
  String get backlogin;

  /// No description provided for @errorC.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get errorC;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get warning;

  /// No description provided for @passwordWarningMessage.
  ///
  /// In fr, this message translates to:
  /// **'Mémorisez bien votre mot de passe. En cas d\'oubli, il ne pourra pas être récupéré et vous perdrez l’accès à votre compte.'**
  String get passwordWarningMessage;

  /// No description provided for @indicesSoonAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Indice bientôt disponible'**
  String get indicesSoonAvailable;

  /// No description provided for @indicesDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Indices à venir'**
  String get indicesDialogTitle;

  /// No description provided for @indicesCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} indice(s)'**
  String indicesCount(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
