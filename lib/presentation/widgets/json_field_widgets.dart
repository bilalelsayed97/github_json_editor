import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/json_field.dart';
import '../../domain/entities/json_field_type.dart';
import 'code_editor_widget.dart';

abstract class JsonFieldWidget extends StatelessWidget {
  final JsonField field;
  final ValueChanged<JsonField> onChanged;
  final ValueChanged<JsonFieldType>? onTypeChanged;
  final bool isReadOnly;

  const JsonFieldWidget({
    super.key,
    required this.field,
    required this.onChanged,
    this.onTypeChanged,
    this.isReadOnly = false,
  });

  factory JsonFieldWidget.create({
    required JsonField field,
    required ValueChanged<JsonField> onChanged,
    ValueChanged<JsonFieldType>? onTypeChanged,
    bool isReadOnly = false,
  }) {
    switch (field.type) {
      case JsonFieldType.string:
        return StringFieldWidget(
          field: field,
          onChanged: onChanged,
          onTypeChanged: onTypeChanged,
          isReadOnly: isReadOnly,
        );
      case JsonFieldType.boolean:
        return BooleanFieldWidget(
          field: field,
          onChanged: onChanged,
          onTypeChanged: onTypeChanged,
          isReadOnly: isReadOnly,
        );
      case JsonFieldType.integer:
        return IntegerFieldWidget(
          field: field,
          onChanged: onChanged,
          onTypeChanged: onTypeChanged,
          isReadOnly: isReadOnly,
        );
      case JsonFieldType.double:
        return DoubleFieldWidget(
          field: field,
          onChanged: onChanged,
          onTypeChanged: onTypeChanged,
          isReadOnly: isReadOnly,
        );
      case JsonFieldType.enumValue:
        return EnumFieldWidget(
          field: field,
          onChanged: onChanged,
          onTypeChanged: onTypeChanged,
          isReadOnly: isReadOnly,
        );
      case JsonFieldType.html:
        return HtmlFieldWidget(
          field: field,
          onChanged: onChanged,
          onTypeChanged: onTypeChanged,
          isReadOnly: isReadOnly,
        );
    }
  }
}

class StringFieldWidget extends JsonFieldWidget {
  const StringFieldWidget({
    super.key,
    required super.field,
    required super.onChanged,
    super.onTypeChanged,
    super.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: field.value?.toString() ?? '');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldHeader(context),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !isReadOnly,
          maxLines: field.value?.toString().contains('\n') == true ? null : 1,
          decoration: InputDecoration(
            hintText: 'Enter string value',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.text_fields),
          ),
          onChanged: (value) {
            onChanged(field.copyWith(value: value));
          },
          validator: (value) => field.validateValue(value ?? ''),
        ),
      ],
    );
  }

  Widget _buildFieldHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.key,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildTypeChip(context, JsonFieldType.string),
      ],
    );
  }
}

class BooleanFieldWidget extends JsonFieldWidget {
  const BooleanFieldWidget({
    super.key,
    required super.field,
    required super.onChanged,
    super.onTypeChanged,
    super.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final boolValue = field.value is bool 
        ? field.value as bool 
        : (field.value?.toString().toLowerCase() == 'true');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldHeader(context),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.toggle_on),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Boolean Value',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Switch(
                  value: boolValue,
                  onChanged: isReadOnly ? null : (value) {
                    onChanged(field.copyWith(value: value));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.key,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildTypeChip(context, JsonFieldType.boolean),
      ],
    );
  }
}

class IntegerFieldWidget extends JsonFieldWidget {
  const IntegerFieldWidget({
    super.key,
    required super.field,
    required super.onChanged,
    super.onTypeChanged,
    super.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: field.value?.toString() ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldHeader(context),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !isReadOnly,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
          decoration: InputDecoration(
            hintText: 'Enter integer value',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.numbers),
          ),
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null || value.isEmpty) {
              onChanged(field.copyWith(value: intValue ?? 0));
            }
          },
          validator: (value) => field.validateValue(value ?? ''),
        ),
      ],
    );
  }

  Widget _buildFieldHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.key,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildTypeChip(context, JsonFieldType.integer),
      ],
    );
  }
}

class DoubleFieldWidget extends JsonFieldWidget {
  const DoubleFieldWidget({
    super.key,
    required super.field,
    required super.onChanged,
    super.onTypeChanged,
    super.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: field.value?.toString() ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldHeader(context),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !isReadOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
          decoration: InputDecoration(
            hintText: 'Enter decimal value',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.pin),
          ),
          onChanged: (value) {
            final doubleValue = double.tryParse(value);
            if (doubleValue != null || value.isEmpty) {
              onChanged(field.copyWith(value: doubleValue ?? 0.0));
            }
          },
          validator: (value) => field.validateValue(value ?? ''),
        ),
      ],
    );
  }

  Widget _buildFieldHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.key,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildTypeChip(context, JsonFieldType.double),
      ],
    );
  }
}

class EnumFieldWidget extends JsonFieldWidget {
  const EnumFieldWidget({
    super.key,
    required super.field,
    required super.onChanged,
    super.onTypeChanged,
    super.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = field.enumOptions ?? [];
    final currentValue = field.value?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldHeader(context),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: options.contains(currentValue) ? currentValue : null,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: isReadOnly ? null : (value) {
            if (value != null) {
              onChanged(field.copyWith(value: value));
            }
          },
          decoration: InputDecoration(
            hintText: 'Select an option',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.list),
          ),
          validator: (value) => field.validateValue(value ?? ''),
        ),
        if (options.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'No enum options defined. You can edit this as a string field.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.key,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildTypeChip(context, JsonFieldType.enumValue),
      ],
    );
  }
}

class HtmlFieldWidget extends JsonFieldWidget {
  const HtmlFieldWidget({
    super.key,
    required super.field,
    required super.onChanged,
    super.onTypeChanged,
    super.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final htmlContent = field.value?.toString() ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldHeader(context),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code),
                    const SizedBox(width: 8),
                    Text(
                      'HTML Content',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CodeEditorWidget(
                  content: htmlContent,
                  language: 'html',
                  readOnly: isReadOnly,
                  height: 300,
                  onChanged: isReadOnly ? null : (value) {
                    onChanged(field.copyWith(value: value));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.key,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildTypeChip(context, JsonFieldType.html),
      ],
    );
  }
}

Widget _buildTypeChip(BuildContext context, JsonFieldType type) {
  final colors = {
    JsonFieldType.string: Colors.blue,
    JsonFieldType.boolean: Colors.green,
    JsonFieldType.integer: Colors.orange,
    JsonFieldType.double: Colors.purple,
    JsonFieldType.enumValue: Colors.teal,
    JsonFieldType.html: Colors.red,
  };

  return Chip(
    label: Text(
      type.displayName,
      style: const TextStyle(fontSize: 12),
    ),
    backgroundColor: colors[type]?.withValues(alpha: 0.1),
    side: BorderSide(color: colors[type] ?? Colors.grey),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}