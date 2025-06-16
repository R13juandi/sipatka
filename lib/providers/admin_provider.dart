import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/profile_model.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProvider with ChangeNotifier {
  final _supabase = supabase;
  final AuthProvider? authProvider;

  AdminProvider(this.authProvider);

  Future<Map<String, dynamic>> registerNewStudent({
    required String parentName,
    required String email,
    required String password,
    required String studentName,
    required String className,
    required int academicYearStart,
    required double sppAmount,
  }) async {
    if (authProvider?.userRole != 'admin') {
      return {'success': false, 'message': 'Hanya admin yang bisa mendaftarkan siswa.'};
    }
    try {
      final response = await _supabase.functions.invoke(
        'create-user-and-bills',
        body: {
          'email': email,
          'password': password,
          'spp_amount': sppAmount,
          'academic_year_start': academicYearStart,
          'user_data': {
            'full_name': parentName,
            'student_name': studentName,
            'class_name': className,
            'role': 'user',
          }
        },
      );

      if (response.data['error'] != null) {
        return {'success': false, 'message': response.data['error']};
      }
      notifyListeners();
      return {'success': true, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memanggil fungsi: ${e.toString()}'};
    }
  }

  Future<List<Profile>> getStudents() async {
    try {
      final data = await _supabase.from('profiles').select('*, students(*)').eq('role', 'user');
      return data.map((item) => Profile.fromMap(item)).toList();
    } catch (e) {
      print("Error fetching students: $e");
      return [];
    }
  }

  Future<List<Payment>> getPendingPaymentsWithStudentInfo() async {
    try {
      final data = await _supabase
          .from('payments')
          .select('*, students(*, profiles(*))') // Join nested
          .eq('status', 'pending')
          .order('created_at', ascending: true);
          
      return data.map((item) => Payment.fromMap(item)).toList();
    } catch (e) {
      print("Error get pending payments: $e");
      return [];
    }
  }

  Future<bool> updatePaymentStatus(String paymentId, String status) async {
    try {
      await _supabase.from('payments').update({
        'status': status,
        if(status == 'unpaid') 'proof_of_payment_url': null,
      }).eq('id', paymentId);
      return true;
    } catch (e) {
      return false;
    }
  }
}