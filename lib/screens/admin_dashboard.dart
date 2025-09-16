
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_background/animated_background.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboard> with TickerProviderStateMixin {
  late Stream<QuerySnapshot> _usersStream;
  String _appointmentFilter = 'Upcoming';
  final List<String> _barbers = ['All Barbers'];
  String _selectedBarber = 'All Barbers';

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    _fetchBarbers();
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
          .collection('users')
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

  void _confirmCancelAppointment(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: _buildLiquidGoldTitle('Confirm Cancellation', 18),
          content: const Text('Are you sure you want to cancel this appointment?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelAppointment(docId);
              },
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showManageSpecialtiesDialog(BuildContext context, String uid, List<dynamic> currentSpecialties) {
    final TextEditingController specialtyController = TextEditingController();
    List<String> specialties = List<String>.from(currentSpecialties);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: _buildLiquidGoldTitle('Manage Specialties', 18),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            backgroundColor: Colors.amber,
                            labelStyle: const TextStyle(color: Colors.black),
                            deleteIconColor: Colors.black54,
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    _updateBarberSpecialties(uid, specialties);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.amber)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.black)),
      backgroundColor: Colors.amber,
    ));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.redAccent,
    ));
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: AnimatedBackground(
          behaviour: RandomParticleBehaviour(
            options: const ParticleOptions(
              baseColor: Color(0xFFFFD700),
              spawnOpacity: 0.0,
              opacityChangeRate: 0.25,
              minOpacity: 0.1,
              maxOpacity: 0.3,
              particleCount: 70,
              spawnMaxRadius: 3.0,
              spawnMinRadius: 1.0,
              spawnMaxSpeed: 50.0,
              spawnMinSpeed: 10.0,
            ),
          ),
          vsync: this,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.amber),
                      onPressed: _signOut,
                      tooltip: 'Sign Out',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: _buildLiquidGoldTitle('Admin Command', 20),
                    titlePadding: const EdgeInsets.only(bottom: 55.0),
                    centerTitle: true,
                  ),
                  bottom: TabBar(
                    indicatorColor: Colors.amber,
                    labelStyle: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Appointments'),
                      Tab(text: 'User Management'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _buildAppointmentsTab(),
                _buildUsersTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGoldTitle(String text, double fontSize) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFF7D780), Color(0xFFC9A24C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.cinzel(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
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
        Expanded(child: _buildAppointmentsStream()),
      ],
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
      query = query.where('barber', isEqualTo: _selectedBarber);
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

        return ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final doc = appointments[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildGlassCard(
              child: ListTile(
                title: Text(data['barber'] ?? 'N/A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('''Client: ${data['client'] ?? 'N/A'}\nTime: ${data['time'] ?? 'N/A'}''', style: const TextStyle(color: Colors.white70)),
                trailing: _buildAppointmentTrailing(doc.id, data),
              ),
            );
          },
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
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
      stream: _usersStream,
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: _buildLiquidGoldTitle('$title (${users.length})', 18),
      ),
      ...users.map((doc) => _buildUserCard(doc)).toList(),
      const SizedBox(height: 10),
    ];
  }

  Widget _buildUserCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final uid = doc.id;
    final role = data['role'] ?? 'client';
    final specialties = data['specialties'] ?? [];

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(data['username'] ?? 'No Name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildGlassCard({required Widget child}) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: child,
    );
  }
}
