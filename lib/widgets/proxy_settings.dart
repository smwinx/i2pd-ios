import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProxySettings extends StatelessWidget {
  final bool httpEnabled;
  final bool socksEnabled;
  final int httpPort;
  final int socksPort;
  final ValueChanged<bool> onHttpToggle;
  final ValueChanged<bool> onSocksToggle;

  const ProxySettings({
    super.key,
    required this.httpEnabled,
    required this.socksEnabled,
    required this.httpPort,
    required this.socksPort,
    required this.onHttpToggle,
    required this.onSocksToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Proxy Services',
            style: TextStyle(
              color: AppTheme.primaryPurple,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              _ProxyTile(
                title: 'HTTP Proxy',
                subtitle: '127.0.0.1:$httpPort',
                icon: Icons.http,
                enabled: httpEnabled,
                onToggle: onHttpToggle,
              ),
              const Divider(height: 1),
              _ProxyTile(
                title: 'SOCKS Proxy',
                subtitle: '127.0.0.1:$socksPort',
                icon: Icons.security,
                enabled: socksEnabled,
                onToggle: onSocksToggle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, 
                        color: AppTheme.primaryPurple, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'How to Use',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Configure your browser or app to use these proxy settings to browse .i2p sites:',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProxyInfo('HTTP Proxy', '127.0.0.1', httpPort),
                const SizedBox(height: 8),
                _buildProxyInfo('SOCKS5 Proxy', '127.0.0.1', socksPort),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProxyInfo(String type, String host, int port) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$host:$port',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              // Copy to clipboard
            },
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ProxyTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _ProxyTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled 
              ? AppTheme.accentGreen.withOpacity(0.2)
              : AppTheme.textSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? AppTheme.accentGreen : AppTheme.textSecondary,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'monospace',
          color: enabled ? AppTheme.accentGreen : AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: enabled,
        onChanged: onToggle,
      ),
    );
  }
}
