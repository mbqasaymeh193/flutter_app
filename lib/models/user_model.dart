class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? role;
  final String? token;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      name: json['name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      token: json['token'] ?? json['accessToken'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'token': token,
      };
}
