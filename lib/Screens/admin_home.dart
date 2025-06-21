import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milk_app/Screens/admin_profile.dart';
import 'package:milk_app/Screens/admin_user_screen.dart';
import 'package:milk_app/Screens/login_screen.dart';
import 'package:milk_app/Screens/user_profile.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  User? user = FirebaseAuth.instance.currentUser;
  late Future<List<Map<String, dynamic>>> usersFuture;
  @override
  void initState() {
    super.initState();
    usersFuture = fetchAllUsers();
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(user!.uid).get();

    if (!adminDoc.exists) {
      print("Admin document not found.");
      return [];
    }

    final adminData = adminDoc.data();
    if (adminData == null || !(adminData['users'] is List)) {
      print("No 'users' found  for  admin.");
      return [];
    }

    final List<dynamic> allowedUserNames = adminData['users']; // List of user names

    // If names list is empty, return empty list
    if (allowedUserNames.isEmpty) return [];

    // Fetch all users and filter by allowed names
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('name', whereIn: allowedUserNames)
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      appBar: AppBar(
        leading: GestureDetector(
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => AdminProfile()));
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[50],
              child: Icon(Icons.person,color: Colors.blue,),
            ),
          ),
        ),
        title: const Text('All Customers'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue,));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No users found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[700]),
                  ),
                  title: Text(
                    user['name']?.toString().toUpperCase() ?? 'NO NAME',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    user['email'] ?? 'No Email',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUserScreen(
                            userId: user['id'],
                            email: user['email'],
                            name:user['name']
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
