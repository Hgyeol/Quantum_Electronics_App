import 'url_opener_stub.dart'
    if (dart.library.html) 'url_opener_web.dart';

Future<bool> openExternalUrl(String url) => openExternalUrlImpl(url);
