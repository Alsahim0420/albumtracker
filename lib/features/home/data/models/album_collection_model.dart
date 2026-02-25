// ignore: depend_on_referenced_packages, file_names
import 'package:hive/hive.dart';


@HiveType(typeId: 0)
class AlbumCollectionModel extends HiveObject {

  @HiveField(0)
  final Map<String, int> collectedStickers;

  AlbumCollectionModel({
    required this.collectedStickers,
  });
}