import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/github_config.dart';
import '../models/repository_file_model.dart';

abstract class GithubRemoteDataSource {
  Future<List<RepositoryFileModel>> getRepositoryFiles(GitHubConfig config);
  Future<Map<String, dynamic>> getFileContent(String filePath, GitHubConfig config);
  Future<void> updateFileContent(String filePath, String content, String sha, GitHubConfig config);
  Future<List<RepositoryFileModel>> searchJsonFiles(GitHubConfig config, [String query = '']);
}

class GithubRemoteDataSourceImpl implements GithubRemoteDataSource {
  final Dio dio;

  GithubRemoteDataSourceImpl({
    required this.dio,
  });

  void _setHeaders(GitHubConfig config) {
    dio.options.headers['Authorization'] = 'Bearer ${config.token}';
    dio.options.headers['Accept'] = 'application/vnd.github.v3+json';
    dio.options.headers['X-GitHub-Api-Version'] = '2022-11-28';
  }

  @override
  Future<List<RepositoryFileModel>> getRepositoryFiles(GitHubConfig config) async {
    try {
      _setHeaders(config);
      final repoContentsUrl = '${ApiConstants.githubBaseUrl}/repos/${config.username}/${config.repoName}/contents';
      final response = await dio.get('$repoContentsUrl?ref=${config.branch}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return await _getJsonFilesRecursively(data, config);
      } else {
        throw ServerFailure('Failed to fetch repository files: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerFailure('Unexpected error: $e');
    }
  }

  Future<List<RepositoryFileModel>> _getJsonFilesRecursively(
    List<dynamic> items,
    GitHubConfig config,
  ) async {
    final List<RepositoryFileModel> jsonFiles = [];

    for (final item in items) {
      if (item['type'] == 'file' && item['name'].toString().endsWith('.json')) {
        jsonFiles.add(RepositoryFileModel.fromJson(item));
      } else if (item['type'] == 'dir') {
        try {
          _setHeaders(config);
          final response = await dio.get('${item['url']}?ref=${config.branch}');
          if (response.statusCode == 200) {
            final subItems = await _getJsonFilesRecursively(response.data, config);
            jsonFiles.addAll(subItems);
          }
        } catch (e) {
          // Continue with other directories if one fails
          continue;
        }
      }
    }

    return jsonFiles;
  }

  @override
  Future<Map<String, dynamic>> getFileContent(String filePath, GitHubConfig config) async {
    try {
      _setHeaders(config);
      final repoContentsUrl = '${ApiConstants.githubBaseUrl}/repos/${config.username}/${config.repoName}/contents';
      final response = await dio.get('$repoContentsUrl/$filePath?ref=${config.branch}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final String encodedContent = data['content'];
        final String sha = data['sha'];
        
        // Decode base64 content
        final String decodedContent = utf8.decode(base64.decode(encodedContent.replaceAll('\n', '')));
        
        return {
          'content': decodedContent,
          'sha': sha,
        };
      } else {
        throw ServerFailure('Failed to fetch file content: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerFailure('Unexpected error: $e');
    }
  }

  @override
  Future<void> updateFileContent(String filePath, String content, String sha, GitHubConfig config) async {
    try {
      _setHeaders(config);
      final repoContentsUrl = '${ApiConstants.githubBaseUrl}/repos/${config.username}/${config.repoName}/contents';
      
      // Encode content to base64
      final encodedContent = base64.encode(utf8.encode(content));
      
      final requestData = {
        'message': 'Update $filePath via Quran Admin Panel 🤖',
        'content': encodedContent,
        'sha': sha,
        'branch': config.branch,
      };

      final response = await dio.put(
        '$repoContentsUrl/$filePath',
        data: requestData,
      );
      
      if (response.statusCode != 200) {
        throw ServerFailure('Failed to update file: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerFailure('Unexpected error: $e');
    }
  }

  @override
  Future<List<RepositoryFileModel>> searchJsonFiles(GitHubConfig config, [String query = '']) async {
    try {
      _setHeaders(config);
      final allFiles = await getRepositoryFiles(config);
      
      if (query.isEmpty) {
        return allFiles;
      }
      
      return allFiles.where((file) {
        final fileName = file.name.toLowerCase();
        final filePath = file.path.toLowerCase();
        final searchQuery = query.toLowerCase();
        
        return fileName.contains(searchQuery) || filePath.contains(searchQuery);
      }).toList();
    } catch (e) {
      throw ServerFailure('Search failed: $e');
    }
  }

  Failure _handleDioException(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return const AuthenticationFailure('Invalid GitHub token or insufficient permissions');
      case 403:
        return const AuthenticationFailure('GitHub API rate limit exceeded or access forbidden');
      case 404:
        return const ServerFailure('Repository, branch, or file not found');
      case 409:
        return const ServerFailure('File has been modified by someone else. Please refresh and try again.');
      case 422:
        return const ServerFailure('Invalid request data. Please check your input.');
      default:
        return NetworkFailure('Network error: ${e.message ?? 'Unknown error'}');
    }
  }
}