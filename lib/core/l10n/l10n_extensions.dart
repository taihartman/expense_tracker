import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Extension to easily access localization strings from BuildContext
extension LocalizationExtension on BuildContext {
  /// Returns the [AppLocalizations] instance for this context
  ///
  /// Usage: `context.l10n.stringKey`
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
