import 'dart:ui';
import 'package:barber/screens/login_screen.dart';
import 'package:barber/widgets/glass_container.dart';
import 'package:barber/widgets/glowing_icon_button.dart';
import 'package:barber/widgets/modern_tab_indicator.dart';
import 'package:barber/widgets/particles_painter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  String _appointmentFilter = 'Upcoming';
  final List<String> _barbers = ['All Barbers'];
  String _selectedBarber = 'All Barbers';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutCubic),
    );
    _headerAnimationController.forward();
    _fetchBarbers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchBarbers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'barber')
          .get();
      final barberNames = snapshot.docs
          .map((doc) => (doc.data())['username'] as String)
          .toList();
      if (mounted) {
        setState(() {
          _barbers.addAll(barberNames);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to fetch barbers: $e');
      }
    }
  }

  Future<void> _updateUserRole(String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': newRole});
      _showSuccessSnackBar('User role updated successfully.');
    } catch (e) {
      _showErrorSnackBar('Failed to update role: $e');
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      _showSuccessSnackBar('User deleted successfully.');
    } catch (e) {
      _showErrorSnackBar('Failed to delete user: $e');
    }
  }

  Future<void> _updateBarberSpecialties(String uid, List<String> specialties) async {
    try {
      await FirebaseFirestore.instance
          .collection('barbers')
          .doc(uid)
          .update({'specialties': specialties});
      _showSuccessSnackBar('Barber specialties updated.');
    } catch (e) {
      _showErrorSnackBar('Failed to update specialties: $e');
    }
  }

  Future<void> _cancelAppointment(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).update({'status': 'cancelled'});
      _showSuccessSnackBar('Appointment cancelled.');
    } catch (e) {
      _showErrorSnackBar('Failed to cancel appointment: $e');
    }
  }

  Future<void> _markAppointmentAsComplete(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).update({'status': 'completed'});
      _showSuccessSnackBar('Appointment marked as complete.');
    } catch (e) {
      _showErrorSnackBar('Failed to mark appointment as complete: $e');
    }
  }

  void _confirmCancelAppointment(BuildContext context, String docId) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            content: GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFD4AF37),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm Cancellation',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Are you sure you want to cancel this appointment?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('No'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _cancelAppointment(docId);
                            },
                            child: const Text('Yes, Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showManageSpecialtiesDialog(BuildContext context, String uid, List<dynamic> currentSpecialties) {
    final TextEditingController specialtyController = TextEditingController();
    List<String> specialties = List<String>.from(currentSpecialties);

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                content: GlassContainer(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Specialties',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (specialties.isNotEmpty)
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: specialties.map((specialty) {
                                return Chip(
                                  label: Text(specialty),
                                  onDeleted: () {
                                    setState(() {
                                      specialties.remove(specialty);
                                    });
                                  },
                                );
                              }).toList(),
                            )
                          else
                            const Text('No specialties added yet.', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 20),
                          TextField(
                            controller: specialtyController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Add New Specialty',
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.amber.withOpacity(0.5)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.amber),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add, color: Colors.amber),
                                onPressed: () {
                                  final newSpecialty = specialtyController.text.trim();
                                  if (newSpecialty.isNotEmpty && !specialties.contains(newSpecialty)) {
                                    setState(() {
                                      specialties.add(newSpecialty);
                                    });
                                    specialtyController.clear();
                                  }
                                },
                              ),
                            ),
                            onSubmitted: (value) {
                              final newSpecialty = value.trim();
                              if (newSpecialty.isNotEmpty && !specialties.contains(newSpecialty)) {
                                setState(() {
                                  specialties.add(newSpecialty);
                                });
                                specialtyController.clear();
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _updateBarberSpecialties(uid, specialties);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Save'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0F0F23),
              Color(0xFF000000),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _headerAnimation.value,
                    child: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: ParticlesPainter(_headerAnimation.value),
                              ),
                            ),
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 80.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Welcome,',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Admin',
                                                style: GoogleFonts.inter(
                                                  color: goldColor,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GlowingIconButton(
                                          icon: Icons.logout_rounded,
                                          onPressed: _signOut,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: GlassContainer(
                    borderRadius: 30,
                    child: TabBar(
                      controller: _tabController,
                      indicator: ModernTabIndicator(),
                      labelColor: goldColor,
                      unselectedLabelColor: Colors.white60,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Appointments'))),
                        Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('User Management'))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsTab(),
                  _buildUsersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.grey[900],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedBarber,
                      isExpanded: true,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber.withOpacity(0.5)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.amber),
                      items: _barbers.map((String barber) {
                        return DropdownMenuItem<String>(
                          value: barber,
                          child: Text(barber, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBarber = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    children: ['Upcoming', 'Completed', 'All'].map((filter) {
                      return ChoiceChip(
                        label: Text(filter),
                        selected: _appointmentFilter == filter,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _appointmentFilter = filter;
                            });
                          }
                        },
                        backgroundColor: Colors.black.withOpacity(0.3),
                        selectedColor: Colors.amber,
                        labelStyle: TextStyle(
                          color: _appointmentFilter == filter ? Colors.black : Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAppointmentsStream(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsStream() {
    Query query = FirebaseFirestore.instance.collection('appointments').orderBy('time', descending: true);
    if (_appointmentFilter == 'Upcoming') {
      query = query.where('status', isEqualTo: 'upcoming');
    } else if (_appointmentFilter == 'Completed') {
      query = query.where('status', isEqualTo: 'completed');
    }

    if (_selectedBarber != 'All Barbers') {
      query = query.where('barberName', isEqualTo: _selectedBarber);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Something went wrong: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No appointments found for the selected filters.', style: TextStyle(color: Colors.white70)),
          );
        }

        final appointments = snapshot.data!.docs;

        return Column(
          children: appointments.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GlassContainer(
                child: ListTile(
                  title: Text(data['barberName'] ?? 'N/A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Client: ${data['clientName'] ?? 'N/A'}\nTime: ${data['time']?.toDate()?.toString() ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                  trailing: _buildAppointmentTrailing(doc.id, data),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentTrailing(String docId, Map<String, dynamic> data) {
    final status = data['status']?.toUpperCase() ?? 'N/A';
    Color statusColor;
    switch (data['status']) {
      case 'upcoming':
        statusColor = Colors.greenAccent;
        break;
      case 'completed':
        statusColor = Colors.grey;
        break;
      case 'cancelled':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.white70;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        if (data['status'] == 'upcoming')
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: Colors.grey[800],
            onSelected: (value) {
              if (value == 'cancel') {
                _confirmCancelAppointment(context, docId);
              } else if (value == 'complete') {
                _markAppointmentAsComplete(docId);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'complete',
                child: Text('Mark as Complete', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem<String>(
                value: 'cancel',
                child: Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong. Check permissions?', style: TextStyle(color: Colors.redAccent)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No users found.', style: TextStyle(color: Colors.white70)),
          );
        }

        final users = snapshot.data!.docs;
        final admins = users.where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'admin').toList();
        final barbers = users.where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'barber').toList();
        final clients = users.where((doc) {
          final role = (doc.data() as Map<String, dynamic>)['role'];
          return role == 'client' || role == null;
        }).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            if (admins.isNotEmpty) ..._buildUserSection('Admins', admins),
            if (barbers.isNotEmpty) ..._buildUserSection('Barbers', barbers),
            if (clients.isNotEmpty) ..._buildUserSection('Clients', clients),
          ],
        );
      },
    );
  }

  List<Widget> _buildUserSection(String title, List<QueryDocumentSnapshot> users) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFFFF8DC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '$title (${users.length})',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      ...users.map((doc) => _buildUserCard(doc)).toList(),
      const SizedBox(height: 10),
    ];
  }

  Widget _buildUserCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final uid = doc.id;
    final role = data['role'] ?? 'client';
    final username = data['username'] ?? 'No Name';
    final specialties = data['specialties'] ?? [];

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(data['email'] ?? 'No Email', style: const TextStyle(color: Colors.white70)),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              color: Colors.grey[800],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteUser(uid);
                } else if (value == 'manage_specialties') {
                  _showManageSpecialtiesDialog(context, uid, specialties);
                } else {
                  _updateUserRole(uid, value);
                }
              },
              itemBuilder: (BuildContext context) {
                List<PopupMenuEntry<String>> items = [
                  if (role != 'admin') const PopupMenuItem<String>(value: 'admin', child: Text('Make Admin', style: TextStyle(color: Colors.white))),
                  if (role != 'barber') const PopupMenuItem<String>(value: 'barber', child: Text('Make Barber', style: TextStyle(color: Colors.white))),
                  if (role != 'client') const PopupMenuItem<String>(value: 'client', child: Text('Make Client', style: TextStyle(color: Colors.white))),
                  const PopupMenuDivider(),
                  if (role == 'barber')
                    const PopupMenuItem<String>(
                      value: 'manage_specialties',
                      child: Text('Manage Specialties', style: TextStyle(color: Colors.white)),
                    ),
                  if (role == 'barber') const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete User', style: TextStyle(color: Colors.redAccent)),
                  ),
                ];
                return items;
              },
            ),
          ),
          if (role == 'barber' && specialties.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: (specialties as List).map<Widget>((specialty) {
                  return Chip(
                    label: Text(specialty),
                    backgroundColor: Colors.amber.withOpacity(0.7),
                    labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}