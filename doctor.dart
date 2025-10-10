class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String description;
  final String experience;
  final double rating;
  final String imageUrl;
  final int patients;
  final String education;
  final String hospital;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.description,
    required this.experience,
    required this.rating,
    required this.imageUrl,
    required this.patients,
    required this.education,
    required this.hospital,
  });
}

// Mock data
final List<Doctor> mockDoctors = [
  Doctor(
    id: '1',
    name: 'Dr. Ahmad Hassan',
    specialty: 'General Practitioner',
    description: 'Experienced family doctor with focus on preventive care',
    experience: '10 years',
    rating: 4.8,
    imageUrl: 'assets/images/doctors/5ozFKWQbIW0e.jpg',
    patients: 1200,
    education: 'MD, Harvard Medical School',
    hospital: 'City General Hospital',
  ),
  Doctor(
    id: '2',
    name: 'Dr. Sarah Johnson',
    specialty: 'Cardiologist',
    description: 'Heart specialist with extensive experience in cardiac care',
    experience: '15 years',
    rating: 4.9,
    imageUrl: 'assets/images/doctors/FOCSKaFpPlGa.jpg',
    patients: 950,
    education: 'MD, Johns Hopkins University',
    hospital: 'Heart Care Center',
  ),
  Doctor(
    id: '3',
    name: 'Dr. Michael Chen',
    specialty: 'Pediatrician',
    description: 'Children healthcare expert with gentle approach',
    experience: '12 years',
    rating: 4.7,
    imageUrl: 'assets/images/doctors/D7YC0K59TWUo.jpg',
    patients: 1500,
    education: 'MD, Stanford University',
    hospital: 'Children Medical Center',
  ),
  Doctor(
    id: '4',
    name: 'Dr. Emily Rodriguez',
    specialty: 'Dermatologist',
    description: 'Skin care specialist focusing on cosmetic and medical dermatology',
    experience: '8 years',
    rating: 4.6,
    imageUrl: 'assets/images/doctors/Os9XMUnAJbWE.jpg',
    patients: 800,
    education: 'MD, UCLA Medical School',
    hospital: 'Skin Health Clinic',
  ),
  Doctor(
    id: '5',
    name: 'Dr. David Williams',
    specialty: 'Orthopedic Surgeon',
    description: 'Expert in bone and joint surgery',
    experience: '18 years',
    rating: 4.9,
    imageUrl: 'assets/images/doctors/kCDJ7VD5AadD.jpg',
    patients: 750,
    education: 'MD, Mayo Clinic',
    hospital: 'Orthopedic Institute',
  ),
  Doctor(
    id: '6',
    name: 'Dr. Lisa Anderson',
    specialty: 'Ophthalmologist',
    description: 'Eye care specialist with focus on vision correction',
    experience: '11 years',
    rating: 4.8,
    imageUrl: 'assets/images/doctors/5ozFKWQbIW0e.jpg',
    patients: 900,
    education: 'MD, Columbia University',
    hospital: 'Vision Care Center',
  ),
];

final List<String> specialties = [
  'General',
  'Cardiology',
  'Pediatrics',
  'Dermatology',
  'Orthopedics',
  'Ophthalmology',
  'Dentistry',
  'Neurology',
];
