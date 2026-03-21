/// Modelo de un equipo dentro de un grupo (solo presentación/mock).
class TeamProgress {
  const TeamProgress({
    required this.name,
    required this.collected,
    required this.total,
    this.flagCode,
  });

  final String name;
  final int collected;
  final int total;
  final String? flagCode;

  bool get isComplete => total > 0 && collected >= total;
  double get percent => total > 0 ? (collected / total).clamp(0.0, 1.0) : 0.0;
}

/// Modelo de un grupo con equipos (solo presentación/mock).
class GroupWithTeams {
  const GroupWithTeams({
    required this.name,
    required this.teams,
  });

  final String name;
  final List<TeamProgress> teams;

  int get totalStickers => teams.fold(0, (s, t) => s + t.total);
  int get collectedStickers => teams.fold(0, (s, t) => s + t.collected);
  int get percentComplete => totalStickers > 0
      ? (collectedStickers / totalStickers * 100).round()
      : 0;
}
