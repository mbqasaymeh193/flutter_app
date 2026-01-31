class DoctorProfile {
  final int userId;
  final String fullName;
  final String email;
  final String specialty;
  final String phoneNumber;
  final String education;
  final String clinicName;
  final String clinicAddress;
  final String bio;
  final int yearsOfExperience;
  final double averageRating;
  final int ratingsCount;

  DoctorProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.specialty,
    required this.phoneNumber,
    required this.education,
    required this.clinicName,
    required this.clinicAddress,
    required this.bio,
    required this.yearsOfExperience,
    required this.averageRating,
    required this.ratingsCount,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      userId: _parseInt(json['userId'] ?? json['id']),
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      education: json['education']?.toString() ?? '',
      clinicName: json['clinicName']?.toString() ?? '',
      clinicAddress: json['clinicAddress']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      yearsOfExperience: _parseInt(json['yearsOfExperience']),
      averageRating: _parseDouble(json['averageRating']),
      ratingsCount: _parseInt(json['ratingsCount']),
    );
  }

  // ---------- Helpers ----------

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
