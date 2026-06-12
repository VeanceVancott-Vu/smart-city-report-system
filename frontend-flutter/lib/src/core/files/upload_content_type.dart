import 'package:http_parser/http_parser.dart';

MediaType? uploadContentTypeForFilename(String filename) {
  final extension = _extensionOf(filename);
  return switch (extension) {
    'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
    'png' => MediaType('image', 'png'),
    'webp' => MediaType('image', 'webp'),
    _ => null,
  };
}

String _extensionOf(String filename) {
  final trimmed = filename.trim();
  final extensionStart = trimmed.lastIndexOf('.');
  if (extensionStart < 0 || extensionStart == trimmed.length - 1) {
    return '';
  }
  return trimmed.substring(extensionStart + 1).toLowerCase();
}
