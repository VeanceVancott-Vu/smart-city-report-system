import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class LocaleStorage {
  Future<String?> readLanguageCode();

  Future<void> saveLanguageCode(String languageCode);
}

class SecureLocaleStorage implements LocaleStorage {
  const SecureLocaleStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _languageCodeKey = 'smart_city_language_code';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readLanguageCode() {
    return _storage.read(key: _languageCodeKey);
  }

  @override
  Future<void> saveLanguageCode(String languageCode) {
    return _storage.write(key: _languageCodeKey, value: languageCode);
  }
}

class MemoryLocaleStorage implements LocaleStorage {
  MemoryLocaleStorage([this.languageCode]);

  String? languageCode;

  @override
  Future<String?> readLanguageCode() async => languageCode;

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
  }
}
