import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

// The main widget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLoginView = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginView) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'client',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // AuthWrapper will handle navigation
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      final userDoc = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        String username = googleUser.displayName?.split(' ').first ?? 'User';
        await userDoc.set({
          'username': username,
          'email': googleUser.email,
          'role': 'client',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // AuthWrapper will handle navigation
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                _buildLogo(),
                const SizedBox(height: 20),
                _buildTitle(),
                const SizedBox(height: 50),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _isLoginView ? const SizedBox.shrink() : _buildUsernameField(),
                ),
                if (!_isLoginView) const SizedBox(height: 20),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 15),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 40),
                _isLoading ? _buildLoadingIndicator() : _buildSubmitButton(),
                const SizedBox(height: 25),
                _isLoading ? const SizedBox.shrink() : _buildGoogleSignInButton(),
                const SizedBox(height: 30),
                _isLoading ? const SizedBox.shrink() : _buildAuthSwitchButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Icon(
      Icons.content_cut_rounded, // Example logo
      size: 80,
      color: Colors.amber,
      shadows: [
        Shadow(
          color: Colors.amber.withOpacity(0.8),
          blurRadius: 15,
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF4500)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'TrimCraft',
        textAlign: TextAlign.center,
        style: GoogleFonts.cinzel(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: _inputDecoration('Username', Icons.person_outline_rounded),
      style: const TextStyle(color: Colors.white),
      validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: _inputDecoration('Email', Icons.alternate_email_rounded),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value!.isEmpty) return 'Please enter an email';
        if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: _inputDecoration('Password', Icons.lock_outline_rounded),
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value!.isEmpty) return 'Please enter a password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      textInputAction: _isLoginView ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) => _isLoading ? null : _submitForm(),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.6),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              ),
              BoxShadow(
                color: const Color(0xFFFF4500).withOpacity(0.4),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero, // Remove padding from the button itself
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              backgroundColor: Colors.transparent, // Important for gradient
              shadowColor: Colors.transparent,
            ).copyWith(
              elevation: MaterialStateProperty.all(0),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFF4500)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20), // Apply padding here
                alignment: Alignment.center,
                child: Text(
                  _isLoginView ? 'SIGN IN' : 'SIGN UP',
                  style: GoogleFonts.lato(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoogleSignInButton() {
    return OutlinedButton.icon(
      onPressed: _signInWithGoogle,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.amber, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 18),
      label: Text(
        'Continue with Google',
        style: GoogleFonts.lato(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
  
  Widget _buildAuthSwitchButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLoginView = !_isLoginView;
          _errorMessage = null;
          _formKey.currentState?.reset();
          _emailController.clear();
          _passwordController.clear();
          _usernameController.clear();
        });
      },
      child: Text(
        _isLoginView ? "Don't have an account? Sign Up" : "Have an account? Login",
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.amber, size: 20),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.amber),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
