// =============================
// file: lib/models/app_user.dart
// =============================
class AppUser {
  final String uid;
  final String email;
  final String role; // 'mozo' | 'cocinero'

  const AppUser({required this.uid, required this.email, required this.role});

  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role,
    'createdAt': DateTime.now().toIso8601String(),
  };

  static AppUser fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: (map['email'] ?? '') as String,
      role: (map['role'] ?? 'mozo') as String,
    );
  }
}
