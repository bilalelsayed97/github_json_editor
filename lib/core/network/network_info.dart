import 'package:dio/dio.dart';

class NetworkInfo {
  final Dio dio;
  
  NetworkInfo({required this.dio});
  
  Future<bool> get isConnected async {
    try {
      final response = await dio.get('https://www.google.com');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}