class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.salt,
    required this.hash,
    required this.createdAt,
    this.verified = false,
  });

  final String id;
  String name;
  final String email;
  String salt;
  String hash;
  final int createdAt;

  /// Почта подтверждена кодом из письма.
  bool verified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'salt': salt,
        'hash': hash,
        'createdAt': createdAt,
        'verified': verified,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        salt: j['salt'] as String,
        hash: j['hash'] as String,
        createdAt: j['createdAt'] as int,
        verified: (j['verified'] as bool?) ?? true,
      );
}
