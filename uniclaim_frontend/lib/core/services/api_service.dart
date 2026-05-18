import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dio_adapter_io.dart' if (dart.library.html) 'dio_adapter_web.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  CookieJar? _cookieJar;
  bool _initialized = false;

  // ⚠️  USB debugging → adb reverse tcp:3000 tcp:3000  puis localhost fonctionne
  static String get baseUrl => 'http://localhost:3000/api';

  Future<void> init() async {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl        : baseUrl,
      connectTimeout : const Duration(seconds: 15),
      receiveTimeout : const Duration(seconds: 15),
      headers        : {'Content-Type': 'application/json'},
    ));

    if (kIsWeb) {
      configureDioAdapter(_dio);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      _cookieJar = PersistCookieJar(
        storage: FileStorage('${dir.path}/.uniclaim_cookies/'),
      );
      _dio.interceptors.add(CookieManager(_cookieJar!));
    }

    _initialized = true;
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, dynamic data) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, dynamic data) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) =>
      _dio.delete(path);

  Future<Response> postForm(String path, FormData data) =>
      _dio.post(path, data: data,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));

  Future<void> clearSession() async {
    await _cookieJar?.deleteAll();
  }
}
