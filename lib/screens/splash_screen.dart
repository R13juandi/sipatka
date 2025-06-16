import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Beri waktu untuk splash screen
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    // PERBAIKAN: Tunggu sampai provider selesai memeriksa status login awal
    // Ini penting agar kita tidak bernavigasi sebelum tahu rolenya
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (authProvider.isLoggedIn) {
      final role = authProvider.userRole;
      if (role == 'admin') {
        Navigator.of(context).pushReplacementNamed('/admin_dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 120),
            const SizedBox(height: 20),
            const Text("SIPATKA", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text("Sistem Pembayaran SPP TK An-Naafi'Nur"),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}