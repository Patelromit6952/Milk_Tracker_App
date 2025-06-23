import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milk_app/Screens/HomeScreen.dart';
import 'package:milk_app/Screens/admin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController(); // Added
bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isLogin = true;
  String selectedRole = 'user';

  Future<void> loginOrRegister(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    try {
      UserCredential userCredential;

      if (isLogin) {
        // 🔐 Login
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // 👤 Register
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final uid = userCredential.user!.uid;

        if (selectedRole == 'admin') {
          final adminCode = Random().nextInt(9000) + 1000;
          await FirebaseFirestore.instance.collection('admin').doc(uid).set({
            'email': email,
            'name': name,
            'role': 'admin',
            'admincode': adminCode.toString(),
          });
        } else {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'email': email,
            'name': name,
            'role': 'user',
          });
        }
      }

      final user = userCredential.user!;
      final roleDoc = selectedRole == 'admin'
          ? await FirebaseFirestore.instance.collection('admin').doc(user.uid).get()
          : await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      final role = roleDoc.data()?['role'];

      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHome()));
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserHome(
              userId: user.uid,
              email: user.email,
              name: roleDoc.data()?['name'] ?? 'User',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/milk.jpg', height: 200),
                const SizedBox(height: 16),
                Text(
                  isLogin ? 'Milk Tracker Login' : 'Register New Account',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email),
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.blue, fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.blue, fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                  value != null && value.length >= 6 ? null : 'Minimum 6 characters',
                ),

                // 👤 Name field (only for Register)
                if (!isLogin) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      labelText: 'Name',
                      labelStyle: const TextStyle(color: Colors.blue, fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    validator: (value) =>
                    value != null && value.trim().isNotEmpty ? null : 'Enter your name',
                  ),
                ],

                // 👥 Role selector (only for Register)
                if (!isLogin) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.blue),
                      const SizedBox(width: 10),
                      const Text('Register as:'),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                        value: selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedRole = value!);
                        },
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => loginOrRegister(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      isLogin ? 'Login' : 'Register',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
                        ? "Don't have an account? Register here"
                        : "Already have an account? Login here",
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
