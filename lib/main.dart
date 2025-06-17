import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milk_app/Screens/AddEntry.dart';
import 'package:milk_app/Screens/add_user_screen.dart';
import 'package:milk_app/Screens/admin_home.dart';
import 'package:milk_app/Screens/previous_entries.dart';
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
      home: const AuthGate(),
      routes: {
        '/add-entry': (_) => const AddEntryScreen(),
        '/previous-entries': (_) => const PreviousEntriesScreen(),
        '/add-customer': (context) => const AddUserScreen(),
        '/adminHome': (context) => const AdminHome(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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

        // User is NOT logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // User is logged in
        final user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.blue)),
              );
            }

            if (userSnapshot.hasError) {
              print("Firestore user fetch error: ${userSnapshot.error}");

              return const Scaffold(
                body: Center(child: Text("Something went wrong while fetching user data")),
              );
            }

            final doc = userSnapshot.data;

            if (doc == null || !doc.exists) {
              // Auto-create user document if missing
              FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'name': user.displayName ?? '',
                'email': user.email ?? '',
                'role': 'user', // default role, change if needed
              });

              return const Scaffold(
                body: Center(child: Text("Creating user profile... Please restart the app.")),
              );
            }

            final userData = doc.data() as Map<String, dynamic>?;

            final role = userData?['role'];

            if (role == 'admin') {
              return const AdminHome();
            } else if (role == 'user') {
              return UserHome(
                userId: user.uid,
                email: user.email,
                name: userData?['name'] ?? 'User',
              );
            } else {
              return const Scaffold(body: Center(child: Text("Invalid role in profile")));
            }
          },
        );
      },
    );
  }
}
