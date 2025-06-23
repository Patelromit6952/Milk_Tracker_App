import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milk_app/Screens/spalsh_screen.dart';

import 'Screens/HomeScreen.dart';
import 'Screens/login_screen.dart';
import 'Screens/admin_home.dart';
import 'Screens/AddEntry.dart';
import 'Screens/previous_entries.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Milk Tracker',
      theme: ThemeData(primarySwatch: Colors.green),
      home: SplashScreen(),
      routes: {
        '/add-entry': (_) => const AddEntryScreen(),
        '/previous-entries': (_) => const PreviousEntriesScreen(),
        '/adminHome': (_) => const AdminHome(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> _getUserData(User firebaseUser) async {
    final uid = firebaseUser.uid;

    // Check admin collection
    final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(uid).get();
    if (adminDoc.exists) {
      final data = adminDoc.data()!..['role'] = 'admin';
      return data;
    }

    // Check users collection
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!..['role'] = 'user';
      return data;
    }

    // User not found in either collection
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(user),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.blue)),
              );
            }

            if (userSnapshot.hasError || userSnapshot.data == null) {
              return const Scaffold(
                body: Center(child: Text("User profile not found or unauthorized.")),
              );
            }

            final userData = userSnapshot.data!;
            final role = userData['role'];

            if (role == 'admin') {
              return const AdminHome();
            } else if (role == 'user') {
              return UserHome(
                userId: user.uid,
                email: user.email,
                name: userData['name'] ?? 'User',
              );
            } else {
              return const Scaffold(
                body: Center(child: Text("Invalid user role.")),
              );
            }
          },
        );
      },
    );
  }
}
