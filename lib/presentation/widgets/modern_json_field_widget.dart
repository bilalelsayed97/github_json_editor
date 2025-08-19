import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/json_field.dart';
import '../../domain/entities/json_field_type.dart';
import 'code_editor_widget.dart';

class ModernJsonFieldWidget extends StatefulWidget {
  final JsonField field;
  final ValueChanged<JsonField> onChanged;
  final ValueChanged<JsonFieldType>? onTypeChanged;
  final VoidCallback? onDelete;
  final bool isReadOnly;

  const ModernJsonFieldWidget({
    super.key,
    required this.field,
    required this.onChanged,
    this.onTypeChanged,
    this.onDelete,
    this.isReadOnly = false,
  });

  @override
  State<ModernJsonFieldWidget> createState() => _ModernJsonFieldWidgetState();
}

class _ModernJsonFieldWidgetState extends State<ModernJsonFieldWidget> with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isHovered = false;
  late TextEditingController _keyController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fadeController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _keyController = TextEditingController(text: widget.field.key);
    _valueController = TextEditingController(text: widget.field.value?.toString() ?? '');

    _keyController.addListener(_onKeyChanged);
    _valueController.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    _expandController.dispose();
    _fadeController.dispose();
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _onKeyChanged() {
    final newField = widget.field.copyWith(key: _keyController.text);
    widget.onChanged(newField);
  }

  void _onValueChanged() {
    final typedValue = widget.field.getTypedValue(_valueController.text);
    final newField = widget.field.copyWith(value: typedValue);
    widget.onChanged(newField);
  }

  void _onTypeChanged(JsonFieldType newType) {
    if (widget.onTypeChanged != null) {
      widget.onTypeChanged!(newType);
    }
  }

  Color _getTypeColor() {
    switch (widget.field.type) {
      case JsonFieldType.string:
        return Colors.blue;
      case JsonFieldType.boolean:
        return Colors.green;
      case JsonFieldType.integer:
        return Colors.orange;
      case JsonFieldType.double:
        return Colors.purple;
      case JsonFieldType.enumValue:
        return Colors.teal;
      case JsonFieldType.html:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = _getTypeColor();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _isHovered
              ? LinearGradient(
                  colors: [colorScheme.surfaceContainer, colorScheme.surfaceContainerHighest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isHovered ? null : colorScheme.surfaceContainer,
          boxShadow: _isHovered
              ? [BoxShadow(color: typeColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(
            color: _isHovered ? typeColor.withValues(alpha: 0.3) : colorScheme.outline.withValues(alpha: 0.1),
            width: _isHovered ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(children: [_buildHeader(theme, typeColor)]),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color typeColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              // Key field
              Expanded(child: _buildKeyField(theme)),

              const SizedBox(width: 8),

              // Type selector
              _buildTypeSelector(theme, typeColor),

              const SizedBox(width: 4),

              // Actions
              _buildActions(theme, typeColor),
            ],
          ),

          const SizedBox(height: 16),

          // Value field (compact)
          _buildValueField(theme, compact: true),
        ],
      ),
    );
  }

  Widget _buildKeyField(ThemeData theme) {
    return TextFormField(
      controller: _keyController,
      enabled: !widget.isReadOnly,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: 'Key',
        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        filled: true,
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme, Color typeColor) {
    return PopupMenuButton<JsonFieldType>(
      enabled: !widget.isReadOnly && widget.onTypeChanged != null,
      itemBuilder: (context) => JsonFieldType.values.map((type) {
        final color = _getTypeColorForType(type);
        return PopupMenuItem<JsonFieldType>(
          value: type,
          child: Row(
            children: [
              Icon(_getTypeIconForType(type), color: color, size: 16),
              const SizedBox(width: 8),
              Text(type.displayName),
            ],
          ),
        );
      }).toList(),
      onSelected: _onTypeChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: typeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.field.type.displayName,
              style: theme.textTheme.labelMedium?.copyWith(color: typeColor, fontWeight: FontWeight.w600),
            ),
            if (!widget.isReadOnly && widget.onTypeChanged != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 16, color: typeColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(ThemeData theme, Color typeColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delete
        if (widget.onDelete != null)
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline),
            color: theme.colorScheme.error,
            tooltip: 'Delete field',
          ),
      ],
    );
  }

  Widget _buildValueField(ThemeData theme, {required bool compact}) {
    switch (widget.field.type) {
      case JsonFieldType.boolean:
        return _buildBooleanField(theme, compact);
      case JsonFieldType.enumValue:
        return _buildEnumField(theme, compact);
      case JsonFieldType.html:
        return compact ? _buildHtmlPreview(theme) : _buildHtmlEditor(theme);
      default:
        return _buildTextField(theme, compact);
    }
  }

  Widget _buildTextField(ThemeData theme, bool compact) {
    return TextFormField(
      controller: _valueController,
      enabled: !widget.isReadOnly,
      keyboardType: widget.field.type == JsonFieldType.integer || widget.field.type == JsonFieldType.double
          ? TextInputType.number
          : TextInputType.text,
      inputFormatters: _getInputFormatters(),
      maxLines: compact ? 1 : null,
      minLines: compact ? 1 : 3,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: _getHintText(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: EdgeInsets.all(compact ? 12 : 16),
      ),
      validator: (value) => widget.field.validateValue(value ?? ''),
    );
  }

  Widget _buildBooleanField(ThemeData theme, bool compact) {
    final boolValue = widget.field.value is bool ? widget.field.value as bool : (widget.field.value?.toString().toLowerCase() == 'true');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(boolValue ? Icons.check_circle : Icons.cancel, color: boolValue ? Colors.green : Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text('Boolean Value', style: theme.textTheme.bodyMedium)),
          Switch(
            value: boolValue,
            onChanged: widget.isReadOnly
                ? null
                : (value) {
                    widget.onChanged(widget.field.copyWith(value: value));
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildEnumField(ThemeData theme, bool compact) {
    final options = widget.field.enumOptions ?? [];
    final currentValue = widget.field.value?.toString() ?? '';

    return DropdownButtonFormField<String>(
      value: options.contains(currentValue) ? currentValue : null,
      items: options.map((option) {
        return DropdownMenuItem<String>(value: option, child: Text(option));
      }).toList(),
      onChanged: widget.isReadOnly
          ? null
          : (value) {
              if (value != null) {
                widget.onChanged(widget.field.copyWith(value: value));
              }
            },
      decoration: InputDecoration(
        hintText: 'Select an option',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildHtmlPreview(ThemeData theme) {
    final content = widget.field.value?.toString() ?? '';
    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.code, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              content.length > 50 ? '${content.substring(0, 50)}...' : content,
              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Courier', color: theme.colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlEditor(ThemeData theme) {
    return CodeEditorWidget(
      content: widget.field.value?.toString() ?? '',
      language: 'html',
      readOnly: widget.isReadOnly,
      height: 200,
      onChanged: widget.isReadOnly
          ? null
          : (value) {
              widget.onChanged(widget.field.copyWith(value: value));
            },
    );
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (widget.field.type) {
      case JsonFieldType.integer:
        return [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))];
      case JsonFieldType.double:
        return [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))];
      default:
        return [];
    }
  }

  String _getHintText() {
    switch (widget.field.type) {
      case JsonFieldType.string:
        return 'Enter string value';
      case JsonFieldType.integer:
        return 'Enter integer value';
      case JsonFieldType.double:
        return 'Enter decimal value';
      default:
        return 'Enter value';
    }
  }

  Color _getTypeColorForType(JsonFieldType type) {
    switch (type) {
      case JsonFieldType.string:
        return Colors.blue;
      case JsonFieldType.boolean:
        return Colors.green;
      case JsonFieldType.integer:
        return Colors.orange;
      case JsonFieldType.double:
        return Colors.purple;
      case JsonFieldType.enumValue:
        return Colors.teal;
      case JsonFieldType.html:
        return Colors.red;
    }
  }

  IconData _getTypeIconForType(JsonFieldType type) {
    switch (type) {
      case JsonFieldType.string:
        return Icons.text_fields;
      case JsonFieldType.boolean:
        return Icons.toggle_on;
      case JsonFieldType.integer:
        return Icons.numbers;
      case JsonFieldType.double:
        return Icons.pin;
      case JsonFieldType.enumValue:
        return Icons.list;
      case JsonFieldType.html:
        return Icons.code;
    }
  }
}
