import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

const String kBaseUrl = 'http://localhost:8000';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  void init({String baseUrl = kBaseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      extra: {'withCredentials': true},
    ));
    // 웹에서는 브라우저가 쿠키를 자동 처리 — CookieManager 불필요
    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(CookieJar()));
    }
  }

  Dio get dio => _dio;

  String wsUrl(String path) {
    final base = _dio.options.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    return '$base$path';
  }
}

final api = ApiClient.instance;
