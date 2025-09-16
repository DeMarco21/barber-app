import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BarberDashboard extends StatelessWidget {
  const BarberDashboard({super.key});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barber Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome, Barber!'),
      ),
    );
  }
}
