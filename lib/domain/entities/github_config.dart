class GitHubConfig {
  final String token;
  final String username;
  final String repoName;
  final String branch;

  const GitHubConfig({
    required this.token,
    required this.username,
    required this.repoName,
    required this.branch,
  });

  GitHubConfig copyWith({
    String? token,
    String? username,
    String? repoName,
    String? branch,
  }) {
    return GitHubConfig(
      token: token ?? this.token,
      username: username ?? this.username,
      repoName: repoName ?? this.repoName,
      branch: branch ?? this.branch,
    );
  }

  Map<String, String> toMap() {
    return {
      'github_token': token,
      'github_username': username,
      'github_repo_name': repoName,
      'github_branch': branch,
    };
  }

  static GitHubConfig fromMap(Map<String, String> map) {
    return GitHubConfig(
      token: map['github_token'] ?? '',
      username: map['github_username'] ?? '',
      repoName: map['github_repo_name'] ?? '',
      branch: map['github_branch'] ?? 'main',
    );
  }

  bool get isValid {
    return token.isNotEmpty &&
           username.isNotEmpty &&
           repoName.isNotEmpty &&
           branch.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GitHubConfig &&
        other.token == token &&
        other.username == username &&
        other.repoName == repoName &&
        other.branch == branch;
  }

  @override
  int get hashCode {
    return token.hashCode ^
           username.hashCode ^
           repoName.hashCode ^
           branch.hashCode;
  }

  @override
  String toString() {
    return 'GitHubConfig(username: $username, repoName: $repoName, branch: $branch)';
  }
}