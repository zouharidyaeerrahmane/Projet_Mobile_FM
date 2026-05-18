import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

void configureDioAdapter(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
