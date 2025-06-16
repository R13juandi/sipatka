// Model ini menggabungkan data dari tabel 'profiles' dan 'students'
class Profile {
  final String id; // parent_id
  final String? email;
  final String? parentName;
  final String? role;
  
  // Data Siswa
  final String? studentId;
  final String? studentName;
  final String? className;

  Profile({
    required this.id,
    this.email,
    this.parentName,
    this.role,
    this.studentId,
    this.studentName,
    this.className,
  });

  // Factory constructor untuk membuat objek Profile dari data Supabase
  factory Profile.fromMap(Map<String, dynamic> map) {
    List<dynamic> students = map['students'] ?? [];
    Map<String, dynamic>? studentData = students.isNotEmpty ? students.first : null;

    return Profile(
      id: map['id'],
      email: map['email'],
      parentName: map['full_name'], // Menggunakan full_name dari tabel profiles
      role: map['role'],
      studentId: studentData?['id'],
      studentName: studentData?['full_name'], // Menggunakan full_name dari tabel students
      className: studentData?['class_name'],
    );
  }
}