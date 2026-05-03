import 'package:easy_localization/easy_localization.dart';

/// Convierte el nombre de grupo del seed (`Group A`, … `Group L`) al texto localizado.
String localizedGroupDisplayName(String groupName) {
  final parts = groupName.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].toLowerCase() == 'group') {
    return 'groupWithLetter'.tr(args: [parts.last]);
  }
  return groupName;
}
