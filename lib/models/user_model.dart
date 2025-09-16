class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // "client", "barber", "admin"
  final String? phone;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      role: map['role'],
      phone: map['phone'],
    );
  }
}