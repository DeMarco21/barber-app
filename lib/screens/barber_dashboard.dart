import 'dart:ui';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barber/widgets/particles_painter.dart';
import 'package:barber/screens/login_screen.dart'; // Added import

class BarberDashboard extends StatefulWidget {
  const BarberDashboard({super.key});

  @override
  State<BarberDashboard> createState() => _BarberDashboardState();
}

class _BarberDashboardState extends State<BarberDashboard>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _userName = 'Barber';
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;

  DateTime _selectedDate = DateTime.now();
  int _todayAppointments = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _tabController = TabController(length: 3, vsync: this);

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutCubic),
    );
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.elasticOut),
    );

    _loadUserData();
    _loadTodayAppointments();
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      if (_user!.displayName != null && _user!.displayName!.isNotEmpty) {
        if (mounted) setState(() => _userName = _user!.displayName!);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(_user!.uid)
          .get();

      if (mounted && doc.exists) {
        final data = doc.data();
        setState(() => _userName = data?['username'] ?? data?['name'] ?? _user!.email?.split('@')[0] ?? 'Barber');
      } else if (mounted) {
        setState(() => _userName = _user!.email?.split('@')[0] ?? 'Barber');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _userName = _user!.email?.split('@')[0] ?? 'Barber');
      }
    }
  }

  Future<void> _loadTodayAppointments() async {
    if (_user == null) return;

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: _user!.uid)
          .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('time', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      if (mounted) {
        setState(() => _todayAppointments = snapshot.docs.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _todayAppointments = 0);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
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
              Color(0xFF2A1810),
              Color(0xFF1A1A2E),
              Color(0xFF000000),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 380.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _headerAnimation.value)),
                    child: Opacity(
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
                              // Animated background elements
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: ParticlesPainter(_headerAnimation.value),
                                ),
                              ),
                              SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with greeting and logout
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                ShaderMask(
                                                  shaderCallback: (bounds) => const LinearGradient(
                                                    colors: [Colors.white70, Colors.white38],
                                                  ).createShader(bounds),
                                                  child: Text(
                                                    _getGreeting(),
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w300,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                ShaderMask(
                                                  shaderCallback: (bounds) => const LinearGradient(
                                                    colors: [goldColor, Color(0xFFFFF8DC)],
                                                  ).createShader(bounds),
                                                  child: Text(
                                                    _userName,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 28,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: -0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          _GlowingIconButton(
                                            icon: Icons.logout_rounded,
                                            onPressed: () async {
                                              await _auth.signOut();
                                              if (!mounted) return; // Check if the widget is still in the tree
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                                (Route<dynamic> route) => false,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      // Stats Cards
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _StatsCard(
                                              icon: Icons.today_rounded,
                                              title: 'Today',
                                              value: _todayAppointments.toString(),
                                              subtitle: 'Appointments',
                                              color: goldColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _StatsCard(
                                              icon: Icons.calendar_month_rounded,
                                              title: 'Date',
                                              value: DateFormat('MMM dd').format(_selectedDate),
                                              subtitle: DateFormat('yyyy').format(_selectedDate),
                                              color: const Color(0xFF6366F1),
                                              onTap: _showDatePicker,
                                            ),
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
                    ),
                  );
                },
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: TabBar(
                          controller: _tabController,
                          indicator: _ModernTabIndicator(),
                          labelColor: goldColor,
                          unselectedLabelColor: Colors.white60,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          padding: const EdgeInsets.all(4),
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.today_rounded, size: 16),
                                  SizedBox(width: 4),
                                  Text('Today'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.schedule_rounded, size: 16),
                                  SizedBox(width: 4),
                                  Text('All'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_rounded, size: 16),
                                  SizedBox(width: 4),
                                  Text('History'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              child: _user == null
                  ? const Center(child: CircularProgressIndicator(color: goldColor))
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildTodayAppointments(),
                  _buildAllAppointments(),
                  _buildHistoryAppointments(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Today's appointments
  Widget _buildTodayAppointments() {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: _user!.uid)
          .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('time', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('time')
          .snapshots(),
      builder: (context, snapshot) {
        return _buildAppointmentsList(
          snapshot,
          'No appointments for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
          'Your schedule is clear for this day',
          true,
        );
      },
    );
  }

  // All appointments
  Widget _buildAllAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: _user!.uid)
          .where('status', isEqualTo: 'upcoming')
          .orderBy('time')
          .snapshots(),
      builder: (context, snapshot) {
        return _buildAppointmentsList(
          snapshot,
          'No upcoming appointments',
          'All your upcoming bookings will appear here',
          true,
        );
      },
    );
  }

  // History appointments
  Widget _buildHistoryAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: _user!.uid)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        return _buildAppointmentsList(
          snapshot,
          'No appointment history',
          'Your past appointments will appear here',
          false,
        );
      },
    );
  }

  Widget _buildAppointmentsList(
      AsyncSnapshot<QuerySnapshot> snapshot,
      String emptyTitle,
      String emptySubtitle,
      bool isUpcoming,
      ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _LoadingWidget(),
        ),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _EmptyStateWidget(
            icon: isUpcoming ? Icons.event_available_rounded : Icons.history_rounded,
            title: emptyTitle,
            subtitle: emptySubtitle,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final DateTime appointmentTime = (data['time'] as Timestamp).toDate(); // Extract appointmentTime

            return Transform.translate(
              offset: Offset(0, 50 * (1 - _cardAnimation.value)),
              child: Opacity(
                opacity: _cardAnimation.value,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  child: _BarberAppointmentCard(
                    doc: doc,
                    data: data,
                    isUpcoming: isUpcoming,
                    index: index,
                    appointmentTime: appointmentTime, // Pass appointmentTime
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadTodayAppointments();
    }
  }

  void _markAppointmentComplete(String appointmentId) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            content: _GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFFD4AF37),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mark as Complete',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mark this appointment as completed?',
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
                          child: _ModernButton(
                            text: 'Cancel',
                            onPressed: () => Navigator.of(context).pop(),
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModernButton(
                            text: 'Complete',
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('appointments')
                                  .doc(appointmentId)
                                  .update({'status': 'completed'});
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text(
                                    "Appointment Completed",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                            isPrimary: true,
                            color: Colors.green,
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

  Future<void> _cancelAppointment(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).update({'status': 'cancelled'});
      _showSuccessSnackBar('Appointment cancelled.');
    } catch (e) {
      _showErrorSnackBar('Failed to cancel appointment: $e');
    }
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

  void _confirmCancelAppointment(BuildContext dialogContext, String docId) { // Changed context name to avoid conflict
    showDialog(
      context: dialogContext, // Use the passed-in context
      barrierColor: Colors.black87,
      builder: (BuildContext alertContext) { // Use a different name for AlertDialog context
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            content: _GlassContainer( // Use _GlassContainer here
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
                          child: _ModernButton( // Use _ModernButton here
                            text: 'No',
                            onPressed: () => Navigator.of(alertContext).pop(), // Use alertContext
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModernButton( // Use _ModernButton here
                            text: 'Yes, Cancel',
                            onPressed: () {
                              Navigator.of(alertContext).pop(); // Use alertContext
                              _cancelAppointment(docId);
                            },
                            isPrimary: true,
                            color: Colors.redAccent,
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
} // <<<< THIS IS THE MISSING BRACE I'VE ADDED

// --- CUSTOM WIDGETS ---

// Glowing icon button
class _GlowingIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlowingIconButton({required this.icon, required this.onPressed});

  @override
  State<_GlowingIconButton> createState() => _GlowingIconButtonState();
}

class _GlowingIconButtonState extends State<_GlowingIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(_glowAnimation.value * 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: widget.onPressed,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.3),
                      const Color(0xFFD4AF37).withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFFD4AF37),
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Stats Card
class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _StatsCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.5), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(Icons.touch_app_rounded, color: Colors.white30, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern tab indicator
class _ModernTabIndicator extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _ModernTabPainter(this, onChanged);
  }
}

class _ModernTabPainter extends BoxPainter {
  final _ModernTabIndicator decoration;

  _ModernTabPainter(this.decoration, VoidCallback? onChanged)
      : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    final rect = offset & configuration.size!;

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFFFF8DC)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rect.left + 8,
        rect.top + 8,
        rect.right - 8,
        rect.bottom - 8,
      ),
      const Radius.circular(26),
    );

    canvas.drawRRect(rrect, paint);
  }
}

