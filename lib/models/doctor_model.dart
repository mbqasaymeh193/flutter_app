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
      id: json['id'] ?? json['Id'],
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      specialty: json['specialty'] ?? json['Specialty'] ?? '',
    );
  }
}
