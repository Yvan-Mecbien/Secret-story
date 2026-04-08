import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Group ───────────────────────────────────────────────────────────────────
class GroupModel {
  final String id;
  final String name;
  final String color;
  final String lien;
  final int? nbrMembre;

  const GroupModel({
    required this.id,
    required this.name,
    required this.color,
    required this.lien,
    this.nbrMembre,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Groupe',
        lien: json['lien'] as String? ?? '',
        color: json['color'] as String? ?? 'blue',
        nbrMembre: json['nbr_membre'] as int?,
      );

  Color get flutterColor => AppColors.groupColor(color);

  // Constructeur pour les groupes sans nom/color (quand on a juste l'ID)
  factory GroupModel.fromId(String id) =>
      GroupModel(id: id, name: 'Groupe', color: 'blue', lien: '');
}

// ─── User ────────────────────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String pseudo;
  final String secret;
  final String? groupId;
  final int points;
  final bool isEliminated;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final GroupModel? group;
  final String? sessionToken;
  final DateTime? sessionExpiresAt;

  const UserModel({
    required this.id,
    required this.pseudo,
    required this.secret,
    this.groupId,
    required this.points,
    required this.isEliminated,
    required this.createdAt,
    this.updatedAt,
    this.group,
    this.sessionToken,
    this.sessionExpiresAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extraire les données du groupe
    GroupModel? groupModel;

    if (json['groups'] != null) {
      // Si groups est présent et c'est un Map
      if (json['groups'] is Map<String, dynamic>) {
        groupModel =
            GroupModel.fromJson(json['groups'] as Map<String, dynamic>);
      }
    } else if (json['group_id'] != null && json['group'] == null) {
      // Si on a seulement group_id, on crée un groupe basique
      groupModel = GroupModel.fromId(json['group_id'] as String);
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      pseudo: json['pseudo'] as String? ?? '',
      secret: json['secret'] as String? ?? '',
      groupId: json['group_id'] as String?,
      points: json['points'] as int? ?? 0,
      isEliminated: json['is_eliminated'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      group: groupModel,
      sessionToken: json['session_token'] as String?,
      sessionExpiresAt: json['session_expires_at'] != null
          ? DateTime.parse(json['session_expires_at'] as String)
          : null,
    );
  }

  Color get groupColor {
    if (group != null) {
      return group!.flutterColor;
    }
    return AppColors.primary;
  }

  String get initials {
    final t = pseudo.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return t.substring(0, t.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserModel copyWith({
    int? points,
    bool? isEliminated,
    GroupModel? group,
  }) {
    return UserModel(
      id: id,
      pseudo: pseudo,
      secret: secret,
      groupId: groupId,
      points: points ?? this.points,
      isEliminated: isEliminated ?? this.isEliminated,
      createdAt: createdAt,
      updatedAt: updatedAt,
      group: group ?? this.group,
      sessionToken: sessionToken,
      sessionExpiresAt: sessionExpiresAt,
    );
  }

  // Vérifier si la session est valide
  bool get isSessionValid {
    if (sessionExpiresAt == null) return false;
    return DateTime.now().isBefore(sessionExpiresAt!);
  }
}

// ─── Game ────────────────────────────────────────────────────────────────────
class GameModel {
  final String id;
  final String title;
  final String description;
  final int pointsReward;
  final int time;
  final String gameType;
  final bool isActive;
  final DateTime createdAt;

  const GameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsReward,
    required this.isActive,
    required this.gameType,
    required this.time,
    required this.createdAt,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) => GameModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        pointsReward: json['points_reward'] as int? ?? 50,
        time: json['time'] as int? ?? 20,
        isActive: json['is_active'] as bool? ?? false,
        gameType: json['game_type'] as String? ?? 'quiz',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

// ─── GameSettings ────────────────────────────────────────────────────────────
class GameSettings {
  final String id;
  final bool gameStarted;
  final String currentPhase;

  const GameSettings({
    required this.id,
    required this.gameStarted,
    required this.currentPhase,
  });

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        id: json['id'] as String? ?? '',
        gameStarted: json['game_started'] as bool? ?? false,
        currentPhase: json['current_phase'] as String? ?? 'waiting',
      );

  factory GameSettings.empty() =>
      const GameSettings(id: '', gameStarted: false, currentPhase: 'waiting');

  bool get isVotePhase => currentPhase == 'vote';
  bool get isGamePhase => currentPhase == 'game';
  bool get isElimination => currentPhase == 'elimination';
  bool get isFinished => currentPhase == 'finished';
}

// ─── PointHistory ────────────────────────────────────────────────────────────
class PointHistory {
  final String id;
  final String userId;
  final String? gameId;
  final int points;
  final String reason;
  final DateTime createdAt;

  const PointHistory({
    required this.id,
    required this.userId,
    this.gameId,
    required this.points,
    required this.reason,
    required this.createdAt,
  });

  factory PointHistory.fromJson(Map<String, dynamic> json) => PointHistory(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        gameId: json['game_id'] as String?,
        points: json['points'] as int? ?? 0,
        reason: json['reason'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

class IndiceModel {
  final String id;
  final String userId;
  final String? userPseudo;
  final String indice;
  final bool visible;
  final DateTime createdAt;

  const IndiceModel({
    required this.id,
    required this.userId,
    required this.indice,
    required this.userPseudo,
    required this.visible,
    required this.createdAt,
  });

  factory IndiceModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['user_id'] as Map<String, dynamic>?;
    return IndiceModel(
      id: json['id'] as String,
      userId: userObj?['id'] as String? ?? '',
      userPseudo: userObj?['pseudo'] as String?,
      indice: json['indice'] as String,
      visible: json['visible'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class QuestionModel {
  final String id;
  final String gameId;
  final int position;
  final String question;
  final List<String> options;
  final String answer; // index (string) ou texte selon le type
  final Map<String, dynamic>? extra;

  const QuestionModel({
    required this.id,
    required this.gameId,
    required this.position,
    required this.question,
    required this.options,
    required this.answer,
    this.extra,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> j) {
    final rawOpts = j['options'];
    List<String> opts = [];
    if (rawOpts is List) opts = rawOpts.map((e) => e.toString()).toList();

    return QuestionModel(
      id: j['id'] as String,
      gameId: j['game_id'] as String,
      position: j['position'] as int? ?? 0,
      question: j['question'] as String,
      options: opts,
      answer: j['answer'] as String,
      extra: j['extra'] as Map<String, dynamic>?,
    );
  }

  int get answerIndex => int.tryParse(answer) ?? 0;
}

class GameSessionState {
  final int score;
  final int currentQuestion;
  final bool completed;
  final DateTime startedAt;
  final DateTime lastActiveAt;

  const GameSessionState({
    required this.score,
    required this.currentQuestion,
    required this.completed,
    required this.startedAt,
    required this.lastActiveAt,
  });

  GameSessionState copyWith({
    int? score,
    int? currentQuestion,
    bool? completed,
    DateTime? lastActiveAt,
  }) =>
      GameSessionState(
        score: score ?? this.score,
        currentQuestion: currentQuestion ?? this.currentQuestion,
        completed: completed ?? this.completed,
        startedAt: startedAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      );
}
