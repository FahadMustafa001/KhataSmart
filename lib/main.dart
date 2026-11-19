import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/local_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize and load offline database
  await LocalDatabaseService.instance.init();
  runApp(const SmartKhataApp());
}

class SmartKhataApp extends StatelessWidget {
  const SmartKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
