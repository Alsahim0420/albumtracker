import 'package:image_picker/image_picker.dart';

class StickerImageInputService {
  StickerImageInputService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<List<String>> pickSingleFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return const [];
    return [image.path];
  }

  Future<List<String>> pickMultipleFromGallery() async {
    final images = await _picker.pickMultiImage();
    return images.map((x) => x.path).toList();
  }

  Future<List<String>> captureSinglePhoto() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return const [];
    return [image.path];
  }
}
