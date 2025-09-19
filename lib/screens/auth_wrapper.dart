
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
        // If the connection is still loading, show a loading indicator.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If a user is logged in
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnapshot) {
              // If we are still waiting for the user's data, continue showing a loading indicator.
              // This is the key fix: We don't give up and return to LoginScreen immediately.
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If the user document exists, route them based on their role.
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
              
              // If the user document does NOT exist, but we are logged in, it means
              // the document is in the process of being created.
              // We should show a loading screen while we wait for the login flow to complete.
              if (userSnapshot.hasData && !userSnapshot.data!.exists) {
                 return const Scaffold(
                    body: Center(
                      // It is better to show a loading indicator here than to flash the login screen.
                      child: CircularProgressIndicator(),
                    ),
                  );
              }

              // If something went wrong (e.g., no data, but not waiting), default to login.
              return const LoginScreen();
            },
          );
        }

        // If no user is logged in, show the login screen.
        return const LoginScreen();
      },
    );
  }
}
