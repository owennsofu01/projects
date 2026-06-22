import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Sign in with Apple is only wired up natively for iOS/macOS in this app.
/// `kIsWeb` must be checked first — touching `Platform.*` on web throws.
bool get supportsAppleSignIn {
  if (kIsWeb) return false;
  return Platform.isIOS || Platform.isMacOS;
}
