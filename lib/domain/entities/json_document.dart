import 'dart:convert';
import 'json_field.dart';
import 'json_field_type.dart';

class JsonDocument {
  final String filePath;
  final String fileName;
  final String sha;
  final List<JsonField> fields;
  final Map<String, dynamic> originalContent;

  const JsonDocument({
    required this.filePath,
    required this.fileName,
    required this.sha,
    required this.fields,
    required this.originalContent,
  });

  static JsonDocument fromJsonString(
    String content,
    String filePath,
    String fileName,
    String sha,
  ) {
    final Map<String, dynamic> jsonMap = jsonDecode(content);
    final List<JsonField> fields = _extractFields(jsonMap);

    return JsonDocument(
      filePath: filePath,
      fileName: fileName,
      sha: sha,
      fields: fields,
      originalContent: jsonMap,
    );
  }

  static List<JsonField> _extractFields(Map<String, dynamic> jsonMap) {
    final List<JsonField> fields = [];

    void extractRecursive(Map<String, dynamic> map, [String prefix = '']) {
      for (final entry in map.entries) {
        final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
        final value = entry.value;

        if (value is Map<String, dynamic>) {
          extractRecursive(value, key);
        } else if (value is List) {
          // Handle arrays - for now, treat as JSON string
          fields.add(JsonField(
            key: key,
            value: jsonEncode(value),
            type: JsonFieldType.string,
          ));
        } else {
          fields.add(JsonField(
            key: key,
            value: value,
            type: JsonFieldType.fromValue(value),
          ));
        }
      }
    }

    extractRecursive(jsonMap);
    return fields;
  }

  JsonDocument copyWith({
    String? filePath,
    String? fileName,
    String? sha,
    List<JsonField>? fields,
    Map<String, dynamic>? originalContent,
  }) {
    return JsonDocument(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      sha: sha ?? this.sha,
      fields: fields ?? this.fields,
      originalContent: originalContent ?? this.originalContent,
    );
  }

  JsonDocument updateField(int index, JsonField newField) {
    final updatedFields = List<JsonField>.from(fields);
    updatedFields[index] = newField;
    return copyWith(fields: updatedFields);
  }

  JsonDocument addField(JsonField field) {
    final updatedFields = List<JsonField>.from(fields)..add(field);
    return copyWith(fields: updatedFields);
  }

  JsonDocument removeField(int index) {
    final updatedFields = List<JsonField>.from(fields)..removeAt(index);
    return copyWith(fields: updatedFields);
  }

  Map<String, dynamic> toJsonMap() {
    final Map<String, dynamic> result = {};

    for (final field in fields) {
      _setNestedValue(result, field.key, field.value);
    }

    return result;
  }

  void _setNestedValue(Map<String, dynamic> map, String key, dynamic value) {
    final parts = key.split('.');
    Map<String, dynamic> current = map;

    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (!current.containsKey(part)) {
        current[part] = <String, dynamic>{};
      }
      current = current[part] as Map<String, dynamic>;
    }

    current[parts.last] = value;
  }

  String toJsonString({bool pretty = true}) {
    final jsonMap = toJsonMap();
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonMap);
    }
    return jsonEncode(jsonMap);
  }

  bool get hasChanges {
    final currentJson = toJsonMap();
    return !_deepEquals(currentJson, originalContent);
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a.runtimeType != b.runtimeType) return false;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
          return false;
        }
      }
      return true;
    } else if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  @override
  String toString() {
    return 'JsonDocument(fileName: $fileName, fieldsCount: ${fields.length})';
  }
}