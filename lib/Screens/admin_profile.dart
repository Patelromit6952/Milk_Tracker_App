import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfile();
}

class _AdminProfile extends State<AdminProfile> {
  String name = '';
  String email = '';
  String role = '';
  String sellerCode = '';
  String message = '';
  bool isLoading = true;
  bool isConnecting = false;

  final TextEditingController sellerCodeController = TextEditingController();

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    print("Fetching data for UID: ${user?.uid}");

    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('admin').doc(user.uid).get();

      if (!userDoc.exists) {
        setState(() {
          message = "Admin profile not found";
          isLoading = false;
        });
        return;
      }

      final data = userDoc.data();

      setState(() {
        name = data?['name'] ?? '';
        email = data?['email'] ?? user.email ?? user.phoneNumber ?? '';
        role = data?['role'] ?? 'admin';
        sellerCode = data?['admincode'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        message = "Failed to load profile.";
        isLoading = false;
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: Colors.blue,
        title: Text('Profile',style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue,))
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Email: $email', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('Role: ${role.toUpperCase()}', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('SellerCode: ${sellerCode}'),
            Divider(),

            // if (role == 'user' && !sellerName) ...[
            //   const SizedBox(height: 10),
            //   Text('Connect to Your Seller', style: TextStyle(fontWeight: FontWeight.bold)),
            //   const SizedBox(height: 8),
            //   TextField(
            //     controller: sellerCodeController,
            //     keyboardType: TextInputType.number,
            //     maxLength: 4,
            //     decoration: InputDecoration(
            //       hintText: 'Enter 4-digit seller code',
            //       border: OutlineInputBorder(),
            //       focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
            //       counterText: '',
            //     ),
            //   ),
            //   const SizedBox(height: 10),
            //   ElevatedButton(
            //     onPressed: isConnecting ? null : connectToSeller,
            //     child: Text('Connect',style: TextStyle(color: Colors.blue),),
            //   ),
            //   if (message.isNotEmpty)
            //     Padding(
            //       padding: const EdgeInsets.all(8.0),
            //       child: Text(
            //         message,
            //         style: TextStyle(
            //           color: message.contains('✅') ? Colors.green : Colors.red,
            //         ),
            //       ),
            //     ),
            // ],
          ],
        ),
      ),
    );
  }
}
