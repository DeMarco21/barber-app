import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'admin_dashboard.dart';
import 'barber_dashboard.dart';
import 'client_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isSignUp = false;
  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(User user) async {
    final profile = await AuthService().getUserProfile(user.uid);
    if (profile == null) return;

    switch (profile.role) {
      case 'admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
        break;
      case 'barber':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BarberDashboard()),
        );
        break;
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClientDashboard()),
        );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      User? user;
      if (isSignUp) {
        user = await AuthService().signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      } else {
        user = await AuthService().signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }

      if (user != null) {
        _handleLogin(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null) {
        _handleLogin(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            color: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSignUp ? "Create Account" : "Sign In",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isSignUp)
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Name",
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? "Enter your name" : null,
                      ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? "Enter your email" : null,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      validator: (value) =>
                      value!.length < 6 ? "Min 6 characters" : null,
                    ),

                    const SizedBox(height: 20),

                    isLoading
                        ? const CircularProgressIndicator(color: Colors.amber)
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isSignUp ? "Create Account" : "Sign In",
                        style:
                        const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        setState(() => isSignUp = !isSignUp);
                      },
                      child: Text(
                        isSignUp
                            ? "Already have an account? Sign In"
                            : "Don't have an account? Sign Up",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),

                    const Divider(color: Colors.white24, height: 32),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text("Sign in with Google"),
                      onPressed: _signInWithGoogle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


void _handleLogin(User user) async {
  final profile = await AuthService().getUserProfile(user.uid);
  if (profile == null) return;

  switch (profile.role) {
    case 'admin':
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      break;
    case 'barber':
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BarberDashboard()));
      break;
    default:
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClientDashboard()));
  }
}