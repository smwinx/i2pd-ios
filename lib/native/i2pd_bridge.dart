import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// FFI type definitions for i2pd C API
typedef I2pdInitNative = Int32 Function(Pointer<Utf8> dataDir);
typedef I2pdInit = int Function(Pointer<Utf8> dataDir);

typedef I2pdStartNative = Int32 Function();
typedef I2pdStart = int Function();

typedef I2pdStopNative = Void Function();
typedef I2pdStop = void Function();

typedef I2pdGetStatusNative = Int32 Function();
typedef I2pdGetStatus = int Function();

typedef I2pdGetRouterInfoNative = Pointer<Utf8> Function();
typedef I2pdGetRouterInfo = Pointer<Utf8> Function();

class I2pdBridge {
  DynamicLibrary? _lib;
  bool _initialized = false;
  String _dataPath = '';
  
  // Function pointers
  I2pdInit? _init;
  I2pdStart? _start;
  I2pdStop? _stop;
  I2pdGetStatus? _getStatus;
  I2pdGetRouterInfo? _getRouterInfo;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _dataPath = await getDataPath();
      
      // Load the native library
      if (Platform.isIOS) {
        _lib = DynamicLibrary.process();
      } else if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libi2pd.so');
      } else {
        throw UnsupportedError('Platform not supported');
      }
      
      // Bind functions
      _init = _lib!.lookupFunction<I2pdInitNative, I2pdInit>('i2pd_init');
      _start = _lib!.lookupFunction<I2pdStartNative, I2pdStart>('i2pd_start');
      _stop = _lib!.lookupFunction<I2pdStopNative, I2pdStop>('i2pd_stop');
      _getStatus = _lib!.lookupFunction<I2pdGetStatusNative, I2pdGetStatus>('i2pd_get_status');
      
      // Initialize i2pd with data directory
      final dataDir = _dataPath.toNativeUtf8();
      final result = _init!(dataDir);
      calloc.free(dataDir);
      
      if (result != 0) {
        throw Exception('Failed to initialize i2pd: error code $result');
      }
      
      _initialized = true;
      debugPrint('i2pd initialized successfully at $_dataPath');
    } catch (e) {
      debugPrint('Failed to initialize i2pd bridge: $e');
      rethrow;
    }
  }

  Future<String> getDataPath() async {
    if (_dataPath.isNotEmpty) return _dataPath;
    
    final appDir = await getApplicationDocumentsDirectory();
    _dataPath = '${appDir.path}/i2pd';
    
    // Create directory if it doesn't exist
    final dir = Directory(_dataPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    // Create subdirectories
    await Directory('$_dataPath/certificates').create(recursive: true);
    await Directory('$_dataPath/tunnels.d').create(recursive: true);
    await Directory('$_dataPath/addressbook').create(recursive: true);
    
    return _dataPath;
  }

  Future<bool> startDaemon() async {
    if (!_initialized) {
      await initialize();
    }
    
    try {
      final result = _start!();
      return result == 0;
    } catch (e) {
      debugPrint('Failed to start daemon: $e');
      return false;
    }
  }

  Future<void> stopDaemon() async {
    if (!_initialized || _stop == null) return;
    
    try {
      _stop!();
    } catch (e) {
      debugPrint('Failed to stop daemon: $e');
    }
  }

  Future<Map<String, dynamic>> getRouterInfo() async {
    // Return mock data if not running natively
    // Real implementation will use FFI to get actual stats
    return {
      'uptime': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'status': 'ok',
      'knownRouters': 2500,
      'activeTunnels': 12,
      'participatingTunnels': 8,
      'sentBytes': 1024000,
      'receivedBytes': 2048000,
      'bandwidth': 50.5,
    };
  }

  void configureHttpProxy(bool enabled, int port) {
    // Will be implemented via FFI
    debugPrint('HTTP Proxy: $enabled, port: $port');
  }

  void configureSocksProxy(bool enabled, int port) {
    // Will be implemented via FFI
    debugPrint('SOCKS Proxy: $enabled, port: $port');
  }

  Future<void> gracefulShutdown() async {
    // Graceful shutdown waits for tunnels to expire
    await stopDaemon();
  }

  void dispose() {
    if (_initialized) {
      stopDaemon();
    }
  }
}
