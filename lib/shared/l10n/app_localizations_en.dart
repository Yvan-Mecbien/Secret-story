// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Secret Story';

  @override
  String get appTitle => 'Secret Story';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get pseudo => 'Username';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get secret => 'Your secret';

  @override
  String get secretHint => 'E.g. I\'m afraid of butterflies...';

  @override
  String get loginButton => 'Sign in';

  @override
  String get registerButton => 'Join the game';

  @override
  String get noAccount => 'Not registered yet? ';

  @override
  String get alreadyAccount => 'Already have an account? ';

  @override
  String get pseudoRequired => 'Enter your username';

  @override
  String get pseudoTooShort => 'Minimum 3 characters';

  @override
  String get passwordRequired => 'Enter a password';

  @override
  String get passwordTooShort => 'Minimum 6 characters';

  @override
  String get passwordsNoMatch => 'Passwords do not match';

  @override
  String get secretRequired => 'Your secret cannot be empty';

  @override
  String get secretTooShort => 'Secret too short (min 10 chars)';

  @override
  String get loginError => 'Wrong username or password.';

  @override
  String get registerError => 'This username may already be taken.';

  @override
  String get welcome => 'Welcome to Secret Story!';

  @override
  String get welcomeSub => 'Enter your secret to join the game.';

  @override
  String get secretInfo =>
      'Your secret will stay hidden from other players until the end.';

  @override
  String get waitingTitle => 'The game hasn\'t started yet';

  @override
  String get waitingSubtitle =>
      'Please wait...\nThe admin will start the game soon.';

  @override
  String get home => 'Home';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get games => 'Games';

  @override
  String get votes => 'Votes';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get rankingTitle => '🏆 Leaderboard';

  @override
  String seeAll(int count) {
    return 'See all ($count)';
  }

  @override
  String get points => 'points';

  @override
  String get pts => 'pts';

  @override
  String get me => 'Me';

  @override
  String get eliminated => 'Eliminated';

  @override
  String get active => 'Active';

  @override
  String get group => 'Group';

  @override
  String get podiumTitle => '🏆 Podium';

  @override
  String get tabActive => 'Active';

  @override
  String get tabAll => 'All';

  @override
  String get noPlayers => 'No players yet';

  @override
  String get gamesAvailable => 'Available games';

  @override
  String get gamesSoon => 'Coming soon';

  @override
  String get noGames => 'No games available';

  @override
  String get noGamesSub => 'The admin will activate games\nduring the game.';

  @override
  String get alreadyPlayed => 'Already played';

  @override
  String get play => 'Play';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get voteTitle => 'Elimination vote';

  @override
  String get votePhaseHeader => 'Vote phase';

  @override
  String get voteInstruction =>
      'Choose a player to eliminate.\nYou can only vote once.';

  @override
  String get voteButton => '🗳️ Vote for this player';

  @override
  String get voteSelectFirst => 'Select a player';

  @override
  String get voteConfirmTitle => 'Confirm vote';

  @override
  String get voteConfirmText =>
      'Are you sure? You can only vote three times per session.';

  @override
  String get voteSuccess => '✅ Vote recorded!';

  @override
  String get voteDone => 'Vote recorded!';

  @override
  String get voteDoneSub =>
      'Your vote has been counted.\nResults will be announced soon.';

  @override
  String get voteNotOpen => 'Vote not available';

  @override
  String voteNotOpenSub(String phase) {
    return 'Votes are not open right now.\nCurrent phase: $phase';
  }

  @override
  String get gameNotStartedLock => 'The game hasn\'t started yet';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get myProfile => 'My profile';

  @override
  String get mySecret => 'My secret 🤫';

  @override
  String get reveal => 'Reveal';

  @override
  String get hide => 'Hide';

  @override
  String get pointHistory => 'Points history';

  @override
  String get noHistory => 'No points earned yet';

  @override
  String get status => 'Status';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmText => 'Are you sure you want to logout?';

  @override
  String get phaseWaiting => 'Waiting';

  @override
  String get phaseGame => 'Game phase';

  @override
  String get phaseVote => 'Vote phase';

  @override
  String get phaseElimination => 'Elimination in progress';

  @override
  String get phaseFinished => 'Game over';

  @override
  String questionLabel(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get nextQuestion => 'Next question →';

  @override
  String get seeResults => 'See my results';

  @override
  String goodAnswers(int score, int total) {
    return '$score / $total correct answers';
  }

  @override
  String get submitScore => 'Submit and claim my points';

  @override
  String pointsEarned(int points) {
    return '+$points points earned!';
  }

  @override
  String get backToGames => 'Back to games';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Language';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get gameActive => 'Active';

  @override
  String pointsReward(int pts) {
    return '+$pts pts';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get voteGameTitle => 'Vote — Guess the secrets';

  @override
  String get voteSelectSecret => 'Choose a secret';

  @override
  String get voteSelectPlayer => 'Choose a player';

  @override
  String get voteSearchPlayer => 'Search a player...';

  @override
  String get voteSecretDropdownHint => 'Select a secret';

  @override
  String get votePlayerDropdownHint => 'Select a player';

  @override
  String get voteSubmitGuess => '🗳️ Submit vote';

  @override
  String voteAttemptsLeft(int n) {
    return '$n vote(s) left today';
  }

  @override
  String get voteNoAttemptsLeft => 'You have used your 3 votes today';

  @override
  String get voteCorrect => '🎉 Correct! The player is eliminated!';

  @override
  String get voteWrong => '❌ Wrong! -10 pts penalty.';

  @override
  String get voteResultTitle => 'Vote result';

  @override
  String get votePenaltyWarning =>
      'WWarning: one wrong vote costs you 10 points, and two wrong votes reveal a clue about you!';

  @override
  String get indicesTitle => 'Revealed clues';

  @override
  String get noIndices => 'No clues revealed yet';

  @override
  String get voteCompleteSelectBoth => 'Select a secret and a player';

  @override
  String get voteSectionSecret => '1. Choose a secret';

  @override
  String get voteSectionPlayer => '2. Choose a player';

  @override
  String get voteRandomSecrets => 'Secrets are displayed randomly';

  @override
  String get send => 'Share';

  @override
  String get indice => 'Clues';

  @override
  String get messenger => 'Messages';

  @override
  String get registerClose => 'Registration closed';

  @override
  String get jeuStart => 'The game has already started';

  @override
  String get registerNo => 'New registrations are no longer permitted.';

  @override
  String get backlogin => 'Return to login';

  @override
  String get errorC => 'Loading error';

  @override
  String get warning => 'Warning';

  @override
  String get passwordWarningMessage =>
      'Please remember your password carefully. In case of loss, it cannot be recovered and you will lose access to your account.';

  @override
  String get indicesSoonAvailable => 'Index coming soon';

  @override
  String get indicesDialogTitle => 'Indices coming soon';

  @override
  String indicesCount(int n) {
    return '$n index(es)';
  }
}
