import 'package:app/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

final leaderboardStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return supabase
      .from('users')
      .stream(primaryKey: ['id'])
      .order('points', ascending: false)
      .map((data) => (data as List).map((j) => UserModel.fromJson(j)).toList());
});

final fullLeaderboardProvider = FutureProvider<List<UserModel>>((ref) async {
  final data = await supabase
      .from('users')
      .select('*, groups(*)')
      .order('points', ascending: false);
  return (data as List).map((j) => UserModel.fromJson(j)).toList();
});
