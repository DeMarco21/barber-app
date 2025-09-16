
import 'package:barber/screens/admin_dashboard.dart';
import 'package:barber/screens/barber_dashboard.dart';
import 'package:barber/screens/client_dashboard.dart';
import 'package:barber/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userRole = userSnapshot.data!.get('role');
                switch (userRole) {
                  case 'admin':
                    return const AdminDashboard();
                  case 'barber':
                    return const BarberDashboard();
                  default:
                    return const ClientDashboard();
                }
              }

              return const LoginScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
