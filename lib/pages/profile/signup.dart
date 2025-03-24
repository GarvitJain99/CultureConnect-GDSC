import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cultureconnect/pages/profile/signin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zxcvbn/zxcvbn.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String? passwordMatchError;
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  final zxcvbn = Zxcvbn();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    passwordController.addListener(_validatePasswordMatch);
    confirmPasswordController.addListener(_validatePasswordMatch);
  }

  void _validatePasswordMatch() {
    if (confirmPasswordController.text.isNotEmpty &&
        passwordController.text != confirmPasswordController.text) {
      setState(() {
        passwordMatchError = "Passwords do not match.";
      });
    } else {
      setState(() {
        passwordMatchError = null;
      });
    }
  }

  void signUp() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please fill in all the fields'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        passwordMatchError = "Passwords do not match.";
      });
      return;
    }

    setState(() => isLoading = true);
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'status': 'New User',
          'about': '',
          'location': '',
          'profileImage': '',
        });

        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'A verification email has been sent to your email address. Please check your inbox and spam folder to verify your account.'),
          ),
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => const SignInScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'An error occurred during sign up: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _getPasswordStrengthLabel(double score) {
    if (score <= 1.0) {
      return "Very Weak";
    } else if (score <= 2.0) {
      return "Weak";
    } else if (score <= 3.0) {
      return "Fair";
    } else {
      return "Strong";
    }
  }

  Color _getPasswordStrengthColor(double score) {
    if (score <= 1.0) {
      return const Color.fromARGB(255, 255, 17, 0);
    } else if (score <= 2.0) {
      return Colors.orange;
    } else if (score <= 3.0) {
      return const Color.fromARGB(255, 243, 222, 34);
    } else {
      return const Color.fromARGB(255, 20, 227, 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFFFA726)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField("Name", nameController, false),
                const SizedBox(height: 16),
                _buildTextField("Email", emailController, false),
                const SizedBox(height: 16),
                _buildPasswordField(
                    "Password",
                    passwordController,
                    () =>
                        setState(() => isPasswordVisible = !isPasswordVisible),
                    isPasswordVisible),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: passwordController,
                      builder: (context, value, child) {
                        final passwordText = value.text;
                        if (passwordText.isNotEmpty) {
                          final strength = zxcvbn.evaluate(passwordText);
                          final strengthLabel = _getPasswordStrengthLabel(
                              strength.score!.toDouble());
                          final strengthColor = _getPasswordStrengthColor(
                              strength.score!.toDouble());
                          return Text(
                            'Password Strength: $strengthLabel',
                            style:
                                TextStyle(color: strengthColor, fontSize: 12),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                    "Confirm Password",
                    confirmPasswordController,
                    () => setState(() =>
                        isConfirmPasswordVisible = !isConfirmPasswordVisible),
                    isConfirmPasswordVisible),
                if (passwordMatchError != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        passwordMatchError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                        ),
                      )
                    ),
                  ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: signUp,
                        style: _buttonStyle(),
                        child: const Text("Sign Up"),
                      ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignInScreen()),
                  ),
                  child: const Text(
                    "Already have an account? Sign In",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      VoidCallback toggleVisibility, bool isVisible) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.deepOrange,
      padding: const EdgeInsets.all(13),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 10,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    passwordController.removeListener(_validatePasswordMatch);
    confirmPasswordController.removeListener(_validatePasswordMatch);
    super.dispose();
  }
}
