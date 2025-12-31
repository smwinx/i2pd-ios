import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsGrid extends StatelessWidget {
  final int knownRouters;
  final int activeTunnels;
  final int participatingTunnels;
  final int sentBytes;
  final int receivedBytes;
  final double bandwidth;

  const StatsGrid({
    super.key,
    required this.knownRouters,
    required this.activeTunnels,
    required this.participatingTunnels,
    required this.sentBytes,
    required this.receivedBytes,
    required this.bandwidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Statistics',
            style: TextStyle(
              color: AppTheme.primaryPurple,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.2,
          children: [
            _StatTile(
              label: 'Routers',
              value: _formatNumber(knownRouters),
              icon: Icons.router,
              color: AppTheme.primaryPurple,
            ),
            _StatTile(
              label: 'Client Tunnels',
              value: activeTunnels.toString(),
              icon: Icons.route,
              color: AppTheme.accentGreen,
            ),
            _StatTile(
              label: 'Transit Tunnels',
              value: participatingTunnels.toString(),
              icon: Icons.swap_horiz,
              color: AppTheme.accentOrange,
            ),
            _StatTile(
              label: 'Sent',
              value: _formatBytes(sentBytes),
              icon: Icons.upload,
              color: Colors.blue,
            ),
            _StatTile(
              label: 'Received',
              value: _formatBytes(receivedBytes),
              icon: Icons.download,
              color: Colors.cyan,
            ),
            _StatTile(
              label: 'Bandwidth',
              value: '${bandwidth.toStringAsFixed(1)} KB/s',
              icon: Icons.speed,
              color: Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
