import 'package:flutter/material.dart';
import '../services/config_manager.dart';

/// Screen for editing raw i2pd.conf file
class ConfigEditorScreen extends StatefulWidget {
  const ConfigEditorScreen({super.key});

  @override
  State<ConfigEditorScreen> createState() => _ConfigEditorScreenState();
}

class _ConfigEditorScreenState extends State<ConfigEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _configManager = ConfigManager();
  
  final _mainConfigController = TextEditingController();
  final _tunnelsConfigController = TextEditingController();
  
  bool _loading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfigs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mainConfigController.dispose();
    _tunnelsConfigController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    setState(() => _loading = true);
    
    final mainConfig = await _configManager.readConfig();
    final tunnelsConfig = await _configManager.readTunnelsConfig();
    
    _mainConfigController.text = mainConfig;
    _tunnelsConfigController.text = tunnelsConfig;
    
    setState(() {
      _loading = false;
      _hasChanges = false;
    });
  }

  Future<void> _saveConfigs() async {
    await _configManager.writeConfig(_mainConfigController.text);
    await _configManager.writeTunnelsConfig(_tunnelsConfigController.text);
    
    setState(() => _hasChanges = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration saved. Restart router to apply changes.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Configuration'),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _saveConfigs,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfigs,
            tooltip: 'Reload',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'i2pd.conf'),
            Tab(text: 'tunnels.conf'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEditor(_mainConfigController),
                _buildEditor(_tunnelsConfigController),
              ],
            ),
    );
  }

  Widget _buildEditor(TextEditingController controller) {
    return Container(
      color: Colors.grey[900],
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Colors.white,
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
        ),
        onChanged: (_) {
          if (!_hasChanges) {
            setState(() => _hasChanges = true);
          }
        },
      ),
    );
  }
}
