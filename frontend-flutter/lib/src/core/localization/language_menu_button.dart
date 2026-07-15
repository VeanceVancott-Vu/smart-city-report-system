import 'dart:async';

import 'package:flutter/material.dart';

import 'app_localizations_extension.dart';
import 'locale_scope.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    final languageCode = controller.locale.languageCode;

    return PopupMenuButton<String>(
      initialValue: languageCode,
      tooltip: context.l10n.language,
      icon: const Icon(Icons.language),
      onSelected: (selectedLanguageCode) {
        unawaited(controller.setLocale(Locale(selectedLanguageCode)));
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String>(
          value: 'en',
          checked: languageCode == 'en',
          child: Text(context.l10n.english),
        ),
        CheckedPopupMenuItem<String>(
          value: 'vi',
          checked: languageCode == 'vi',
          child: Text(context.l10n.vietnamese),
        ),
      ],
    );
  }
}
