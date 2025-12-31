import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TunnelList extends StatelessWidget {
  const TunnelList({super.key});

  @override
  Widget build(BuildContext context) {
    final tunnels = [
      TunnelConfig(
        name: 'I2P HTTP Proxy',
        type: TunnelType.httpProxy,
        destination: '',
        port: 4444,
        enabled: true,
        isBuiltIn: true,
      ),
      TunnelConfig(
        name: 'I2P SOCKS Proxy',
        type: TunnelType.socksProxy,
        destination: '',
        port: 4447,
        enabled: true,
        isBuiltIn: true,
      ),
      TunnelConfig(
        name: 'SAM Bridge',
        type: TunnelType.sam,
        destination: '',
        port: 7656,
        enabled: true,
        isBuiltIn: true,
      ),
      TunnelConfig(
        name: 'IRC Server',
        type: TunnelType.server,
        destination: 'irc.ilita.i2p',
        port: 6668,
        enabled: false,
        isBuiltIn: false,
      ),
      TunnelConfig(
        name: 'Web Server',
        type: TunnelType.server,
        destination: '',
        port: 8080,
        enabled: false,
        isBuiltIn: false,
      ),
    ];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Client Tunnels', tunnels.where((t) => t.isClient).toList()),
          const SizedBox(height: 24),
          _buildSection('Server Tunnels', tunnels.where((t) => !t.isClient).toList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTunnelDialog(context),
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSection(String title, List<TunnelConfig> tunnels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryPurple,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(
            children: tunnels.asMap().entries.map((entry) {
              final index = entry.key;
              final tunnel = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 1),
                  _TunnelTile(tunnel: tunnel),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAddTunnelDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _AddTunnelSheet(),
    );
  }
}

class _TunnelTile extends StatelessWidget {
  final TunnelConfig tunnel;

  const _TunnelTile({required this.tunnel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tunnel.enabled
              ? AppTheme.accentGreen.withOpacity(0.2)
              : AppTheme.textSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getTypeIcon(tunnel.type),
          color: tunnel.enabled ? AppTheme.accentGreen : AppTheme.textSecondary,
        ),
      ),
      title: Text(tunnel.name),
      subtitle: Text(
        tunnel.destination.isNotEmpty
            ? tunnel.destination
            : '127.0.0.1:${tunnel.port}',
        style: const TextStyle(
          fontFamily: 'monospace',
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!tunnel.isBuiltIn)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {},
              color: AppTheme.textSecondary,
            ),
          Switch(
            value: tunnel.enabled,
            onChanged: tunnel.isBuiltIn ? null : (value) {},
          ),
        ],
      ),
      onTap: tunnel.isBuiltIn ? null : () => _showTunnelDetails(context),
    );
  }

  IconData _getTypeIcon(TunnelType type) {
    switch (type) {
      case TunnelType.httpProxy:
        return Icons.http;
      case TunnelType.socksProxy:
        return Icons.security;
      case TunnelType.client:
        return Icons.arrow_forward;
      case TunnelType.server:
        return Icons.arrow_back;
      case TunnelType.sam:
        return Icons.api;
      case TunnelType.i2cp:
        return Icons.terminal;
    }
  }

  void _showTunnelDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TunnelDetailsSheet(tunnel: tunnel),
    );
  }
}

class _AddTunnelSheet extends StatefulWidget {
  const _AddTunnelSheet();

  @override
  State<_AddTunnelSheet> createState() => _AddTunnelSheetState();
}

class _AddTunnelSheetState extends State<_AddTunnelSheet> {
  TunnelType _selectedType = TunnelType.client;
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _portController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Tunnel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TunnelType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: [
              TunnelType.client,
              TunnelType.server,
            ].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type == TunnelType.client ? 'Client' : 'Server'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              hintText: 'My Tunnel',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _destinationController,
            decoration: InputDecoration(
              labelText: _selectedType == TunnelType.client 
                  ? 'Destination (b32 address)' 
                  : 'Keys File',
              border: const OutlineInputBorder(),
              hintText: _selectedType == TunnelType.client
                  ? 'example.b32.i2p'
                  : 'myserver-keys.dat',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _portController,
            decoration: InputDecoration(
              labelText: _selectedType == TunnelType.client 
                  ? 'Local Port' 
                  : 'Service Port',
              border: const OutlineInputBorder(),
              hintText: '8080',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Save tunnel
                Navigator.pop(context);
              },
              child: const Text('Add Tunnel'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _portController.dispose();
    super.dispose();
  }
}

class _TunnelDetailsSheet extends StatelessWidget {
  final TunnelConfig tunnel;

  const _TunnelDetailsSheet({required this.tunnel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tunnel.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Type', tunnel.type.name.toUpperCase()),
          _buildDetailRow('Port', tunnel.port.toString()),
          if (tunnel.destination.isNotEmpty)
            _buildDetailRow('Destination', tunnel.destination),
          _buildDetailRow('Status', tunnel.enabled ? 'Enabled' : 'Disabled'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentRed,
                    side: const BorderSide(color: AppTheme.accentRed),
                  ),
                  child: const Text('Delete'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

enum TunnelType {
  httpProxy,
  socksProxy,
  client,
  server,
  sam,
  i2cp,
}

class TunnelConfig {
  final String name;
  final TunnelType type;
  final String destination;
  final int port;
  final bool enabled;
  final bool isBuiltIn;

  TunnelConfig({
    required this.name,
    required this.type,
    required this.destination,
    required this.port,
    required this.enabled,
    required this.isBuiltIn,
  });

  bool get isClient => type == TunnelType.client ||
      type == TunnelType.httpProxy ||
      type == TunnelType.socksProxy ||
      type == TunnelType.sam ||
      type == TunnelType.i2cp;
}
