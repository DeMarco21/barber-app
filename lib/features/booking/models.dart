

class Barber {
  final String id;
  final String name;
  final String photoUrl;
  final List<String> services;
  final Map<String, List<String>> availability;
  // Example: { "2025-09-13": ["09:00","10:00","11:30"] }

  Barber({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.services,
    required this.availability,
  });
}

class AppointmentDraft {
  final Barber barber;
  final String date;     // "YYYY-MM-DD"
  final String timeSlot; // "HH:mm"
  final String service;

  AppointmentDraft({
    required this.barber,
    required this.date,
    required this.timeSlot,
    required this.service,
  });
}

// Mock barbers (temporary local data)
final List<Barber> mockBarbers = [
  Barber(
    id: 'b1',
    name: 'Marcus “Edge” Bailey',
    photoUrl: '',
    services: ['Fade', 'Line-up', 'Beard Trim'],
    availability: {
      '2025-09-13': ['09:00', '10:00', '11:30', '14:00'],
      '2025-09-14': ['10:00', '12:00', '15:30'],
    },
  ),
  Barber(
    id: 'b2',
    name: 'Shane “Clip” Morgan',
    photoUrl: '',
    services: ['Cut & Shave', 'Kids Cut', 'Hot Towel Shave'],
    availability: {
      '2025-09-13': ['09:30', '11:00', '13:00', '16:00'],
      '2025-09-15': ['09:00', '10:30', '12:30'],
    },
  ),
];