import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/network_info.dart';
import '../data/datasources/github_remote_datasource.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  
  sl.registerLazySingleton(() => sharedPreferences);
  
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options.baseUrl = 'https://api.github.com';
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    return dio;
  });

  sl.registerLazySingleton(() => NetworkInfo(dio: sl()));

  sl.registerLazySingleton<GithubRemoteDataSource>(() {
    return GithubRemoteDataSourceImpl(
      dio: sl(),
    );
  });
}