import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milk_app/Screens/AddEntry.dart';
import 'package:milk_app/Screens/admin_home.dart';
import 'package:milk_app/Screens/previous_entries.dart';
import 'package:milk_app/Screens/spalsh_screen.dart';
import 'Screens/HomeScreen.dart';
import 'Screens/login_screen.dart';

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
        '/adminHome': (context) => const AdminHome(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    // Try to get admin document
    final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(uid).get();
    if (adminDoc.exists) {
      final data = adminDoc.data();
      if (data != null) {
        data['role'] = 'admin'; // Tag explicitly
      }
      return data;
    }

    // Try to get user document
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        data['role'] = 'user'; // Tag explicitly
      }
      return data;
    }

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

        // User is not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.blue)),
              );
            }

            if (userSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text("Error loading profile")),
              );
            }

            final userData = userSnapshot.data;

            // No user data found in either collection
            if (userData == null) {
              return const Scaffold(
                body: Center(child: Text("User record not found")),
              );
            }

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
              return const Scaffold(body: Center(child: Text("Invalid role")));
            }
          },
        );
      },
    );
  }
}

