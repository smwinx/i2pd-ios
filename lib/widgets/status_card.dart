import 'package:flutter/material.dart';
import '../services/i2pd_service.dart';
import '../theme/app_theme.dart';

class StatusCard extends StatelessWidget {
  final RouterStatus routerStatus;
  final NetworkStatus networkStatus;
  final Duration uptime;
  final String version;
  final VoidCallback onToggle;

  const StatusCard({
    super.key,
    required this.routerStatus,
    required this.networkStatus,
    required this.uptime,
    required this.version,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Network: ${_getNetworkStatusText()}',
                        style: TextStyle(
                          color: _getNetworkStatusColor(),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildToggleButton(),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  'Uptime',
                  _formatUptime(uptime),
                  Icons.timer_outlined,
                ),
                _buildInfoItem(
                  'Version',
                  version,
                  Icons.info_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    IconData icon;

    switch (routerStatus) {
      case RouterStatus.running:
        color = AppTheme.accentGreen;
        icon = Icons.check_circle;
        break;
      case RouterStatus.starting:
        color = AppTheme.accentOrange;
        icon = Icons.pending;
        break;
      case RouterStatus.stopping:
        color = AppTheme.accentOrange;
        icon = Icons.pending;
        break;
      case RouterStatus.error:
        color = AppTheme.accentRed;
        icon = Icons.error;
        break;
      default:
        color = AppTheme.textSecondary;
        icon = Icons.stop_circle;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  Widget _buildToggleButton() {
    final isRunning = routerStatus == RouterStatus.running;
    final isLoading = routerStatus == RouterStatus.starting ||
        routerStatus == RouterStatus.stopping;

    return SizedBox(
      width: 80,
      height: 40,
      child: ElevatedButton(
        onPressed: isLoading ? null : onToggle,
        style: ElevatedButton.styleFrom(
          backgroundColor: isRunning ? AppTheme.accentRed : AppTheme.accentGreen,
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(isRunning ? 'Stop' : 'Start'),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    switch (routerStatus) {
      case RouterStatus.running:
        return 'Router Running';
      case RouterStatus.starting:
        return 'Starting...';
      case RouterStatus.stopping:
        return 'Stopping...';
      case RouterStatus.error:
        return 'Error';
      default:
        return 'Router Stopped';
    }
  }

  String _getNetworkStatusText() {
    switch (networkStatus) {
      case NetworkStatus.ok:
        return 'OK';
      case NetworkStatus.firewalled:
        return 'Firewalled';
      case NetworkStatus.testing:
        return 'Testing...';
      default:
        return 'Disconnected';
    }
  }

  Color _getNetworkStatusColor() {
    switch (networkStatus) {
      case NetworkStatus.ok:
        return AppTheme.accentGreen;
      case NetworkStatus.firewalled:
        return AppTheme.accentOrange;
      case NetworkStatus.testing:
        return AppTheme.accentOrange;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatUptime(Duration duration) {
    if (duration.inSeconds == 0) return '0:00:00';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
