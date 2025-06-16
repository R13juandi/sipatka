import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/profile_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/screens/admin/admin_chat_detail_screen.dart';
import 'package:sipatka/screens/admin/student_detail_screen.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});
  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  String _searchQuery = '';
  List<Profile> _allStudents = [];
  List<Profile> _filteredStudents = [];
  late Future<List<Profile>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() {
    final future = context.read<AdminProvider>().getStudents();
    setState(() {
      _studentsFuture = future;
    });
    return future;
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredStudents = _allStudents.where((student) {
        final studentName = student.studentName?.toLowerCase() ?? '';
        final parentName = student.parentName?.toLowerCase() ?? '';
        final className = student.className?.toLowerCase() ?? '';
        return studentName.contains(_searchQuery) || parentName.contains(_searchQuery) || className.contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Siswa')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterStudents,
              decoration: const InputDecoration(labelText: 'Cari (Nama Siswa, Wali, Kelas)', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Profile>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada data siswa.'));
                }
                
                // Simpan data asli jika list _allStudents kosong
                if (_allStudents.isEmpty) {
                  _allStudents = snapshot.data!;
                  _filteredStudents = _allStudents;
                }

                return RefreshIndicator(
                  onRefresh: _loadStudents,
                  child: ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(student.studentName ?? 'Nama Siswa Kosong'),
                          subtitle: Text('Wali: ${student.parentName ?? ''} | Kelas: ${student.className ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            tooltip: 'Chat dengan Wali',
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatDetailScreen(user: student)));
                            },
                          ),
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student)));
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/admin_create_student').then((_) => _loadStudents()),
        label: const Text('Tambah Siswa'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}