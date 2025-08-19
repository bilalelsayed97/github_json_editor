class ApiConstants {
  static const String githubBaseUrl = 'https://api.github.com';
  static const String repoOwner = '';
  static const String repoName = '';

  static String get repoContentsUrl => '$githubBaseUrl/repos/$repoOwner/$repoName/contents';
}
