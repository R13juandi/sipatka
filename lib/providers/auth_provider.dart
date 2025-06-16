import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = supabase;
  Profile? _profile;
  bool _isLoading = true;

  Profile? get profile => _profile;
  bool get isLoggedIn => _supabase.auth.currentSession != null;
  String get userName => _profile?.parentName ?? '';
  String get studentName => _profile?.studentName ?? '';
  String get className => _profile?.className ?? '';
  String get userRole => _profile?.role ?? 'user';
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Listener ini sekarang hanya untuk handle perubahan di background (misal token refresh)
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.tokenRefreshed) {
        if(data.session != null) {
            _fetchProfile(data.session!.user.id);
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
          _profile = null;
          notifyListeners();
      }
    });
    // Cek sesi awal
    _initialize();
  }
  
  Future<void> _initialize() async {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _fetchProfile(session.user.id);
      }
      _isLoading = false;
      notifyListeners();
  }
  
  Future<void> _fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('*, students(*)')
          .eq('id', userId)
          .single();
      _profile = Profile.fromMap(data);
    } catch (e) {
      print("Error fetching profile: $e");
      _profile = null; // Pastikan null jika error
    }
    notifyListeners();
  }

  // PERBAIKAN UTAMA ADA DI SINI
  Future<String?> login(String email, String password) async {
    try {
      // 1. Coba login
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      
      // 2. Jika berhasil, JANGAN langsung selesai.
      //    Tunggu sampai data profil (beserta role) berhasil diambil.
      if (response.user != null) {
        await _fetchProfile(response.user!.id);
      } else {
        return "Gagal mendapatkan data user setelah login.";
      }
      
      return null; // Kembalikan null jika semua sukses
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Terjadi error tidak diketahui.';
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<String?> sendPasswordReset(String email) async {
      try {
          await _supabase.auth.resetPasswordForEmail(email);
          return null;
      } on AuthException catch(e) {
          return e.message;
      } catch (e) {
          return 'Terjadi error tidak diketahui';
      }
  }
}