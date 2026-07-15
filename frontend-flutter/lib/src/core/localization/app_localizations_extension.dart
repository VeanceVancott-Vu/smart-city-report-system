import 'package:flutter/widgets.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
