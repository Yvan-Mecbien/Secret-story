import 'package:app/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/theme_provider.dart';
import '../../shared/widgets/loading_button.dart';
import '../../shared/l10n/app_localizations.dart';
import '../home/home_provider.dart';
import '../main_shell.dart';
import 'auth_provider.dart';
import 'login_page.dart';

class Register extends ConsumerWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(gameSettingsStreamProvider);
    final l = AppLocalizations.of(context);

    return settingsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorView(
        message: l.errorC,
        onRetry: () {
          ref.invalidate(gameSettingsStreamProvider);
        },
      ),
      // data: (settings) => settings.gameStarted
      //     ? const RegistrationClosedPage() // ← afficher la page "inscriptions fermées"
      //     : const _RegisterPage(), // ← formulaire d'inscription

      data: (settings) => settings.gameStarted
          ? const _RegisterPage() // ← afficher la page "inscriptions fermées"
          : const _RegisterPage(), // ← formulaire d'inscription
    );
  }
}

// Page affichée lorsque le jeu a déjà commencé
class RegistrationClosedPage extends StatelessWidget {
  const RegistrationClosedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.registerClose)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              l.jeuStart,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              l.registerNo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Retour à l'écran de connexion
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(l.backlogin),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterPage extends ConsumerStatefulWidget {
  const _RegisterPage();
  @override
  ConsumerState<_RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<_RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _obscurePass = true, _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await ref.read(authNotifierProvider.notifier).register(
            pseudo: _pseudoCtrl.text.trim(),
            password: _passCtrl.text,
            secret: _secretCtrl.text.trim(),
            onSuccess: () {
              // Navigation ou action en cas de succès
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (_) => false);
              }
            },
            onError: (error) {
              // Afficher l'erreur à l'utilisateur
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.red),
              );
            },
          );
    } catch (e) {
      final l = AppLocalizations.of(context);

      setState(() => _error = l.registerError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE6E6F0);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.primarySurf,
        actions: [
          // Sélecteur de langue (drapeaux)
          PopupMenuButton<Locale>(
            icon: Icon(
              locale.languageCode == 'fr' ? Icons.flag : Icons.flag_outlined,
            ),
            tooltip: 'Changer la langue',
            onSelected: (Locale locale) =>
                ref.read(localeProvider.notifier).setLocale(locale),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: const Locale('fr'),
                child: Row(
                  children: [
                    const Text('🇫🇷 ', style: TextStyle(fontSize: 20)),
                    Text(l.french),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('en'),
                child: Row(
                  children: [
                    const Text('🇬🇧 ', style: TextStyle(fontSize: 20)),
                    Text(l.english),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Sélecteur de thème (couleur)
          PopupMenuButton<ThemeMode>(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
            ),
            tooltip: 'Changer le thème',
            onSelected: (ThemeMode mode) =>
                ref.read(themeProvider.notifier).setMode(mode),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    const Icon(Icons.light_mode),
                    const SizedBox(width: 8),
                    Text(l.themeLight),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    const Icon(Icons.dark_mode),
                    const SizedBox(width: 8),
                    Text(l.themeDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: isDark ? AppColors.darkBg : AppColors.primarySurf,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage())),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor)),
                    child: const Icon(Icons.arrow_back, size: 20)),
              ),
              const SizedBox(width: 14),
              Text(l.register,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
            ]).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),

            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryLight.withOpacity(0.15)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Text('🔮', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(l.welcome,
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.primaryLight
                                  : Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(l.welcomeSub,
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.primaryLight.withOpacity(0.8)
                                  : Colors.white70,
                              fontSize: 12,
                              height: 1.4)),
                    ])),
              ]),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.07),
                            blurRadius: 24,
                            offset: const Offset(0, 8)),
                      ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _pseudoCtrl,
                        decoration: InputDecoration(
                            labelText: l.pseudo,
                            hintText: 'min. 3 caractères',
                            prefixIcon: const Icon(Icons.person_outline)),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l.pseudoRequired;
                          }
                          if (v.trim().length < 3) return l.pseudoTooShort;
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                            labelText: l.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                                icon: Icon(_obscurePass
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass))),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return l.passwordRequired;
                          if (v.length < 6) return l.passwordTooShort;
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                            labelText: l.confirmPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm))),
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v != _passCtrl.text ? l.passwordsNoMatch : null,
                      ),
                      const SizedBox(height: 18),
                      // Secret hint
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                            color: AppColors.jaune
                                .withOpacity(isDark ? 0.1 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.jaune.withOpacity(0.3))),
                        child: Row(children: [
                          const Text('💡', style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(l.secretInfo,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.jaune.withOpacity(0.9)
                                          : const Color(0xFF7A6000)))),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _secretCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                            labelText: l.secret,
                            hintText: l.secretHint,
                            prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.lock_person_outlined)),
                            alignLabelWithHint: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l.secretRequired;
                          }
                          if (v.trim().length < 10) return l.secretTooShort;
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: LoadingButton(
                          isLoading: isLoading,
                          onPressed: () =>
                              _showPasswordWarningDialog(context, _register),
                          child: Text(l.registerButton),
                        ),
                      ),
                    ]),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(l.alreadyAccount,
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54)),
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage())),
                child: Text(l.login,
                    style: TextStyle(
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ),
            ]).animate().fadeIn(delay: 400.ms),
          ]),
        ),
      ),
    );
  }
}

void _showPasswordWarningDialog(BuildContext context, VoidCallback onConfirm) {
  final l = AppLocalizations.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(l.warning),
        content: Text(l.passwordWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Text(l.confirm),
          ),
        ],
      );
    },
  );
}
