import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/providers/payment_provider.dart';
import 'package:sipatka/screens/admin/admin_dashboard_screen.dart';
import 'package:sipatka/screens/admin/create_student_screen.dart';
import 'package:sipatka/screens/auth/forgot_password_screen.dart';
import 'package:sipatka/screens/auth/login_screen.dart';
import 'package:sipatka/screens/home/dashboard_screen.dart';
import 'package:sipatka/screens/splash_screen.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi format tanggal untuk bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase
  await Supabase.initialize(
    // GANTI DENGAN URL & ANON KEY DARI PROJECT SUPABASE ANDA
    url: 'https://jcgqskaxzjbijkisctvo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjZ3Fza2F4empiaWpraXNjdHZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5NDc2OTksImV4cCI6MjA2NTUyMzY5OX0.ekJSQ_5DfQLkSnscWC_WItgSosxY-q5EcogXJqgItT4',
  );
  
  runApp(const MyApp());
}

// Instance Supabase client yang bisa diakses di mana saja
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (_) => AdminProvider(null),
          update: (_, auth, __) => AdminProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create: (_) => PaymentProvider(null),
          update: (_, auth, __) => PaymentProvider(auth),
        ),
      ],
      child: MaterialApp(
        title: 'SIPATKA',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
          '/admin_create_student': (context) => const CreateStudentScreen(),
        },
      ),
    );
  }
}