import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/github_config.dart';
import '../../domain/entities/json_document.dart';
import '../../domain/entities/json_field.dart';
import '../../domain/entities/json_field_type.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../injection/injection_container.dart';
import '../widgets/modern_json_field_widget.dart';
import '../widgets/code_editor_widget.dart';

class JsonEditorPage extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String sha;

  const JsonEditorPage({super.key, required this.filePath, required this.fileName, required this.sha});

  @override
  State<JsonEditorPage> createState() => _JsonEditorPageState();
}

class _JsonEditorPageState extends State<JsonEditorPage> {
  JsonDocument? _document;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<GitHubConfig> _getGitHubConfig() async {
    final prefs = sl<SharedPreferences>();
    return GitHubConfig.fromMap({
      'github_token': prefs.getString('github_token') ?? '',
      'github_username': prefs.getString('github_username') ?? '',
      'github_repo_name': prefs.getString('github_repo_name') ?? '',
      'github_branch': prefs.getString('github_branch') ?? 'main',
    });
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final config = await _getGitHubConfig();
      if (!config.isValid) {
        throw Exception('GitHub configuration is incomplete. Please check settings.');
      }

      final dataSource = sl<GithubRemoteDataSource>();
      final response = await dataSource.getFileContent(widget.filePath, config);

      final document = JsonDocument.fromJsonString(response['content'], widget.filePath, widget.fileName, response['sha']);

      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_document == null) return;

    setState(() => _isSaving = true);

    try {
      final config = await _getGitHubConfig();
      final dataSource = sl<GithubRemoteDataSource>();

      final jsonString = _document!.toJsonString();
      await dataSource.updateFileContent(widget.filePath, jsonString, _document!.sha, config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('File saved successfully! 🎉'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _updateField(int index, JsonField newField) {
    if (_document == null) return;

    setState(() {
      _document = _document!.updateField(index, newField);
    });
  }

  void _updateFieldType(int index, JsonFieldType newType) {
    if (_document == null) return;

    final field = _document!.fields[index];
    final newField = JsonField(
      key: field.key,
      value: _convertValueToType(field.value, newType),
      type: newType,
      enumOptions: newType == JsonFieldType.enumValue ? ['option1', 'option2', 'option3'] : null,
      isRequired: field.isRequired,
    );

    setState(() {
      _document = _document!.updateField(index, newField);
    });
  }

  dynamic _convertValueToType(dynamic value, JsonFieldType newType) {
    final stringValue = value?.toString() ?? '';

    switch (newType) {
      case JsonFieldType.string:
        return stringValue;
      case JsonFieldType.boolean:
        return stringValue.toLowerCase() == 'true';
      case JsonFieldType.integer:
        return int.tryParse(stringValue) ?? 0;
      case JsonFieldType.double:
        return double.tryParse(stringValue) ?? 0.0;
      case JsonFieldType.enumValue:
        return stringValue.isNotEmpty ? stringValue : 'option1';
      case JsonFieldType.html:
        return stringValue;
    }
  }

  void _addField() {
    if (_document == null) return;

    _showAddFieldDialog();
  }

  void _showAddFieldDialog() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    JsonFieldType selectedType = JsonFieldType.string;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(labelText: 'Field Key', hintText: 'e.g., user.name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<JsonFieldType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Field Type', border: OutlineInputBorder()),
                items: JsonFieldType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.displayName));
                }).toList(),
                onChanged: (type) {
                  if (type != null) {
                    setDialogState(() => selectedType = type);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'Initial Value',
                  hintText: 'Enter ${selectedType.displayName.toLowerCase()} value',
                  border: const OutlineInputBorder(),
                ),
                maxLines: selectedType == JsonFieldType.html ? 3 : 1,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (keyController.text.isNotEmpty) {
                  final newField = JsonField(key: keyController.text, value: valueController.text, type: selectedType);

                  setState(() {
                    _document = _document!.addField(newField);
                  });

                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeField(int index) {
    if (_document == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Field'),
        content: Text('Are you sure you want to remove "${_document!.fields[index].key}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _document = _document!.removeField(index);
              });
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.fileName, style: TextStyle(fontSize: 18)),
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          if (_document != null) ...[
            IconButton(icon: const Icon(Icons.add), onPressed: _addField, tooltip: 'Add Field'),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _isSaving || !_document!.hasChanges ? null : _saveDocument,
              icon: _isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              style: FilledButton.styleFrom(backgroundColor: _document!.hasChanges ? null : colorScheme.outline),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading JSON file...')],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load file', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(onPressed: _loadDocument, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_document == null) {
      return const Center(child: Text('No document loaded'));
    }

    return PageView(controller: _pageController, onPageChanged: (index) {}, children: [_buildEditorView(), _buildPreviewView()]);
  }

  Widget _buildEditorView() {
    if (_document!.fields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No fields found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'This JSON file doesn\'t contain any editable fields.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _addField, icon: const Icon(Icons.add), label: const Text('Add First Field')),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with file info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(Icons.description, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fileName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_document!.fields.length} fields • ${_document!.hasChanges ? 'Modified' : 'Unmodified'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              if (_document!.hasChanges)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Modified',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer),
                  ),
                ),
            ],
          ),
        ),
        // Fields list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _document!.fields.length,
            itemBuilder: (context, index) {
              final field = _document!.fields[index];

              return ModernJsonFieldWidget(
                field: field,
                onChanged: (newField) => _updateField(index, newField),
                onTypeChanged: (newType) => _updateFieldType(index, newType),
                onDelete: () => _removeField(index),
                isReadOnly: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewView() {
    return Column(
      children: [
        // Preview header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Row(
            children: [
              Icon(Icons.preview, color: Theme.of(context).colorScheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Text(
                'JSON Preview',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                _document!.hasChanges ? 'With Changes' : 'Original',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer),
              ),
            ],
          ),
        ),
        // JSON content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CodeEditorWidget(content: _document!.toJsonString(), language: 'json', readOnly: true, height: double.infinity),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
