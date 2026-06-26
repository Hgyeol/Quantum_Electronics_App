import 'package:web/web.dart' as web;

Future<bool> openExternalUrlImpl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  web.window.open(uri.toString(), '_blank');
  return true;
}
