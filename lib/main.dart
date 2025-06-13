import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/providers/payment_provider.dart';
import 'package:sipatka/screens/admin/admin_dashboard_screen.dart';
import 'package:sipatka/screens/auth/login_screen.dart';
import 'package:sipatka/screens/home/dashboard_screen.dart';
import 'package:sipatka/screens/splash_screen.dart';
import 'package:sipatka/services/notification_service.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:firebase_core/firebase_core.dart'; // Hanya import ini
import 'firebase_options.dart'; // Import file konfigurasi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Gunakan DefaultFirebaseOptions langsung
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'SIPATKA',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
        },
      ),
    );
  }
}