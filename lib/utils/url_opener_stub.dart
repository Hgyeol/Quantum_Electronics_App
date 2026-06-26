import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrlImpl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
