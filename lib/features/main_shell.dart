import '../shared/l10n/app_localizations.dart';
import 'navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/theme/app_theme.dart';
import 'home/home_provider.dart';
import 'home/home_page.dart';
import 'leaderboard/leaderboard_page.dart';
import 'games/games_page.dart';
import 'votes/vote_page.dart';
import 'profile/profile_page.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final Map<int, Key> _pageKeys;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageKeys = {
      0: UniqueKey(),
      1: UniqueKey(),
      2: UniqueKey(),
      3: UniqueKey(),
      4: UniqueKey(),
    };
    _currentIndex = ref.read(activeTabProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIndex = ref.read(activeTabProvider);
    if (newIndex != _currentIndex) {
      _pageKeys[newIndex] = UniqueKey();
      _currentIndex = newIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(activeTabProvider);
    final settings = ref.watch(gameSettingsStreamProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    // ⚠️ Libellés d'origine (non modifiés)
    final tabs = [
      (Icons.home_outlined, Icons.home, l.home),
      (Icons.emoji_events_outlined, Icons.emoji_events, l.leaderboard),
      (Icons.sports_esports_outlined, Icons.sports_esports, l.games),
      (Icons.how_to_vote_outlined, Icons.how_to_vote, l.votes),
      (Icons.person_outline, Icons.person, l.profile),
    ];

    // Construction des icônes avec badge éventuel (pour l'onglet Votes, index 3)
    List<Widget> navIcons = [];

    List<Widget> navActiveIcons = [];

    for (int i = 0; i < tabs.length; i++) {
      final (inactiveIcon, activeIcon, label) = tabs[i];
      final isVotesTab = (i == 3);
      final showBadge = isVotesTab && (settings?.isVotePhase == true);

      Widget buildIcon(IconData iconData, bool isActive) {
        Widget icon = Icon(
          iconData,
          color: isActive
              ? (isDark ? AppColors.primaryLight : AppColors.primary)
              : (isDark ? const Color(0xFF666680) : Colors.grey),
          size: 26,
        );
        if (showBadge && isActive == false) {
          // On met le badge seulement sur l'icône inactive ? Ou toujours ?
          // Pour être comme avant : le point apparaît sur l'onglet Votes (peu importe actif/inactif)
          // Mais circle_nav_bar affiche l'icône inactive par défaut, donc on le met ici.
          icon = Stack(
            clipBehavior: Clip.none,
            children: [
              icon,
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        }
        return icon;
      }

      navIcons.add(buildIcon(inactiveIcon, false));
      navActiveIcons.add(buildIcon(activeIcon, true));
    }

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          HomePage(key: _pageKeys[0]),
          LeaderboardPage(key: _pageKeys[1]),
          GamesPage(key: _pageKeys[2]),
          VotePage(key: _pageKeys[3]),
          ProfilePage(key: _pageKeys[4]),
        ],
      ),
      bottomNavigationBar: CircleNavBar(
        activeIcons: const [
          Icon(Icons.home_outlined, color: Colors.deepPurple),
          Icon(Icons.emoji_events_outlined, color: Colors.deepPurple),
          Icon(Icons.sports_esports_outlined, color: Colors.deepPurple),
          Icon(Icons.how_to_vote_outlined, color: Colors.deepPurple),
          Icon(Icons.person_outline, color: Colors.deepPurple),
        ],
        inactiveIcons: [
          (Column(
            children: [
              const Icon(Icons.home),
              Text(l.home),
            ],
          )),
          (Column(
            children: [
              const Icon(Icons.emoji_events),
              Text(l.leaderboard),
            ],
          )),
          (Column(
            children: [
              const Icon(Icons.sports_esports),
              Text(l.games),
            ],
          )),
          (Column(
            children: [
              const Icon(Icons.how_to_vote),
              Text(l.votes),
            ],
          )),
          (Column(
            children: [
              const Icon(Icons.person),
              Text(l.profile),
            ],
          )),
        ],
        color: isDark ? AppColors.darkSurface : Colors.white,
        circleColor: isDark ? AppColors.darkSurface : Colors.white,
        activeIndex: index,
        onTap: (newIndex) {
          ref.read(activeTabProvider.notifier).state = newIndex;
        },
        height: 60,
        circleWidth: 60,
        padding: const EdgeInsets.only(left: 16, right: 16),
        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        shadowColor: isDark ? Colors.transparent : Colors.black12,
        elevation: isDark ? 0 : 2,
      ),
    );
  }
}
