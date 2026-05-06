class User {
  final String id;
  final String email;
  final String name;
  final String? picture;
  final String? provider;
  final bool? emailVerified;
  final bool isAdmin;
  final String? phone;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.picture,
    this.provider,
    this.emailVerified,
    this.isAdmin = false,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      picture: json['picture'] as String?,
      provider: json['provider'] as String?,
      emailVerified: json['emailVerified'] as bool?,
      isAdmin: json['admin'] as bool? ?? false,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'picture': picture,
      'provider': provider,
      'emailVerified': emailVerified,
      'admin': isAdmin,
      'phone': phone,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? picture,
    String? provider,
    bool? emailVerified,
    bool? isAdmin,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      picture: picture ?? this.picture,
      provider: provider ?? this.provider,
      emailVerified: emailVerified ?? this.emailVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      phone: phone ?? this.phone,
    );
  }
}
