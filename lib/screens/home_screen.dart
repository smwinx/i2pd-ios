import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/i2pd_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_card.dart';
import '../widgets/stats_grid.dart';
import '../widgets/proxy_settings.dart';
import '../widgets/tunnel_list.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';
import 'addressbook_screen.dart';
import 'config_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<I2pdService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'i2p',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('i2pd'),
          ],
        ),
        actions: [
          Consumer<I2pdService>(
            builder: (context, service, _) => IconButton(
              icon: Icon(
                service.isRunning ? Icons.stop : Icons.play_arrow,
                color: service.isRunning 
                    ? AppTheme.accentRed 
                    : AppTheme.accentGreen,
              ),
              onPressed: () {
                if (service.isRunning) {
                  service.stopRouter();
                } else {
                  service.startRouter();
                }
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          _TunnelsTab(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppTheme.cardBackground,
        indicatorColor: AppTheme.primaryPurple.withOpacity(0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Tunnels',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<I2pdService>(
      builder: (context, service, _) => RefreshIndicator(
        onRefresh: () async {
          // Trigger stats refresh
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StatusCard(
              routerStatus: service.routerStatus,
              networkStatus: service.networkStatus,
              uptime: service.uptime,
              version: service.version,
              onToggle: () {
                if (service.isRunning) {
                  service.stopRouter();
                } else {
                  service.startRouter();
                }
              },
            ),
            const SizedBox(height: 16),
            StatsGrid(
              knownRouters: service.knownRouters,
              activeTunnels: service.activeTunnels,
              participatingTunnels: service.participatingTunnels,
              sentBytes: service.sentBytes,
              receivedBytes: service.receivedBytes,
              bandwidth: service.bandwidth,
            ),
            const SizedBox(height: 16),
            ProxySettings(
              httpEnabled: service.httpProxyEnabled,
              socksEnabled: service.socksProxyEnabled,
              httpPort: service.httpProxyPort,
              socksPort: service.socksProxyPort,
              onHttpToggle: (enabled) => service.setHttpProxy(enabled),
              onSocksToggle: (enabled) => service.setSocksProxy(enabled),
            ),
          ],
        ),
      ),
    );
  }
}

class _TunnelsTab extends StatelessWidget {
  const _TunnelsTab();

  @override
  Widget build(BuildContext context) {
    return const TunnelList();
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
