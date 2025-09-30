// lib/core/models/app_user.dart
class AppUser {
  final String uid;
  final String email;
  final String role; // 'mozo' | 'cocinero'

  // --- Constantes para los roles ---
  static const String roleWaiter = 'mozo';
  static const String roleKitchen = 'cocinero';

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  bool get isWaiter => role == roleWaiter;
  bool get isKitchen => role == roleKitchen;

  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role,
  };

  static AppUser fromMap(String uid, Map<String, dynamic>? map) {
    final m = map ?? const {};
    final email = (m['email'] ?? '').toString();
    final rawRole = (m['role'] ?? roleWaiter).toString();
    // Aseguramos que el rol sea uno de los válidos
    final role = rawRole == roleKitchen ? roleKitchen : roleWaiter;
    return AppUser(uid: uid, email: email, role: role);
  }
}