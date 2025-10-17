class Doctor {
  final int id;
  final String fullName;
  final String email;
  final String specialty;

  Doctor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.specialty,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      specialty: json['specialty'],
    );
  }
}
