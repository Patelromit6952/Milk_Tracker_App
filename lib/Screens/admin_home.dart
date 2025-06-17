import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:milk_app/Screens/HomeScreen.dart';
import 'package:milk_app/Screens/add_user_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  User? user = FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    fetchAllUsers();
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: "user")
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
        title: const Text('All Customers'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                        builder: (_) => UserHome(
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

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[600],
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Add Customer",style: TextStyle(color: Colors.white),),
        onPressed: () async {
          final result = await Navigator.push(context,MaterialPageRoute(builder: (_) => const AddUserScreen()),);
          if (result == true) {
            setState(() {}); // Refresh the user list
          }
        },

      ),
    );
  }
}
