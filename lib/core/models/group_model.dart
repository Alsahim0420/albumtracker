import 'team_model.dart';

/// Modelo de dominio: un grupo (A–L) del Mundial 2026.
class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.teams,
  });

  final String id;
  final String name;
  final List<TeamModel> teams;

  int get totalStickers => teams.fold(0, (s, t) => s + t.totalStickers);
}