// Enhanced Glass Container
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;

  const _GlassContainer({
    required this.child,
    this.padding,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
                Colors.black.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Barber Appointment Card
class _BarberAppointmentCard extends StatefulWidget {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  final bool isUpcoming;
  final int index;
  final DateTime appointmentTime; // New parameter

  const _BarberAppointmentCard({
    required this.doc,
    required this.data,
    required this.isUpcoming,
    required this.index,
    required this.appointmentTime, // New parameter
  });

  @override
  State<_BarberAppointmentCard> createState() => _BarberAppointmentCardState();
}

class _BarberAppointmentCardState extends State<_BarberAppointmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  String _clientName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _loadClientName();
  }

  Future<void> _loadClientName() async {
    final clientId = widget.data['clientId'] as String?;
    if (clientId == null) {
      if (mounted) {
        setState(() => _clientName = widget.data['clientName'] ?? 'Unknown Client');
      }
      return;
    }

    try {
      // Try to get from users collection first
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          final userData = userDoc.data();
          setState(() => _clientName = userData?['username'] ?? userData?['name'] ?? widget.data['clientName'] ?? 'Client');
        } else {
          // Fallback to stored client name
          setState(() => _clientName = widget.data['clientName'] ?? 'Client');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _clientName = widget.data['clientName'] ?? 'Client');
      }
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime time = (widget.data['time'] as Timestamp).toDate();
    final String month = DateFormat('MMM').format(time).toUpperCase();
    final String day = DateFormat('d').format(time);
    final String timeOfDay = DateFormat('h:mm a').format(time);
    final String status = widget.data['status'] as String? ?? 'upcoming';

    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _hoverAnimation.value,
          child: Container(
            margin: EdgeInsets.only(
              bottom: 16,
              top: widget.index == 0 ? 8 : 0,
            ),
            child: GestureDetector(
              onTapDown: (_) => _hoverController.forward(),
              onTapUp: (_) => _hoverController.reverse(),
              onTapCancel: () => _hoverController.reverse(),
              child: _GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Date Container
                      Container(
                        width: 70,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD4AF37).withOpacity(0.3),
                              const Color(0xFFD4AF37).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              month,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              day,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Client Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  color: const Color(0xFFD4AF37),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _clientName,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeOfDay,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Action Button or Status
                      Builder(
                        builder: (BuildContext dialogContext) { // Renamed context
                          if (widget.isUpcoming) {
                            final bool isToday = DateUtils.isSameDay(widget.appointmentTime, DateTime.now());
                            if (isToday) {
                              // Today's appointments: Complete and Cancel
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ModernButton(
                                    text: 'Complete',
                                    isPrimary: true,
                                    color: Colors.green,
                                    onPressed: () {
                                      (dialogContext as Element) // Use renamed context
                                          .findAncestorStateOfType<_BarberDashboardState>()!
                                          ._markAppointmentComplete(widget.doc.id);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _ModernButton(
                                    text: 'Cancel',
                                    isPrimary: false,
                                    color: Colors.redAccent,
                                    onPressed: () {
                                      (dialogContext as Element) // Use renamed context
                                          .findAncestorStateOfType<_BarberDashboardState>()!
                                          ._confirmCancelAppointment(dialogContext, widget.doc.id); // Pass renamed context
                                    },
                                  ),
                                ],
                              );
                            } else {
                              // Future appointments: Only Cancel
                              return _ModernButton(
                                text: 'Cancel',
                                isPrimary: false,
                                color: Colors.redAccent,
                                onPressed: () {
                                  (dialogContext as Element) // Use renamed context
                                      .findAncestorStateOfType<_BarberDashboardState>()!
                                      ._confirmCancelAppointment(dialogContext, widget.doc.id); // Pass renamed context
                                },
                              );
                            }
                          } else {
                            // Past appointments: Status Pill
                            return _StatusPill(status: status);
                          }
                        },
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
  }
}

// Status Pill for past appointments
class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color pillColor;
    String pillText;
    IconData icon;

    switch (status) {
      case 'completed':
        pillColor = Colors.greenAccent;
        pillText = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        pillColor = Colors.redAccent;
        pillText = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      case 'upcoming':
        pillColor = const Color(0xFFD4AF37);
        pillText = 'Upcoming';
        icon = Icons.schedule_rounded;
        break;
      default:
        pillColor = Colors.grey;
        pillText = status.toUpperCase();
        icon = Icons.help_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pillColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pillColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: pillColor, size: 14),
          const SizedBox(width: 4),
          Text(
            pillText,
            style: GoogleFonts.inter(
              color: pillColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Button
class _ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? color;

  const _ModernButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? const Color(0xFFD4AF37);

    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
          colors: [buttonColor, buttonColor.withOpacity(0.7)],
        )
            : null,
        color: isPrimary ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: buttonColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: isPrimary ? Colors.white : buttonColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Loading Widget
class _LoadingWidget extends StatefulWidget {
  @override
  State<_LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<_LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const SweepGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFD4AF37),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Empty State Widget
class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withOpacity(0.2),
                const Color(0xFFD4AF37).withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 40,
            color: const Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
