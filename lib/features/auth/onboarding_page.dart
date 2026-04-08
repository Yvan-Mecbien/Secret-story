import 'package:flutter/material.dart';

import 'StorageService.dart';

// ════════════════════════════════════════════════════════════════
// PAGE ONBOARDING — 3 slides carrousel
// ════════════════════════════════════════════════════════════════
class OnboardingPage extends StatefulWidget {
  /// Callback appelé quand l'utilisateur termine l'onboarding
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ctrl = PageController();
  int _page = 0;

  void _next() {
    if (_page < 2) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await StorageService().markOnboardingSeen();
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides(context);

    return Scaffold(
      backgroundColor: slides[_page].bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Passer',
                  style: TextStyle(
                    color: slides[_page].fg.withOpacity(0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // ── Slides ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: slides.length,
                itemBuilder: (_, i) => _SlideView(slide: slides[i]),
              ),
            ),

            // ── Dots + bouton ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? slides[_page].accent
                              : slides[_page].fg.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: slides[_page].accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      child: Text(_page < 2 ? 'Suivant →' : 'Commencer !'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Slide> _buildSlides(BuildContext context) => [
        // ── Slide 1 : Inscription & départ ───────────────────────────────
        const _Slide(
          bg: Color(0xFF0D0D1A),
          fg: Colors.white,
          accent: Color(0xFF7F77DD),
          emoji: '🔮',
          title: 'Bienvenue dans\nSecret Story',
          bullets: [
            _Bullet('💳', 'Payez pour rejoindre l\'aventure'),
            _Bullet('✍️', 'Inscrivez-vous et choisissez votre secret'),
            _Bullet('⏳', 'Attendez le coup d\'envoi de l\'administrateur'),
            _Bullet('🏁', 'La partie dure 14 jours — que le meilleur gagne !'),
          ],
          tag: 'ÉTAPE 1 · REJOINDRE',
        ),

        // ── Slide 2 : Phases de jeu ───────────────────────────────────────
        const _Slide(
          bg: Color(0xFF0A1628),
          fg: Colors.white,
          accent: Color(0xFF378ADD),
          emoji: '🎮',
          title: 'Des phases de jeu\npour grimper au classement',
          bullets: [
            _Bullet(
                '🧠', 'Quiz, puzzle, calcul, mémoire… 9 mini-jeux différents'),
            _Bullet('⭐', 'Chaque victoire vous rapporte des points'),
            _Bullet('🏆', 'Restez dans le top 3 pour être intouchable'),
            _Bullet('🔄', 'Les jeux se renouvellent toutes les 16 heures'),
          ],
          tag: 'ÉTAPE 2 · JOUER',
        ),

        // ── Slide 3 : Votes & élimination ─────────────────────────────────
        const _Slide(
          bg: Color(0xFF1A0A0A),
          fg: Colors.white,
          accent: Color(0xFFE24B4A),
          emoji: '🕵️',
          title: 'Trouvez les secrets,\néliminez vos rivaux',
          bullets: [
            _Bullet('🗳️', 'Votez pour trouver le secret d\'un joueur'),
            _Bullet('✅', 'Bon vote → le joueur est éliminé !'),
            _Bullet('❌', 'Mauvais vote → -10 pts pour vous'),
            _Bullet('💡', '2ème erreur → -10 pts + un indice sur VOUS dévoilé'),
            _Bullet('🏅',
                'Le joueur restant avec le plus de points remporte le pactole !'),
          ],
          tag: 'ÉTAPE 3 · ÉLIMINER',
        ),
      ];
}

// ─── Modèle slide ─────────────────────────────────────────────────────────────
class _Slide {
  final Color bg, fg, accent;
  final String emoji, title, tag;
  final List<_Bullet> bullets;
  const _Slide({
    required this.bg,
    required this.fg,
    required this.accent,
    required this.emoji,
    required this.title,
    required this.tag,
    required this.bullets,
  });
}

class _Bullet {
  final String icon, text;
  const _Bullet(this.icon, this.text);
}

// ─── Vue d'un slide ───────────────────────────────────────────────────────────
class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: slide.accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: slide.accent.withOpacity(0.35)),
            ),
            child: Text(
              slide.tag,
              style: TextStyle(
                color: slide.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Emoji
          Text(slide.emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 18),

          // Titre
          Text(
            slide.title,
            style: TextStyle(
              color: slide.fg,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 28),

          // Ligne décorative
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: slide.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Bullets
          ...slide.bullets.asMap().entries.map((e) => _BulletRow(
                bullet: e.value,
                fg: slide.fg,
                accent: slide.accent,
                index: e.key,
              )),
        ],
      ),
    );
  }
}

// ─── Ligne bullet ─────────────────────────────────────────────────────────────
class _BulletRow extends StatefulWidget {
  final _Bullet bullet;
  final Color fg, accent;
  final int index;
  const _BulletRow(
      {required this.bullet,
      required this.fg,
      required this.accent,
      required this.index});

  @override
  State<_BulletRow> createState() => _BulletRowState();
}

class _BulletRowState extends State<_BulletRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Délai progressif par index
    Future.delayed(Duration(milliseconds: 120 + widget.index * 90), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.accent.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(widget.bullet.icon,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Text(
                    widget.bullet.text,
                    style: TextStyle(
                      color: widget.fg.withOpacity(0.85),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
