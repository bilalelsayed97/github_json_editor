import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/github_config.dart';
import '../../injection/injection_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  GitHubConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final prefs = sl<SharedPreferences>();
    final configMap = <String, String>{
      'github_token': prefs.getString('github_token') ?? '',
      'github_username': prefs.getString('github_username') ?? '',
      'github_repo_name': prefs.getString('github_repo_name') ?? '',
      'github_branch': prefs.getString('github_branch') ?? 'main',
    };

    setState(() {
      _currentConfig = GitHubConfig.fromMap(configMap);
    });
  }

  Future<void> _saveConfiguration() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;

    setState(() => _isSaving = true);

    try {
      final formData = _formKey.currentState!.value;
      final config = GitHubConfig(
        token: formData['token'] ?? '',
        username: formData['username'] ?? '',
        repoName: formData['repoName'] ?? '',
        branch: formData['branch'] ?? 'main',
      );

      final prefs = sl<SharedPreferences>();
      final configMap = config.toMap();
      
      for (final entry in configMap.entries) {
        await prefs.setString(entry.key, entry.value);
      }

      setState(() {
        _currentConfig = config;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save configuration: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _testConnection() async {
    if (_currentConfig == null || !_currentConfig!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save your configuration first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Here you could add a test API call to verify the configuration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connection test feature coming soon! 🚀'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: _currentConfig?.isValid == true ? _testConnection : null,
            icon: const Icon(Icons.wifi_protected_setup),
            tooltip: 'Test Connection',
          ),
        ],
      ),
      body: _currentConfig == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildConfigurationCard(),
                    const SizedBox(height: 24),
                    _buildInstructionsCard(),
                    const SizedBox(height: 24),
                    _buildStatusCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GitHub Configuration',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure your GitHub repository settings to start editing JSON files.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Repository Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FormBuilderTextField(
              name: 'username',
              initialValue: _currentConfig!.username,
              decoration: InputDecoration(
                labelText: 'GitHub Username',
                hintText: 'your-username',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(1),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'repoName',
              initialValue: _currentConfig!.repoName,
              decoration: InputDecoration(
                labelText: 'Repository Name',
                hintText: 'my-awesome-repo',
                prefixIcon: const Icon(Icons.folder),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(1),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'branch',
              initialValue: _currentConfig!.branch,
              decoration: InputDecoration(
                labelText: 'Branch Name',
                hintText: 'main',
                prefixIcon: const Icon(Icons.account_tree),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(1),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'token',
              initialValue: _currentConfig!.token,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Personal Access Token',
                hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _showTokenHelpDialog(),
                ),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(20),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveConfiguration,
                icon: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Configuration'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'How to get a GitHub Token',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '1. Go to GitHub.com → Settings → Developer settings\n'
              '2. Click "Personal access tokens" → "Tokens (classic)"\n'
              '3. Click "Generate new token (classic)"\n'
              '4. Select "repo" scope for full repository access\n'
              '5. Copy the generated token and paste it above',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isConfigured = _currentConfig?.isValid ?? false;
    
    return Card(
      elevation: 0,
      color: isConfigured 
          ? Theme.of(context).colorScheme.tertiaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              isConfigured ? Icons.check_circle : Icons.warning,
              color: isConfigured 
                  ? Theme.of(context).colorScheme.onTertiaryContainer
                  : Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConfigured ? 'Ready to go!' : 'Configuration incomplete',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isConfigured 
                          ? Theme.of(context).colorScheme.onTertiaryContainer
                          : Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  Text(
                    isConfigured 
                        ? 'Your GitHub configuration is complete. You can now browse and edit JSON files.'
                        : 'Please fill in all required fields to start using the app.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isConfigured 
                          ? Theme.of(context).colorScheme.onTertiaryContainer
                          : Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTokenHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub Token Permissions'),
        content: const Text(
          'Your token needs the following permissions:\n\n'
          '• repo - Full control of private repositories\n'
          '• public_repo - Access public repositories\n'
          '• repo:status - Access commit status\n\n'
          'This allows the app to read and modify files in your repository.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}