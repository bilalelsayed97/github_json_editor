enum JsonFieldType {
  string,
  boolean,
  integer,
  double,
  enumValue,
  html;

  String get displayName {
    switch (this) {
      case JsonFieldType.string:
        return 'String';
      case JsonFieldType.boolean:
        return 'Boolean';
      case JsonFieldType.integer:
        return 'Integer';
      case JsonFieldType.double:
        return 'Double';
      case JsonFieldType.enumValue:
        return 'Enum';
      case JsonFieldType.html:
        return 'HTML';
    }
  }

  static JsonFieldType fromValue(dynamic value) {
    if (value == null) return JsonFieldType.string;
    
    if (value is bool) return JsonFieldType.boolean;
    if (value is int) return JsonFieldType.integer;
    if (value is num && value is! int) return JsonFieldType.double;
    if (value is String) {
      // Check if it looks like HTML
      if (value.contains('<') && value.contains('>')) {
        return JsonFieldType.html;
      }
      return JsonFieldType.string;
    }
    
    return JsonFieldType.string;
  }
}