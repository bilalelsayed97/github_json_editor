// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_file_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepositoryFileModel _$RepositoryFileModelFromJson(Map<String, dynamic> json) =>
    RepositoryFileModel(
      name: json['name'] as String,
      path: json['path'] as String,
      sha: json['sha'] as String,
      size: (json['size'] as num).toInt(),
      downloadUrl: json['download_url'] as String,
    );

Map<String, dynamic> _$RepositoryFileModelToJson(
  RepositoryFileModel instance,
) => <String, dynamic>{
  'name': instance.name,
  'path': instance.path,
  'sha': instance.sha,
  'size': instance.size,
  'download_url': instance.downloadUrl,
};
