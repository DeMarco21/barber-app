import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_background/animated_background.dart';

import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'barber_dashboard.dart';
import 'client_dashboard.dart';
import '../widgets/logo_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();

    Timer(const Duration(seconds: 3), _checkAuthAndNavigate);
  }

  Future<void> _checkAuthAndNavigate() async {
    // Navigation logic remains the same
     try {
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user == null) {
        // No one logged in → go to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      // Logged in → fetch role from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = doc.data()?['role'] ?? 'client';

      if (!mounted) return;

      switch (role) {
        case 'admin':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const AdminDashboard(),
            ),
          );
          break;
        case 'barber':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BarberDashboard()),
          );
          break;
        default:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ClientDashboard()),
          );
      }
    } catch (e) {
      // If there's an error, default to the login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: const ParticleOptions(
            baseColor: Color(0xFFC98633), // Gold
            spawnOpacity: 0.0,
            opacityChangeRate: 0.25,
            minOpacity: 0.1,
            maxOpacity: 0.3,
            spawnMinSpeed: 30.0,
            spawnMaxSpeed: 70.0,
            spawnMinRadius: 2.0,
            spawnMaxRadius: 4.0,
            particleCount: 50,
          ),
        ),
        vsync: this,
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: ScaleTransition(
              scale: _animation,
              child: const LogoWidget(size: 120),
            ),
          ),
        ),
      ),
    );
  }
}
