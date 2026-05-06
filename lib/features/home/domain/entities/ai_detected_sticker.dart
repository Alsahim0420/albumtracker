class AiDetectedSticker {
  const AiDetectedSticker({
    required this.stickerCode,
    required this.countryCode,
    required this.number,
    required this.type,
    required this.playerName,
    required this.teamName,
    required this.rawText,
    required this.confidence,
  });

  final String? stickerCode;
  final String? countryCode;
  final int? number;
  final String type;
  final String? playerName;
  final String? teamName;
  final String? rawText;
  final double confidence;
}
