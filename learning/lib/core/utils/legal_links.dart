import 'package:url_launcher/url_launcher.dart';

import 'app_snackbars.dart';

const privacyPolicyUrl =
    'https://sites.google.com/view/profitpulsesalesexpenses/home';

Future<void> openPrivacyPolicy() async {
  final uri = Uri.parse(privacyPolicyUrl);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    showErrorSnackbar('Could not open the privacy policy link.');
  }
}
