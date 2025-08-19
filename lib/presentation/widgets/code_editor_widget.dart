import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/xml.dart';

class CodeEditorWidget extends StatefulWidget {
  final String content;
  final String language;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final double height;

  const CodeEditorWidget({
    super.key,
    required this.content,
    this.language = 'json',
    this.onChanged,
    this.readOnly = false,
    this.height = 300,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.content,
      language: widget.language == 'html' ? xml : json,
    );
    
    if (widget.onChanged != null) {
      _controller.addListener(() {
        widget.onChanged!(_controller.text);
      });
    }
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CodeField(
        controller: _controller,
        enabled: !widget.readOnly,
        textStyle: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 14,
        ),
        background: colorScheme.surface,
        cursorColor: colorScheme.primary,
        padding: const EdgeInsets.all(8),
        lineNumberStyle: LineNumberStyle(
          background: colorScheme.surfaceContainer,
          textStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}