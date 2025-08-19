import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/repository_file.dart';

part 'repository_file_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RepositoryFileModel extends RepositoryFile {
  const RepositoryFileModel({
    required super.name,
    required super.path,
    required super.sha,
    required super.size,
    required super.downloadUrl,
  });

  factory RepositoryFileModel.fromJson(Map<String, dynamic> json) =>
      _$RepositoryFileModelFromJson(json);

  Map<String, dynamic> toJson() => _$RepositoryFileModelToJson(this);
}