# app


Document de développement
Secret Story — Application Flutter

Jeu social mobile avec gestion de secrets, groupes, mini-jeux, votes et classement en temps réel
Flutter Supabase PostgreSQL Realtime Auth JWT
Architecture générale
📱
Frontend Flutter
Dart / Flutter SDK
Provider ou Riverpod pour l'état · Navigation GoRouter · Supabase Flutter client
☁️
Backend Supabase
BaaS PostgreSQL
Auth JWT · API REST auto · Realtime WebSocket · Row Level Security
Parcours utilisateur
1
Page de bienvenue
Présentation du jeu, accès inscription / connexion
2
Inscription
Pseudo · Mot de passe · Secret → assignation groupe automatique
3
Accueil dynamique
Vérifie game_started — affiche salle d'attente ou classement
4
Mini-jeux actifs
Participation, gain de points, mise à jour temps réel
5
Phase de vote
Vote unique par session · Élimination du joueur le plus voté
Aperçu des écrans principaux
🎮 Secret Story
Partie en attente
Merci de patienter…
Votre secret est en sécurité
🏆 Classement
A
Alice
840
B
Bob
720
C
Clara
610
D
David
450
🎯 Mini-jeux
Quiz mystère
Devinez le secret d'un joueur
Jouer — +50 pts
Aucun autre jeu actif
🗳️ Voter
Éliminer un joueur
A
Alice
B
Bob
Confirmer le vote
Schéma de la base de données
users Table principale des joueurs
iduuidPK
pseudotext — unique
secrettext — chiffré
group_iduuid → groups.idFK
pointsinteger — default 0RT
is_eliminatedboolean — default false
created_attimestamptz — default now()
groups Groupes et couleurs
iduuidPK
nametext (ex: Rouge, Bleu…)
colortext — hex color code
games Mini-jeux disponibles
iduuidPK
titletext
descriptiontext
points_rewardinteger
is_activebooleanRT
votes Votes d'élimination
iduuidPK
voter_iduuid → users.idFK
target_player_iduuid → users.idFK
session_idtext — identifiant de la session
created_attimestamptz
game_settings Configuration globale
iduuidPK
game_startedbooleanRT
current_phasetext — game | vote | eliminationRT
Structure du projet Flutter
lib/ ├── main.dart ├── core/ │ ├── supabase_client.dart // init Supabase │ └── router.dart // GoRouter config ├── features/ │ ├── auth/ │ │ ├── login_page.dart │ │ ├── register_page.dart │ │ └── auth_provider.dart │ ├── home/ │ │ ├── home_page.dart // game_started check │ │ └── waiting_page.dart │ ├── leaderboard/ │ │ └── leaderboard_page.dart // realtime │ ├── games/ │ │ ├── games_page.dart │ │ └── game_play_page.dart │ ├── votes/ │ │ └── vote_page.dart │ └── profile/ │ └── profile_page.dart └── shared/ ├── models/ // User, Group, Game… └── widgets/ // PlayerCard, GroupBadge…
Exemples de code clés
Initialisation Supabase
void main() async { WidgetsFlutterBinding.ensureInitialized(); await Supabase.initialize( url: 'https://YOUR_PROJECT.supabase.co', anonKey: 'YOUR_ANON_KEY', ); runApp(MyApp()); }
Inscription + assignation de groupe
Future<void> registerPlayer( String pseudo, String password, String secret ) async { // 1. Créer l'utilisateur Auth final res = await supabase.auth.signUp( email: '$pseudo@game.local', password: password, ); // 2. Assigner groupe avec le moins de joueurs final group = await supabase .from('groups') .select('id, name, users(count)') .order('users.count') .limit(1).single(); // 3. Insérer dans users await supabase.from('users').insert({ 'id': res.user!.id, 'pseudo': pseudo, 'secret': secret, 'group_id': group['id'], 'points': 0, }); }
Classement en temps réel
final channel = supabase .channel('leaderboard') .onPostgresChanges( event: PostgresChangeEvent.update, schema: 'public', table: 'users', callback: (payload) { // Mettre à jour le state local setState(() => _refreshLeaderboard()); }, ).subscribe();
Phases de jeu
🎮
Jeu
Mini-jeux actifs · Points gagnés
🗳️
Vote
1 vote / joueur · Session unique
❌
Élimination
Le plus voté est éliminé
La phase est contrôlée via game_settings.current_phase — l'interface Flutter s'adapte automatiquement via Realtime.
Sécurité — Row Level Security (RLS)
✓
Lecture classement : tous les joueurs authentifiés
✓
Modification points : uniquement via Edge Function (rôle service)
✓
Vote : un joueur ne peut insérer que son propre voter_id
!
Secret : visible uniquement par le joueur propriétaire
!
game_settings : lecture seule pour les joueurs, écriture admin uniquement
Fonctionnalités supplémentaires recommandées
Profil joueur
Affichage du groupe, secret révélé en fin de jeu, historique des points
Classement live
Mise à jour instantanée via Supabase Realtime WebSocket
Quiz & défis
Table quiz avec questions, options, réponse correcte et points associés
Favoris
Joueurs favoris marqués localement ou via table user_favorites
Notifications
Push FCM pour nouvelle phase, vote lancé, résultats
Admin panel
Interface web Supabase Studio pour démarrer/arrêter parties et gérer phases
Dépendances pubspec.yaml
dependencies: flutter: sdk: flutter supabase_flutter: ^2.0.0 # Client officiel go_router: ^13.0.0 # Navigation flutter_riverpod: ^2.5.0 # State management cached_network_image: ^3.3.0 # Avatars flutter_animate: ^4.5.0 # Animations UI intl: ^0.19.0 # Formatage dates
Checklist de démarrage
Créer le projet Supabase et récupérer URL + anon key
Exécuter le SQL de création des tables (users, groups, games, votes, game_settings)
Insérer les 4 groupes par défaut (Rouge, Bleu, Vert, Jaune) avec couleurs hex
Activer RLS sur toutes les tables et définir les politiques
Activer Realtime sur users (points), games (is_active) et game_settings
Initialiser le projet Flutter et intégrer le client Supabase
Implémenter l'authentification et les flows d'inscription/connexion
Construire les pages dans l'ordre : auth → home → leaderboard → games → votes
