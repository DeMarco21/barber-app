import 'dart:ui';

import 'package:barber/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard>
    with TickerProviderStateMixin {
  // State
  String _clientName = "";
  bool _isLoading = true;
  List<Map<String, dynamic>> _barbers = [];

  // Booking State
  Map<String, dynamic>? _selectedBarber;
  DateTime? _selectedDate;
  String? _selectedTime;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Dummy data for demonstration
  final Map<String, List<String>> _busySlots = {
    "Marcus Bailey": ["10:00 AM", "1:00 PM"],
    "Shane Morgan": ["11:00 AM", "2:00 PM"],
  };

  final List<String> _allTimeSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM", "12:00 PM",
    "01:00 PM", "02:00 PM", "03:00 PM", "04:00 PM",
  ];

  final List<Map<String, dynamic>> _upcomingAppointments = [
    {
      'barber': 'Marcus Bailey',
      'date': 'Jul 28, 2024',
      'time': '10:00 AM',
      'image': 'assets/images/marcus.jpg'
    },
  ];

  final List<Map<String, dynamic>> _pastAppointments = [
    {
      'barber': 'Shane Morgan',
      'date': 'Jun 15, 2024',
      'time': '11:00 AM',
      'image': 'assets/images/shane.jpg'
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchInitialData();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchInitialData() async {
    await _fetchUserName();
    await _fetchBarbers();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
        setState(() {
          _clientName = doc.data()?['username'] ?? user.displayName ?? 'User';
        });
      }
    } catch (e) {
      // Handle error silently or with a snackbar
    }
  }

  Future<void> _fetchBarbers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('barbers').get();
      final barbersData = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'No Name',
          'specialty': data['specialty'] ?? 'No Specialty',
          // Assumes you have an 'imageUrl' field in your Firestore documents
          'imageUrl': data['imageUrl'] ?? 'assets/images/default_avatar.png',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _barbers = barbersData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load barbers: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_bg.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          CustomScrollView(
            slivers: [
              _buildHeroSection(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            _buildSectionTitle("Choose Your Barber"),
                            const SizedBox(height: 20),
                            _buildBarberShowcase(),
                            if (_selectedBarber != null) ...[
                              const SizedBox(height: 40),
                              _buildSectionTitle("Select a Day"),
                              const SizedBox(height: 20),
                              _buildInlineCalendar(),
                            ],
                            if (_selectedDate != null) ...[
                              const SizedBox(height: 40),
                              _buildSectionTitle("Available Times"),
                              const SizedBox(height: 20),
                              _buildTimeSlots(),
                            ],
                            if (_selectedTime != null) ...[
                              const SizedBox(height: 40),
                              _buildBookingConfirmationButton(),
                            ],
                             const SizedBox(height: 50),
                            _buildAppointmentsSection(),
                            const SizedBox(height: 50),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  SliverAppBar _buildHeroSection() {
    return SliverAppBar(
      expandedHeight: 120.0,
      backgroundColor: Colors.transparent,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _clientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _signOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarberShowcase() {
    return SizedBox(
      height: 240,
      child: _barbers.isEmpty
          ? const Center(child: Text("No barbers available.", style: TextStyle(color: Colors.white70)))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _barbers.length,
              itemBuilder: (context, index) {
                final barber = _barbers[index];
                final isSelected = _selectedBarber?['id'] == barber['id'];
                return _BarberCard(
                  barber: barber,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedBarber = isSelected ? null : barber;
                      _selectedDate = null;
                      _selectedTime = null;
                    });
                  },
                );
              },
            ),
    );
  }

  Widget _buildInlineCalendar() {
    final today = DateTime.now();
    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30, // Show next 30 days
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index));
          final isSelected = _selectedDate != null &&
              date.day == _selectedDate!.day &&
              date.month == _selectedDate!.month &&
              date.year == _selectedDate!.year;

          return _DateChip(
            date: date,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedDate = isSelected ? null : date;
                _selectedTime = null;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    final busy = _busySlots[_selectedBarber?['name']] ?? [];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _allTimeSlots.map((time) {
        final isBusy = busy.contains(time);
        final isSelected = _selectedTime == time;
        return _TimeSlotChip(
          time: time,
          isBusy: isBusy,
          isSelected: isSelected,
          onTap: () {
            if (!isBusy) {
              setState(() {
                _selectedTime = isSelected ? null : time;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildBookingConfirmationButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.6),
                blurRadius: _pulseAnimation.value,
                spreadRadius: _pulseAnimation.value / 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle booking confirmation
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                  'Booked with ${_selectedBarber!['name']} on ${DateFormat.yMMMd().format(_selectedDate!)} at $_selectedTime'),
            ));
          },
          borderRadius: BorderRadius.circular(50),
          child: Ink(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: const LinearGradient(
                colors: [Colors.amber, Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text(
                'CONFIRM BOOKING',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Your Appointments"),
        const SizedBox(height: 20),
        _buildAppointmentTimeline(
          title: "Upcoming",
          appointments: _upcomingAppointments,
          icon: Icons.calendar_month,
        ),
        const SizedBox(height: 30),
        _buildAppointmentTimeline(
          title: "History",
          appointments: _pastAppointments,
          icon: Icons.history,
          isPast: true,
        ),
      ],
    );
  }

  Widget _buildAppointmentTimeline({
    required String title,
    required List<Map<String, dynamic>> appointments,
    required IconData icon,
    bool isPast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 15),
        ...appointments.map((appt) => _AppointmentCard(appointment: appt, isPast: isPast)),
      ],
    );
  }
}

// --- CUSTOM WIDGETS ---

class _BarberCard extends StatelessWidget {
  final Map<String, dynamic> barber;
  final bool isSelected;
  final VoidCallback onTap;

  const _BarberCard({
    required this.barber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16),
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(barber['imageUrl']),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(isSelected ? 0.2 : 0.6),
              BlendMode.darken,
            ),
          ),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                barber['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 5, color: Colors.black87)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                barber['specialty'],
                style: TextStyle(
                  color: Colors.amber[200],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        width: 65,
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date).toUpperCase(), // "MON", "TUE"
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('d').format(date), // "1", "15"
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final String time;
  final bool isBusy;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.time,
    required this.isBusy,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool canTap = !isBusy;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber
              : (isBusy ? const Color(0xFF2a2a2a) : const Color(0xFF1e1e1e)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : (isBusy ? Colors.transparent : Colors.white24),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : (isBusy ? Colors.white38 : Colors.white),
            fontWeight: FontWeight.bold,
            decoration: isBusy ? TextDecoration.lineThrough : TextDecoration.none,
            decorationColor: Colors.redAccent,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final bool isPast;

  const _AppointmentCard({required this.appointment, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e1e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage(appointment['image']),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['barber'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${appointment['date']} at ${appointment['time']}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!isPast)
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}
