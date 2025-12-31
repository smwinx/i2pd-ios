import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/i2pd_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<I2pdService>(
      builder: (context, service, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Network'),
          _buildSettingsCard([
            _SettingsTile(
              icon: Icons.language,
              title: 'IPv4',
              subtitle: 'Enable IPv4 connectivity',
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            _SettingsTile(
              icon: Icons.language,
              title: 'IPv6',
              subtitle: 'Enable IPv6 connectivity',
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            _SettingsTile(
              icon: Icons.router,
              title: 'UPnP',
              subtitle: 'Automatic port forwarding',
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Bandwidth'),
          _buildSettingsCard([
            _SettingsTile(
              icon: Icons.speed,
              title: 'Bandwidth Limit',
              subtitle: 'L (32 KB/s)',
              onTap: () => _showBandwidthPicker(context),
            ),
            _SettingsTile(
              icon: Icons.share,
              title: 'Share Bandwidth',
              subtitle: '100%',
              onTap: () => _showSharePicker(context),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Proxies'),
          _buildSettingsCard([
            _SettingsTile(
              icon: Icons.http,
              title: 'HTTP Proxy Port',
              subtitle: '${service.httpProxyPort}',
              onTap: () => _showPortPicker(context, 'HTTP Proxy', service.httpProxyPort),
            ),
            _SettingsTile(
              icon: Icons.security,
              title: 'SOCKS Proxy Port',
              subtitle: '${service.socksProxyPort}',
              onTap: () => _showPortPicker(context, 'SOCKS Proxy', service.socksProxyPort),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Services'),
          _buildSettingsCard([
            _SettingsTile(
              icon: Icons.api,
              title: 'SAM Bridge',
              subtitle: 'Port 7656',
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            _SettingsTile(
              icon: Icons.terminal,
              title: 'I2CP',
              subtitle: 'Port 7654',
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            _SettingsTile(
              icon: Icons.control_point,
              title: 'I2PControl',
              subtitle: 'Port 7650',
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Router'),
          _buildSettingsCard([
            _SettingsTile(
              icon: Icons.dns,
              title: 'Floodfill',
              subtitle: 'Participate as a floodfill router',
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            _SettingsTile(
              icon: Icons.block,
              title: 'No Transit',
              subtitle: 'Disable transit traffic',
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Data'),
          _buildSettingsCard([
            _SettingsTile(
              icon: Icons.folder,
              title: 'Data Directory',
              subtitle: service.dataPath.isEmpty 
                  ? 'Not initialized' 
                  : service.dataPath,
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.description,
              title: 'View Logs',
              subtitle: 'Router logs and debug info',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogsScreen()),
              ),
            ),
            _SettingsTile(
              icon: Icons.delete_outline,
              title: 'Clear Data',
              subtitle: 'Remove all router data',
              titleColor: AppTheme.accentRed,
              onTap: () => _showClearDataDialog(context),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildSettingsCard([
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: 'i2pd ${service.version}',
            ),
            _SettingsTile(
              icon: Icons.code,
              title: 'Source Code',
              subtitle: 'github.com/PurpleI2P/i2pd',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.article_outlined,
              title: 'Documentation',
              subtitle: 'i2pd.readthedocs.io',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryPurple,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  void _showBandwidthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bandwidth Limit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _BandwidthOption('L - Low (32 KB/s)', true),
            _BandwidthOption('O - Medium (256 KB/s)', false),
            _BandwidthOption('P - High (2048 KB/s)', false),
            _BandwidthOption('X - Unlimited', false),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSharePicker(BuildContext context) {
    // Similar implementation
  }

  void _showPortPicker(BuildContext context, String title, int currentPort) {
    final controller = TextEditingController(text: currentPort.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('$title Port'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Port',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Clear Data'),
        content: const Text(
          'This will remove all router data including keys and configuration. '
          'Your router identity will be lost. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryPurple),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? AppTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}

class _BandwidthOption extends StatelessWidget {
  final String label;
  final bool selected;

  const _BandwidthOption(this.label, this.selected);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected 
          ? const Icon(Icons.check, color: AppTheme.accentGreen)
          : null,
      onTap: () => Navigator.pop(context),
    );
  }
}

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 50,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '[${DateTime.now().toString().substring(11, 19)}] Log entry $index - Router status update',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
