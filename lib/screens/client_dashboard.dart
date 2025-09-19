import 'dart:ui';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:barber/screens/login_screen.dart';
import 'package:shimmer/shimmer.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _userName = 'User';
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _tabController = TabController(length: 2, vsync: this);

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
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      // First try display name
      if (_user!.displayName != null && _user!.displayName!.isNotEmpty) {
        if (mounted) setState(() => _userName = _user!.displayName!);
        return;
      }

      // Then try Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (mounted && doc.exists) {
        final data = doc.data();
        setState(() => _userName = data?['username'] ?? data?['name'] ?? _user!.email?.split('@')[0] ?? 'User');
      } else if (mounted) {
        // Fallback to email username part
        setState(() => _userName = _user!.email?.split('@')[0] ?? 'User');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _userName = _user!.email?.split('@')[0] ?? 'User');
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
    const darkCharcoal = Color(0xFF1A1A1A);

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
                              // Animated background elements instead of floating particles
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ParticlesPainter(_headerAnimation.value),
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
                                              Navigator.of(context).pushAndRemoveUntil(
                                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                                (Route<dynamic> route) => false,
                                              );
                                            },
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          padding: const EdgeInsets.all(4),
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.book_online_rounded, size: 18),
                                  SizedBox(width: 6),
                                  Text('Book'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.schedule_rounded, size: 18),
                                  SizedBox(width: 6),
                                  Text('Appointments'),
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
                  _buildBarberListPage(),
                  _buildAppointmentsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Booking Page: A professional list of barbers ---
  Widget _buildBarberListPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('barbers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }
        final barbers = snapshot.data!.docs;
        if (barbers.isEmpty) {
          return Center(
            child: _EmptyStateWidget(
              icon: Icons.content_cut_rounded,
              title: "No barbers available",
              subtitle: "Check back later for available barbers",
            ),
          );
        }
        return AnimatedBuilder(
          animation: _cardAnimation,
          builder: (context, child) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: barbers.length,
              itemBuilder: (context, index) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _cardAnimation.value)),
                  child: Opacity(
                    opacity: _cardAnimation.value,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      child: _ProfessionalBarberCard(
                        barberId: barbers[index].id,
                        name: (barbers[index].data() as Map<String, dynamic>)['fullName'] ?? 'N/A',
                        specialties: ((barbers[index].data() as Map<String, dynamic>)['specialties'] as List<dynamic>?)?.join(' • ') ?? 'Master Barber',
                        imageUrl: (barbers[index].data() as Map<String, dynamic>)['profileImageUrl'],
                        onBook: () => _showBookingSheet(
                          barbers[index].id,
                          (barbers[index].data() as Map<String, dynamic>)['fullName'] ?? 'N/A',
                        ),
                        index: index,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Appointments Page ---
  Widget _buildAppointmentsPage() {
    return CustomScrollView(
      slivers: [
        _buildSectionHeader('Upcoming'),
        _buildAppointmentsStream(
          FirebaseFirestore.instance
              .collection('appointments')
              .where('clientId', isEqualTo: _user!.uid)
              .where('status', isEqualTo: 'upcoming')
              .orderBy('time')
              .snapshots(),
          'You have no upcoming appointments.',
              (doc, data) =>
              _GlassAppointmentCard(doc: doc, data: data, isUpcoming: true),
        ),
        _buildSectionHeader('Past'),
        _buildAppointmentsStream(
          FirebaseFirestore.instance
              .collection('appointments')
              .where('clientId', isEqualTo: _user!.uid)
              .where('status', whereIn: ['completed', 'cancelled'])
              .orderBy('time', descending: true)
              .snapshots(),
          'You have no past appointments.',
              (doc, data) =>
              _GlassAppointmentCard(doc: doc, data: data, isUpcoming: false),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
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
              title,
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
    );
  }

  Widget _buildAppointmentsStream(
      Stream<QuerySnapshot> stream,
      String emptyMessage,
      Widget Function(DocumentSnapshot, Map<String, dynamic>) cardBuilder) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: _LoadingWidget(),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: _EmptyStateWidget(
                  icon: Icons.event_busy_rounded,
                  title: "No appointments",
                  subtitle: emptyMessage,
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final doc = snapshot.data!.docs[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutCubic,
                child: cardBuilder(doc, doc.data() as Map<String, dynamic>),
              );
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }

  // --- Booking Workflow ---
  void _showBookingSheet(String barberId, String barberName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          _BookingSheetContent(barberId: barberId, barberName: barberName),
    );
  }

  void confirmCancelAppointment(String appointmentId) {
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
                          child: _ModernButton(
                            text: 'Keep',
                            onPressed: () => Navigator.of(context).pop(),
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModernButton(
                            text: 'Cancel',
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('appointments')
                                  .doc(appointmentId)
                                  .update({'status': 'cancelled'});
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text(
                                    "Appointment Cancelled",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
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
}

// --- CUSTOM WIDGETS ---

// Custom painter for background particles
class _ParticlesPainter extends CustomPainter {
  final double animationValue;

  _ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw some simple animated dots
    final random = math.Random(42); // Fixed seed for consistent positions

    for (int i = 0; i < 15; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      final radius = (1 + random.nextDouble() * 2) * (0.5 + 0.5 * animationValue);
      final opacity = ((0.2 + 0.3 * math.sin(animationValue * 2 * math.pi + i)) * animationValue).clamp(0.0, 1.0);

      paint.color = const Color(0xFFD4AF37).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Floating particles for the header - simplified version
class _FloatingParticle extends StatefulWidget {
  final int delay;
  final double size;

  const _FloatingParticle({required this.delay, required this.size});

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 3000 + (widget.delay % 2000)),
      vsync: this,
    )..repeat();

    final random = math.Random(widget.delay);
    _animation = Tween<Offset>(
      begin: Offset(random.nextDouble() * 2 - 1, 1.5),
      end: Offset(random.nextDouble() * 2 - 1, -1.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _animation.value.dx * MediaQuery.of(context).size.width,
            _animation.value.dy * MediaQuery.of(context).size.height,
          ),
          child: Opacity(
            opacity: 0.6,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                color: Color(0xFFD4AF37),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFD4AF37),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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

// Enhanced Professional Barber Card
class _ProfessionalBarberCard extends StatefulWidget {
  final String barberId;
  final String name;
  final String specialties;
  final String? imageUrl;
  final VoidCallback onBook;
  final int index;

  const _ProfessionalBarberCard({
    required this.barberId,
    required this.name,
    required this.specialties,
    this.imageUrl,
    required this.onBook,
    required this.index,
  });

  @override
  State<_ProfessionalBarberCard> createState() => _ProfessionalBarberCardState();
}

class _ProfessionalBarberCardState extends State<_ProfessionalBarberCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

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
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _hoverAnimation.value,
          child: Container(
            margin: EdgeInsets.only(
              bottom: 20,
              top: widget.index == 0 ? 10 : 0,
            ),
            child: GestureDetector(
              onTapDown: (_) => _hoverController.forward(),
              onTapUp: (_) => _hoverController.reverse(),
              onTapCancel: () => _hoverController.reverse(),
              child: _GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD4AF37), Color(0xFFFFF8DC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white12,
                              backgroundImage: widget.imageUrl != null
                                  ? NetworkImage(widget.imageUrl!)
                                  : null,
                              child: widget.imageUrl == null
                                  ? const Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: Colors.white70,
                              )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.name,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFD4AF37).withOpacity(0.2),
                                        const Color(0xFFD4AF37).withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    widget.specialties,
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ShinyButton(
                        onPressed: widget.onBook,
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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

// Enhanced Shiny Button (keeping the original design)
class _ShinyButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const _ShinyButton({
    required this.child,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFFD4AF37), Color(0xFFE53935)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: Colors.transparent,
            period: const Duration(seconds: 4),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

// Glass Appointment Card
class _GlassAppointmentCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  final bool isUpcoming;

  const _GlassAppointmentCard({
    required this.doc,
    required this.data,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime time = (data['time'] as Timestamp).toDate();
    final String month = DateFormat('MMM').format(time).toUpperCase();
    final String day = DateFormat('d').format(time);
    final String timeOfDay = DateFormat('h:mm a').format(time);
    final status = data['status'] as String? ?? 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: _GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['barberName'] ?? 'N/A',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              ),
              const SizedBox(width: 16),
              if (isUpcoming)
                _ModernButton(
                  text: 'Cancel',
                  isPrimary: false,
                  color: Colors.redAccent,
                  onPressed: () {
                    (context as Element)
                        .findAncestorStateOfType<_ClientDashboardState>()!
                        .confirmCancelAppointment(doc.id);
                  },
                )
              else
                _StatusPill(status: status),
            ],
          ),
        ),
      ),
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
    switch (status) {
      case 'completed':
        pillColor = Colors.greenAccent;
        pillText = 'Completed';
        break;
      case 'cancelled':
        pillColor = Colors.redAccent;
        pillText = 'Cancelled';
        break;
      default:
        pillColor = Colors.grey;
        pillText = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: pillColor, width: 1.5),
      ),
      child: Text(
        pillText,
        style: GoogleFonts.inter(
          color: pillColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
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

// Full Booking Sheet Content
class _BookingSheetContent extends StatefulWidget {
  final String barberId;
  final String barberName;

  const _BookingSheetContent({
    required this.barberId,
    required this.barberName,
  });

  @override
  State<_BookingSheetContent> createState() => _BookingSheetContentState();
}

class _BookingSheetContentState extends State<_BookingSheetContent> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;

  final List<String> _timeSlots =
  List.generate(8, (i) => "${9 + i}:00 ${9 + i < 12 ? 'AM' : 'PM'}");

  void _confirmBooking() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select a date and time."),
          backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);

    final hour = int.parse(_selectedTimeSlot!.split(':')[0]);
    final finalDateTime = DateTime(_selectedDate!.year, _selectedDate!.month,
        _selectedDate!.day, hour);

    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final clientName = userData.data()?['username'] ?? 'Client';

    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'barberId': widget.barberId,
        'barberName': widget.barberName,
        'clientId': user.uid,
        'clientName': clientName,
        'time': Timestamp.fromDate(finalDateTime),
        'status': 'upcoming',
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Booking confirmed for $finalDateTime!"),
        backgroundColor: const Color(0xFFD4AF37),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking failed: $e"),
              backgroundColor: Colors.redAccent));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.book_online_rounded, color: Color(0xFFD4AF37), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Book with ${widget.barberName}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Select Date',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  onDateChanged: (date) => setState(() => _selectedDate = date),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Time',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final slot = _timeSlots[index];
                  final isSelected = _selectedTimeSlot == slot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeSlot = slot),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFFFF8DC)],
                        )
                            : null,
                        color: isSelected ? null : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          slot,
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32), // Added some padding below time slots before button
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : _ShinyButton(
              onPressed: _confirmBooking,
              child: Text(
                'Confirm Booking',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
