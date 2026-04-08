// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Secret Story';

  @override
  String get appTitle => 'Secret Story';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Inscription';

  @override
  String get logout => 'Déconnexion';

  @override
  String get pseudo => 'Pseudo';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get secret => 'Votre secret';

  @override
  String get secretHint => 'Ex : J\'ai peur des papillons...';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get registerButton => 'Rejoindre le jeu';

  @override
  String get noAccount => 'Pas encore inscrit ? ';

  @override
  String get alreadyAccount => 'Déjà un compte ? ';

  @override
  String get pseudoRequired => 'Entrez votre pseudo';

  @override
  String get pseudoTooShort => 'Minimum 3 caractères';

  @override
  String get passwordRequired => 'Entrez un mot de passe';

  @override
  String get passwordTooShort => 'Minimum 6 caractères';

  @override
  String get passwordsNoMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get secretRequired => 'Votre secret ne peut pas être vide';

  @override
  String get secretTooShort => 'Secret trop court (min 10 caractères)';

  @override
  String get loginError => 'Pseudo ou mot de passe incorrect.';

  @override
  String get registerError => 'Ce pseudo est peut-être déjà utilisé.';

  @override
  String get welcome => 'Bienvenue dans Secret Story !';

  @override
  String get welcomeSub => 'Entrez votre secret pour rejoindre le jeu.';

  @override
  String get secretInfo =>
      'Votre secret restera caché aux autres joueurs jusqu\'à la fin.';

  @override
  String get waitingTitle => 'Le jeu n\'a pas encore commencé';

  @override
  String get waitingSubtitle =>
      'Merci de patienter...\nL\'administrateur lancera la partie prochainement.';

  @override
  String get home => 'Accueil';

  @override
  String get leaderboard => 'Classement';

  @override
  String get games => 'Jeux';

  @override
  String get votes => 'Votes';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get rankingTitle => '🏆 Classement';

  @override
  String seeAll(int count) {
    return 'Voir tout ($count)';
  }

  @override
  String get points => 'points';

  @override
  String get pts => 'pts';

  @override
  String get me => 'Moi';

  @override
  String get eliminated => 'Éliminé';

  @override
  String get active => 'Actif';

  @override
  String get group => 'Groupe';

  @override
  String get podiumTitle => '🏆 Podium';

  @override
  String get tabActive => 'Actifs';

  @override
  String get tabAll => 'Général';

  @override
  String get noPlayers => 'Aucun joueur encore';

  @override
  String get gamesAvailable => 'Jeux disponibles';

  @override
  String get gamesSoon => 'Prochainement';

  @override
  String get noGames => 'Aucun jeu disponible';

  @override
  String get noGamesSub =>
      'L\'administrateur activera les jeux\npendant la partie.';

  @override
  String get alreadyPlayed => 'Déjà joué';

  @override
  String get play => 'Jouer';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get voteTitle => 'Vote d\'élimination';

  @override
  String get votePhaseHeader => 'Phase de vote';

  @override
  String get voteInstruction =>
      'Choisissez un joueur à éliminer.\nVous ne pouvez voter qu\'une seule fois.';

  @override
  String get voteButton => '🗳️ Voter pour ce joueur';

  @override
  String get voteSelectFirst => 'Sélectionnez un joueur';

  @override
  String get voteConfirmTitle => 'Confirmer le vote';

  @override
  String get voteConfirmText =>
      'Êtes-vous sûr ? Vous ne pouvez voter que trois  fois par session.';

  @override
  String get voteSuccess => '✅ Vote enregistré !';

  @override
  String get voteDone => 'Vote enregistré !';

  @override
  String get voteDoneSub =>
      'Votre vote a été pris en compte.\nLes résultats seront annoncés prochainement.';

  @override
  String get voteNotOpen => 'Vote non disponible';

  @override
  String voteNotOpenSub(String phase) {
    return 'Les votes ne sont pas ouverts pour le moment.\nPhase actuelle : $phase';
  }

  @override
  String get gameNotStartedLock => 'La partie n\'a pas encore commencé';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get mySecret => 'Mon secret 🤫';

  @override
  String get reveal => 'Révéler';

  @override
  String get hide => 'Masquer';

  @override
  String get pointHistory => 'Historique des points';

  @override
  String get noHistory => 'Aucun point encore gagné';

  @override
  String get status => 'Statut';

  @override
  String get logoutConfirmTitle => 'Déconnexion';

  @override
  String get logoutConfirmText => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get phaseWaiting => 'En attente';

  @override
  String get phaseGame => 'Phase de jeu';

  @override
  String get phaseVote => 'Phase de vote';

  @override
  String get phaseElimination => 'Élimination en cours';

  @override
  String get phaseFinished => 'Partie terminée';

  @override
  String questionLabel(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get nextQuestion => 'Question suivante →';

  @override
  String get seeResults => 'Voir mes résultats';

  @override
  String goodAnswers(int score, int total) {
    return '$score / $total bonnes réponses';
  }

  @override
  String get submitScore => 'Valider et récupérer mes points';

  @override
  String pointsEarned(int points) {
    return '+$points points gagnés !';
  }

  @override
  String get backToGames => 'Retour aux jeux';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get gameActive => 'Actif';

  @override
  String pointsReward(int pts) {
    return '+$pts pts';
  }

  @override
  String get refresh => 'Rafraîchir';

  @override
  String get voteGameTitle => 'Vote — Devinez les secrets';

  @override
  String get voteSelectSecret => 'Choisir un secret';

  @override
  String get voteSelectPlayer => 'Choisir un joueur';

  @override
  String get voteSearchPlayer => 'Rechercher un joueur...';

  @override
  String get voteSecretDropdownHint => 'Sélectionnez un secret';

  @override
  String get votePlayerDropdownHint => 'Sélectionnez un joueur';

  @override
  String get voteSubmitGuess => '🗳️ Soumettre le vote';

  @override
  String voteAttemptsLeft(int n) {
    return '$n vote(s) restant(s) aujourd\'hui';
  }

  @override
  String get voteNoAttemptsLeft => 'Vous avez utilisé vos 3 votes aujourd\'hui';

  @override
  String get voteCorrect => '🎉 Bonne réponse ! Le joueur est éliminé !';

  @override
  String get voteWrong => '❌ Mauvais ! -10 pts de pénalité.';

  @override
  String get voteResultTitle => 'Résultat du vote';

  @override
  String get votePenaltyWarning =>
      'Attention : un mauvais vote vous coûte 10 points, et deux mauvais votes révèlent un indice sur vous !';

  @override
  String get indicesTitle => 'Indices révélés';

  @override
  String get noIndices => 'Aucun indice révélé pour le moment';

  @override
  String get voteCompleteSelectBoth => 'Sélectionnez un secret et un joueur';

  @override
  String get voteSectionSecret => '1. Choisissez un secret';

  @override
  String get voteSectionPlayer => '2. Choisissez le joueur';

  @override
  String get voteRandomSecrets => 'Les secrets sont affichés aléatoirement';

  @override
  String get send => 'Partager';

  @override
  String get indice => 'Indices';

  @override
  String get messenger => 'Messages';

  @override
  String get registerClose => 'Inscriptions fermées';

  @override
  String get jeuStart => 'Le jeu a déjà commencé';

  @override
  String get registerNo =>
      'Les nouvelles inscriptions ne sont plus autorisées.';

  @override
  String get backlogin => 'Retour à la connexion\'';

  @override
  String get errorC => 'Erreur de chargement';

  @override
  String get warning => 'Attention';

  @override
  String get passwordWarningMessage =>
      'Mémorisez bien votre mot de passe. En cas d\'oubli, il ne pourra pas être récupéré et vous perdrez l’accès à votre compte.';

  @override
  String get indicesSoonAvailable => 'Indice bientôt disponible';

  @override
  String get indicesDialogTitle => 'Indices à venir';

  @override
  String indicesCount(int n) {
    return '$n indice(s)';
  }
}
