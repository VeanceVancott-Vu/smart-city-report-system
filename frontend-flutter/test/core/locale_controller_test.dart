import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/src/core/localization/locale_controller.dart';
import 'package:smart_city_report_frontend/src/core/localization/locale_storage.dart';

void main() {
  test('loads a supported saved language', () async {
    final controller = LocaleController(
      storage: MemoryLocaleStorage('vi'),
      initialLocale: const Locale('en'),
    );

    await controller.load();

    expect(controller.locale, const Locale('vi'));
  });

  test('ignores an unsupported saved language', () async {
    final controller = LocaleController(
      storage: MemoryLocaleStorage('fr'),
      initialLocale: const Locale('vi'),
    );

    await controller.load();

    expect(controller.locale, const Locale('vi'));
  });

  test('persists a selected language', () async {
    final storage = MemoryLocaleStorage();
    final controller = LocaleController(storage: storage);

    await controller.setLocale(const Locale('vi'));

    expect(controller.locale, const Locale('vi'));
    expect(storage.languageCode, 'vi');
  });

  test('keeps the selected language when persistence fails', () async {
    final controller = LocaleController(storage: _FailingLocaleStorage());

    await expectLater(controller.setLocale(const Locale('vi')), completes);

    expect(controller.locale, const Locale('vi'));
  });
}

class _FailingLocaleStorage implements LocaleStorage {
  @override
  Future<String?> readLanguageCode() async => null;

  @override
  Future<void> saveLanguageCode(String languageCode) {
    throw StateError('Storage unavailable');
  }
}
