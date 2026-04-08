import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import '../../shared/models/models.dart';

final gameSettingsStreamProvider = StreamProvider<GameSettings>((ref) {
  return supabase.from('game_settings').stream(primaryKey: ['id']).map((data) =>
      data.isEmpty ? GameSettings.empty() : GameSettings.fromJson(data.first));
});
