import 'json_field_type.dart';

class JsonField {
  final String key;
  final dynamic value;
  final JsonFieldType type;
  final List<String>? enumOptions;
  final bool isRequired;

  const JsonField({
    required this.key,
    required this.value,
    required this.type,
    this.enumOptions,
    this.isRequired = false,
  });

  JsonField copyWith({
    String? key,
    dynamic value,
    JsonFieldType? type,
    List<String>? enumOptions,
    bool? isRequired,
  }) {
    return JsonField(
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      enumOptions: enumOptions ?? this.enumOptions,
      isRequired: isRequired ?? this.isRequired,
    );
  }

  Map<String, dynamic> toJson() {
    return {key: value};
  }

  String? validateValue(String input) {
    if (isRequired && input.trim().isEmpty) {
      return 'This field is required';
    }

    switch (type) {
      case JsonFieldType.boolean:
        if (input.toLowerCase() != 'true' && input.toLowerCase() != 'false') {
          return 'Value must be true or false';
        }
        break;
      case JsonFieldType.integer:
        if (int.tryParse(input) == null) {
          return 'Value must be a valid integer';
        }
        break;
      case JsonFieldType.double:
        if (double.tryParse(input) == null) {
          return 'Value must be a valid number';
        }
        break;
      case JsonFieldType.enumValue:
        if (enumOptions != null && !enumOptions!.contains(input)) {
          return 'Value must be one of: ${enumOptions!.join(', ')}';
        }
        break;
      case JsonFieldType.string:
      case JsonFieldType.html:
        // String and HTML values are always valid
        break;
    }

    return null;
  }

  dynamic getTypedValue(String input) {
    switch (type) {
      case JsonFieldType.boolean:
        return input.toLowerCase() == 'true';
      case JsonFieldType.integer:
        return int.tryParse(input) ?? 0;
      case JsonFieldType.double:
        return double.tryParse(input) ?? 0.0;
      case JsonFieldType.string:
      case JsonFieldType.enumValue:
      case JsonFieldType.html:
        return input;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JsonField &&
        other.key == key &&
        other.value == value &&
        other.type == type;
  }

  @override
  int get hashCode => key.hashCode ^ value.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'JsonField(key: $key, value: $value, type: $type)';
  }
}