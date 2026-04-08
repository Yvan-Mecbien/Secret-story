import 'package:app/features/auth/StorageService.dart';
import 'package:app/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_page.dart';
import '../main_shell.dart';
import 'onboarding_page.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    StorageService().hasSeenOnboarding().then((seen) {
      if (mounted) setState(() => _seenOnboarding = seen);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).getCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chargement initial
    if (_seenOnboarding == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Onboarding pas encore vu
    if (!_seenOnboarding!) {
      return OnboardingPage(
        onDone: () => setState(() => _seenOnboarding = true),
      );
    }

    final authState = ref.watch(currentUserProvider);

    return authState.when(
      data: (user) {
        // Session vérifiée
        if (user != null) {
          return const MainShell();
        }
        return const LoginPage();
      },
      loading: () {
        // Affichage pendant la vérification de session
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                SizedBox(height: 24),
                Text(
                  'Chargement de votre session...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, stack) {
        // En cas d'erreur, rediriger vers login
        return const LoginPage();
      },
    );
  }
}
