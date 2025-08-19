class RepositoryFile {
  final String name;
  final String path;
  final String sha;
  final int size;
  final String downloadUrl;

  const RepositoryFile({
    required this.name,
    required this.path,
    required this.sha,
    required this.size,
    required this.downloadUrl,
  });
}