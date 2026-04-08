import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/theme_provider.dart';
import '../../shared/widgets/loading_button.dart';
import '../../shared/l10n/app_localizations.dart';
import '../main_shell.dart';
import 'auth_provider.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await ref.read(authNotifierProvider.notifier).login(
            pseudo: _pseudoCtrl.text.trim(),
            password: _passCtrl.text,
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
    } catch (_) {
      final l = AppLocalizations.of(context);
      setState(() => _error = l.loginError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LogoWidget()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE6E6F0)),
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
                          Text(l.login,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _pseudoCtrl,
                            decoration: InputDecoration(
                                labelText: l.pseudo,
                                prefixIcon: const Icon(Icons.person_outline)),
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l.pseudoRequired
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: l.password,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure)),
                            ),
                            onFieldSubmitted: (_) => _login(),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l.passwordRequired
                                : null,
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
                                  onPressed: _login,
                                  child: Text(l.loginButton))),
                        ]),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(l.noAccount,
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const Register())),
                    child: Text(l.register,
                        style: TextStyle(
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ]).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: const Center(child: Text('🔮', style: TextStyle(fontSize: 36))),
      ),
      const SizedBox(height: 14),
      Text('Secret Story',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              letterSpacing: -0.5)),
      Text('Le jeu des secrets',
          style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
    ]);
  }
}
