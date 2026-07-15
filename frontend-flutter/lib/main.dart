import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/localization/locale_controller.dart';
import 'src/core/localization/locale_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = LocaleController(
    storage: const SecureLocaleStorage(),
    initialLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
  await localeController.load();

  runApp(SmartCityReportApp(localeController: localeController));
}
