import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentProvider with ChangeNotifier {
  final _supabase = supabase;
  final AuthProvider? authProvider;

  List<Payment> _payments = [];
  bool _isLoading = true;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

  PaymentProvider(this.authProvider) {
    authProvider?.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    if (authProvider?.isLoggedIn ?? false) {
      fetchPayments();
    } else {
      _payments = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayments() async {
    if (authProvider?.profile?.studentId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('payments')
          .select()
          .eq('student_id', authProvider!.profile!.studentId!)
          .order('due_date', ascending: true);

      _payments = data.map((item) => Payment.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching payments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> uploadProofForMultiplePayments(List<String> paymentIds, File imageFile, String paymentMethod) async {
    if (authProvider?.profile == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final userId = authProvider!.profile!.id;
      final fileExt = imageFile.path.split('.').last;
      final filePath = '/$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage.from('payment-proofs').upload(filePath, imageFile);
      final imageUrl = _supabase.storage.from('payment-proofs').getPublicUrl(filePath);

      for (String paymentId in paymentIds) {
        await _supabase.from('payments').update({
          'status': 'pending',
          'proof_of_payment_url': imageUrl,
          'payment_method': paymentMethod,
          'paid_date': DateTime.now().toIso8601String()
        }).eq('id', paymentId);
      }
      
      await fetchPayments();
      return true;
    } catch (e) {
      print('Error uploading proof: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  @override
  void dispose() {
    authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
}