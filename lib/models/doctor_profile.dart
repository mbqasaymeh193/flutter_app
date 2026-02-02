class DoctorProfile {
  final int doctorId;
  final int userId;
  final String fullName;
  final String email;
  final String specialty;
  final String phoneNumber;
  final String university;
  final String qualification;
  final String clinicAddress;
  final String bio;
  final int experienceYears;
  final double averageRating;
  final int ratingsCount;

  DoctorProfile({
    required this.doctorId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.specialty,
    required this.phoneNumber,
    required this.university,
    required this.qualification,
    required this.clinicAddress,
    required this.bio,
    required this.experienceYears,
    required this.averageRating,
    required this.ratingsCount,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    final university = json['university']?.toString() ??
        json['University']?.toString() ??
        json['education']?.toString() ??
        '';

    final qualification = json['qualification']?.toString() ??
        json['Qualification']?.toString() ??
        json['education']?.toString() ??
        '';

    return DoctorProfile(
      doctorId: _parseInt(json['doctorId'] ?? json['DoctorId'] ?? json['id'] ?? json['Id']),
      userId: _parseInt(json['userId'] ?? json['UserId'] ?? json['doctorUserId'] ?? json['DoctorUserId']),
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      university: university,
      qualification: qualification,
      clinicAddress: json['clinicAddress']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      experienceYears: _parseInt(json['experienceYears'] ?? json['yearsOfExperience']),
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
