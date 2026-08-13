import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Sign in with Apple is only wired up natively for iOS/macOS in this app.
/// `kIsWeb` must be checked first — touching `Platform.*` on web throws.
bool get supportsAppleSignIn {
  if (kIsWeb) return false;
  return Platform.isIOS || Platform.isMacOS;
}

/// Google Sign-In is wired up for the mobile/desktop-Apple platforms the
/// `google_sign_in` plugin supports with app-provided UI. Windows/Linux
/// aren't in the plugin's supported platform list, and web needs a
/// platform-rendered button instead of this app's custom one.
/// `kIsWeb` must be checked first — touching `Platform.*` on web throws.
bool get supportsGoogleSignIn {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}
