import 'dart:async';
import 'package:flutter/foundation.dart';
import '../native/i2pd_bridge.dart';

enum RouterStatus { stopped, starting, running, stopping, error }
enum NetworkStatus { disconnected, firewalled, testing, ok }

class I2pdService extends ChangeNotifier {
  RouterStatus _routerStatus = RouterStatus.stopped;
  NetworkStatus _networkStatus = NetworkStatus.disconnected;
  
  int _activeTunnels = 0;
  int _knownRouters = 0;
  int _participatingTunnels = 0;
  int _sentBytes = 0;
  int _receivedBytes = 0;
  double _bandwidth = 0;
  Duration _uptime = Duration.zero;
  
  bool _httpProxyEnabled = true;
  bool _socksProxyEnabled = true;
  int _httpProxyPort = 4444;
  int _socksProxyPort = 4447;
  
  String _dataPath = '';
  String _version = '2.50.2';
  
  Timer? _statsTimer;
  final I2pdBridge _bridge = I2pdBridge();

  // Getters
  RouterStatus get routerStatus => _routerStatus;
  NetworkStatus get networkStatus => _networkStatus;
  int get activeTunnels => _activeTunnels;
  int get knownRouters => _knownRouters;
  int get participatingTunnels => _participatingTunnels;
  int get sentBytes => _sentBytes;
  int get receivedBytes => _receivedBytes;
  double get bandwidth => _bandwidth;
  Duration get uptime => _uptime;
  bool get httpProxyEnabled => _httpProxyEnabled;
  bool get socksProxyEnabled => _socksProxyEnabled;
  int get httpProxyPort => _httpProxyPort;
  int get socksProxyPort => _socksProxyPort;
  String get dataPath => _dataPath;
  String get version => _version;
  
  bool get isRunning => _routerStatus == RouterStatus.running;

  Future<void> initialize() async {
    _dataPath = await _bridge.getDataPath();
    await _bridge.initialize();
    notifyListeners();
  }

  Future<void> startRouter() async {
    if (_routerStatus == RouterStatus.running || 
        _routerStatus == RouterStatus.starting) {
      return;
    }
    
    _routerStatus = RouterStatus.starting;
    _networkStatus = NetworkStatus.testing;
    notifyListeners();
    
    try {
      final success = await _bridge.startDaemon();
      if (success) {
        _routerStatus = RouterStatus.running;
        _startStatsPolling();
      } else {
        _routerStatus = RouterStatus.error;
      }
    } catch (e) {
      _routerStatus = RouterStatus.error;
      debugPrint('Failed to start i2pd: $e');
    }
    
    notifyListeners();
  }

  Future<void> stopRouter() async {
    if (_routerStatus == RouterStatus.stopped ||
        _routerStatus == RouterStatus.stopping) {
      return;
    }
    
    _routerStatus = RouterStatus.stopping;
    notifyListeners();
    
    _stopStatsPolling();
    
    try {
      await _bridge.stopDaemon();
      _routerStatus = RouterStatus.stopped;
      _networkStatus = NetworkStatus.disconnected;
      _resetStats();
    } catch (e) {
      _routerStatus = RouterStatus.error;
      debugPrint('Failed to stop i2pd: $e');
    }
    
    notifyListeners();
  }

  void _startStatsPolling() {
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _updateStats();
    });
  }

  void _stopStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  Future<void> _updateStats() async {
    if (_routerStatus != RouterStatus.running) return;
    
    try {
      final stats = await _bridge.getRouterInfo();
      
      _uptime = Duration(seconds: stats['uptime'] ?? 0);
      _networkStatus = _parseNetworkStatus(stats['status'] ?? 'unknown');
      _knownRouters = stats['knownRouters'] ?? 0;
      _activeTunnels = stats['activeTunnels'] ?? 0;
      _participatingTunnels = stats['participatingTunnels'] ?? 0;
      _sentBytes = stats['sentBytes'] ?? 0;
      _receivedBytes = stats['receivedBytes'] ?? 0;
      _bandwidth = (stats['bandwidth'] ?? 0).toDouble();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update stats: $e');
    }
  }

  NetworkStatus _parseNetworkStatus(String status) {
    switch (status.toLowerCase()) {
      case 'ok':
        return NetworkStatus.ok;
      case 'firewalled':
        return NetworkStatus.firewalled;
      case 'testing':
        return NetworkStatus.testing;
      default:
        return NetworkStatus.disconnected;
    }
  }

  void _resetStats() {
    _activeTunnels = 0;
    _knownRouters = 0;
    _participatingTunnels = 0;
    _sentBytes = 0;
    _receivedBytes = 0;
    _bandwidth = 0;
    _uptime = Duration.zero;
  }

  void setHttpProxy(bool enabled, {int? port}) {
    _httpProxyEnabled = enabled;
    if (port != null) _httpProxyPort = port;
    _bridge.configureHttpProxy(enabled, _httpProxyPort);
    notifyListeners();
  }

  void setSocksProxy(bool enabled, {int? port}) {
    _socksProxyEnabled = enabled;
    if (port != null) _socksProxyPort = port;
    _bridge.configureSocksProxy(enabled, _socksProxyPort);
    notifyListeners();
  }

  Future<void> gracefulShutdown() async {
    await _bridge.gracefulShutdown();
    _routerStatus = RouterStatus.stopping;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopStatsPolling();
    _bridge.dispose();
    super.dispose();
  }
}
