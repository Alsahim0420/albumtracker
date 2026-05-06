import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Guarda el CSV en el directorio temporal y abre el selector para compartir (IO).
Future<void> shareExportedCsv(String csv, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(csv, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv', name: fileName)],
    subject: 'Album Tracker',
  );
}
