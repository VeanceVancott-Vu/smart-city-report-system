import 'package:file_picker/file_picker.dart';

class UploadFilePick {
  const UploadFilePick({required this.filename, required this.bytes});

  final String filename;
  final List<int> bytes;
}

Future<UploadFilePick?> pickImageUploadFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    allowMultiple: false,
    withData: true,
  );

  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw const FilePickerException('Unable to read selected image.');
  }

  return UploadFilePick(filename: file.name, bytes: bytes);
}

class FilePickerException implements Exception {
  const FilePickerException(this.message);

  final String message;

  @override
  String toString() => message;
}
