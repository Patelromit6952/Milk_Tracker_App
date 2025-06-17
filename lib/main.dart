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
      // home: LoginScreen(),
      routes: {
        '/add-entry': (_) => const AddEntryScreen(),
        '/previous-entries': (_) => const PreviousEntriesScreen(),
        '/add-customer': (context) => const AddUserScreen(),
      },// Handles auto-login
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
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blue,)));
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blue,)));
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Scaffold(body: Center(child: Text("User data not found")));
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              final role = userData?['role'];

              if (role == 'admin') {
                return AdminHome();
              } else if (role == 'user') {
                return UserHome(userId: user.uid, email: user.email,name:userData?['name']);
              } else {
                return const Scaffold(body: Center(child: Text("Invalid role")));
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}


