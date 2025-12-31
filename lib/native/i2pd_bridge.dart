import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Bridge class to communicate with native i2pd implementation via method channels
class I2pdBridge {
  static const MethodChannel _channel = MethodChannel('com.purplei2p.i2pd/native');
  
  bool _initialized = false;
  bool _running = false;
  String _dataPath = '';
  DateTime? _startTime;
  
  // Status polling
  Timer? _statusTimer;
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  
  bool get isInitialized => _initialized;
  bool get isRunning => _running;
  String get dataPath => _dataPath;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _dataPath = await _channel.invokeMethod<String>('getDataPath') ?? '';
      final result = await _channel.invokeMethod<bool>('initialize') ?? false;
      _initialized = result;
      debugPrint('I2pdBridge: Initialized with data path: $_dataPath');
    } catch (e) {
      debugPrint('I2pdBridge: Initialize error: $e');
      _initialized = false;
    }
  }
  
  Future<bool> startDaemon() async {
    if (!_initialized) {
      await initialize();
    }
    
    if (_running) return true;
    
    try {
      final result = await _channel.invokeMethod<bool>('start') ?? false;
      _running = result;
      if (_running) {
        _startTime = DateTime.now();
        _startStatusPolling();
      }
      debugPrint('I2pdBridge: Start daemon result: $result');
      return result;
    } catch (e) {
      debugPrint('I2pdBridge: Start error: $e');
      return false;
    }
  }
  
  Future<void> stopDaemon() async {
    if (!_running) return;
    
    try {
      await _channel.invokeMethod('stop');
      _running = false;
      _startTime = null;
      _stopStatusPolling();
      debugPrint('I2pdBridge: Daemon stopped');
    } catch (e) {
      debugPrint('I2pdBridge: Stop error: $e');
    }
  }
  
  Future<void> gracefulShutdown() async {
    try {
      await _channel.invokeMethod('gracefulShutdown');
      _running = false;
      _startTime = null;
      _stopStatusPolling();
    } catch (e) {
      debugPrint('I2pdBridge: Graceful shutdown error: $e');
      // Fallback to regular stop
      await stopDaemon();
    }
  }
  
  Future<Map<String, dynamic>> getRouterInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getRouterInfo');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      debugPrint('I2pdBridge: Get router info error: $e');
    }
    
    // Return placeholder data
    return {
      'status': _running ? 'running' : 'stopped',
      'version': '2.50.0',
      'uptime': _startTime != null 
          ? DateTime.now().difference(_startTime!).inSeconds 
          : 0,
      'networkStatus': _running ? 'connected' : 'disconnected',
    };
  }
  
  Future<void> configureHttpProxy({required bool enabled, required int port}) async {
    try {
      await _channel.invokeMethod('configureHttpProxy', {
        'enabled': enabled,
        'port': port,
      });
    } catch (e) {
      debugPrint('I2pdBridge: Configure HTTP proxy error: $e');
    }
  }
  
  Future<void> configureSocksProxy({required bool enabled, required int port}) async {
    try {
      await _channel.invokeMethod('configureSocksProxy', {
        'enabled': enabled,
        'port': port,
      });
    } catch (e) {
      debugPrint('I2pdBridge: Configure SOCKS proxy error: $e');
    }
  }
  
  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final info = await getRouterInfo();
      _statusController.add(info);
    });
  }
  
  void _stopStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }
  
  Future<String> getDataPath() async {
    if (_dataPath.isNotEmpty) return _dataPath;
    
    try {
      _dataPath = await _channel.invokeMethod<String>('getDataPath') ?? '';
    } catch (e) {
      debugPrint('I2pdBridge: Get data path error: $e');
    }
    
    return _dataPath;
  }
  
  void dispose() {
    _stopStatusPolling();
    _statusController.close();
    if (_running) {
      stopDaemon();
    }
  }
}
