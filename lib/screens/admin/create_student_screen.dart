import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class CreateStudentScreen extends StatefulWidget {
  const CreateStudentScreen({super.key});

  @override
  State<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _sppAmountController = TextEditingController();

  String? _selectedClass;
  final List<String> _classes = ['Kelas A', 'Kelas B'];
  int _academicYearStart = DateTime.now().month < 7 ? DateTime.now().year - 1 : DateTime.now().year;
  bool _isLoading = false;

  @override
  void dispose() {
    _parentNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentNameController.dispose();
    _sppAmountController.dispose();
    super.dispose();
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final adminProvider = context.read<AdminProvider>();
    final result = await adminProvider.registerNewStudent(
      parentName: _parentNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      studentName: _studentNameController.text.trim(),
      className: _selectedClass!,
      academicYearStart: _academicYearStart,
      sppAmount: double.tryParse(_sppAmountController.text.trim()) ?? 0,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Terjadi error tidak diketahui.'),
          backgroundColor: (result['success'] ?? false) ? Colors.green : Colors.red,
        ),
      );
      if (result['success'] == true) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun Siswa Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Data Wali & Login', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _parentNameController, label: 'Nama Lengkap Orang Tua/Wali'),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _emailController, label: 'Email (untuk Login)', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _passwordController, label: 'Password (min. 6 karakter)', obscureText: true),
              
              const Divider(height: 40, thickness: 1),

              Text('Data Siswa & SPP', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _studentNameController, label: 'Nama Lengkap Siswa'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: const InputDecoration(labelText: 'Kelas'),
                items: _classes.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedClass = newValue),
                validator: (value) => value == null ? 'Pilih kelas' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _sppAmountController, label: 'Jumlah SPP per Bulan (contoh: 350000)', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text('Tagihan SPP akan dibuat otomatis untuk Tahun Ajaran $_academicYearStart/${_academicYearStart + 1}.', textAlign: TextAlign.center,),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: _isLoading ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)) : const Icon(Icons.person_add),
                onPressed: _isLoading ? null : _registerStudent,
                label: const Text('Daftarkan Siswa'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label tidak boleh kosong.';
        if (label.contains('Password') && value.length < 6) return 'Password minimal 6 karakter.';
        if (label.contains('Email') && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Format email tidak valid';
        return null;
      },
    );
  }
}