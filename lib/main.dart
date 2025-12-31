import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/i2pd_service.dart';
import 'services/config_manager.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration
  final configManager = ConfigManager();
  await configManager.initializeConfig();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => I2pdService()),
        Provider<ConfigManager>.value(value: configManager),
      ],
      child: const I2pdApp(),
    ),
  );
}

class I2pdApp extends StatelessWidget {
  const I2pdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'i2pd',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
