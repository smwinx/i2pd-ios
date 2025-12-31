import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Manages i2pd configuration files and data directory
class ConfigManager {
  static const String _configFileName = 'i2pd.conf';
  static const String _tunnelsFileName = 'tunnels.conf';
  static const String _certsDir = 'certificates';

  String? _dataDir;

  /// Get the i2pd data directory
  Future<String> get dataDirectory async {
    if (_dataDir != null) return _dataDir!;
    
    final appDir = await getApplicationDocumentsDirectory();
    _dataDir = '${appDir.path}/i2pd';
    
    // Ensure directory exists
    final dir = Directory(_dataDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return _dataDir!;
  }

  /// Get path to main config file
  Future<String> get configPath async {
    final dir = await dataDirectory;
    return '$dir/$_configFileName';
  }

  /// Get path to tunnels config file
  Future<String> get tunnelsConfigPath async {
    final dir = await dataDirectory;
    return '$dir/$_tunnelsFileName';
  }

  /// Get path to certificates directory
  Future<String> get certificatesPath async {
    final dir = await dataDirectory;
    final certsDir = '$dir/$_certsDir';
    
    final certsDirObj = Directory(certsDir);
    if (!await certsDirObj.exists()) {
      await certsDirObj.create(recursive: true);
    }
    
    return certsDir;
  }

  /// Initialize configuration files on first run
  Future<void> initializeConfig() async {
    final configFile = File(await configPath);
    final tunnelsFile = File(await tunnelsConfigPath);
    
    // Copy default config if doesn't exist
    if (!await configFile.exists()) {
      await _copyAssetToFile('assets/config/i2pd.conf', configFile);
    }
    
    if (!await tunnelsFile.exists()) {
      await _copyAssetToFile('assets/config/tunnels.conf', tunnelsFile);
    }
    
    // Create subdirectories
    final dir = await dataDirectory;
    await Directory('$dir/addressbook').create(recursive: true);
    await Directory('$dir/peerProfiles').create(recursive: true);
    await Directory('$dir/tags').create(recursive: true);
  }

  /// Copy a bundled asset to a file
  Future<void> _copyAssetToFile(String assetPath, File destFile) async {
    try {
      final data = await rootBundle.loadString(assetPath);
      await destFile.writeAsString(data);
    } catch (e) {
      // Asset might not exist in development, create default
      if (assetPath.contains('i2pd.conf')) {
        await destFile.writeAsString(_defaultConfig);
      } else if (assetPath.contains('tunnels.conf')) {
        await destFile.writeAsString(_defaultTunnels);
      }
    }
  }

  /// Read the main config file
  Future<String> readConfig() async {
    final file = File(await configPath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return _defaultConfig;
  }

  /// Write the main config file
  Future<void> writeConfig(String content) async {
    final file = File(await configPath);
    await file.writeAsString(content);
  }

  /// Read the tunnels config file
  Future<String> readTunnelsConfig() async {
    final file = File(await tunnelsConfigPath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return _defaultTunnels;
  }

  /// Write the tunnels config file
  Future<void> writeTunnelsConfig(String content) async {
    final file = File(await tunnelsConfigPath);
    await file.writeAsString(content);
  }

  /// Parse config into key-value map
  Future<Map<String, Map<String, String>>> parseConfig() async {
    final content = await readConfig();
    return _parseIniConfig(content);
  }

  /// Parse INI-style config file
  Map<String, Map<String, String>> _parseIniConfig(String content) {
    final result = <String, Map<String, String>>{};
    String currentSection = 'general';
    result[currentSection] = {};

    for (var line in content.split('\n')) {
      line = line.trim();
      
      // Skip comments and empty lines
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }
      
      // Section header
      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line.substring(1, line.length - 1).toLowerCase();
        result[currentSection] = {};
        continue;
      }
      
      // Key-value pair
      final eqIndex = line.indexOf('=');
      if (eqIndex > 0) {
        final key = line.substring(0, eqIndex).trim();
        final value = line.substring(eqIndex + 1).trim();
        result[currentSection]![key] = value;
      }
    }

    return result;
  }

  /// Update a specific config value
  Future<void> updateConfigValue(String section, String key, String value) async {
    var content = await readConfig();
    final lines = content.split('\n');
    final newLines = <String>[];
    String currentSection = 'general';
    bool found = false;
    bool inSection = false;

    for (var line in lines) {
      final trimmed = line.trim();
      
      // Check for section
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        // If we were in the target section and didn't find key, add it
        if (inSection && !found) {
          newLines.add('$key = $value');
          found = true;
        }
        currentSection = trimmed.substring(1, trimmed.length - 1).toLowerCase();
        inSection = currentSection == section.toLowerCase();
      }
      
      // Check for key
      if (inSection && trimmed.startsWith(key)) {
        line = '$key = $value';
        found = true;
      }
      
      newLines.add(line);
    }

    // If section not found, add it
    if (!found) {
      newLines.add('');
      newLines.add('[$section]');
      newLines.add('$key = $value');
    }

    await writeConfig(newLines.join('\n'));
  }

  /// Default config content
  static const String _defaultConfig = '''
[general]
log = file
logfile = i2pd.log
loglevel = info

[ntcp2]
enabled = true
published = true

[ssu2]
enabled = true
published = true

[httpproxy]
enabled = true
address = 127.0.0.1
port = 4444

[socksproxy]
enabled = true
address = 127.0.0.1
port = 4447

[upnp]
enabled = true

[limits]
transittunnels = 500
''';

  /// Default tunnels config
  static const String _defaultTunnels = '''
[HTTP-PROXY]
type = http
host = 127.0.0.1
port = 4444

[SOCKS-PROXY]
type = socks
host = 127.0.0.1
port = 4447
''';
}
