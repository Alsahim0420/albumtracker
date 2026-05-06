import 'package:share_plus/share_plus.dart';

/// En web no hay rutas de archivo locales; se comparte el texto CSV.
Future<void> shareExportedCsv(String csv, String fileName) async {
  await Share.share(csv, subject: 'Album Tracker');
}
