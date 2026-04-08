import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index de l'onglet actif dans le MainShell
final activeTabProvider = StateProvider<int>((ref) => 0);
