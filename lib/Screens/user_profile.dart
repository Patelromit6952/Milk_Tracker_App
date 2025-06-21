import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfile();
}

class _UserProfile extends State<UserProfile> {
  String name = '';
  String email = '';
  String role = '';
  bool sellerName = false;
  String sellerCode = '';
  String message = '';
  bool isLoading = true;
  bool isConnecting = false;

  final TextEditingController sellerCodeController = TextEditingController();

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = userDoc.data();
    print(data);
    if (data != null) {
      setState(() {
        name = data['name'] ?? '';
        email = data['email'] ?? user.phoneNumber ?? '';
        role = data['role'] ?? 'user';
        sellerName = data['connectedSellerId'] != null  ? true : false;
        isLoading = false;
      });
    }
  }

  Future<void> connectToSeller() async {
    final code = sellerCodeController.text.trim();
    if (code.length != 4) {
      setState(() => message = 'Please enter a 4-digit seller code.');
      return;
    }

    setState(() {
      isConnecting = true;
      message = '';
    });

    try {
      // Step 1: Find the matching admin in `admin` collection
      final query = await FirebaseFirestore.instance
          .collection('admin')
          .where('admincode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => message = ' No seller found with that code.');
        return;
      }

      final adminDoc = query.docs.first;
      final adminId = adminDoc.id;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user name (already fetched above)
      final userName = name;

      // Step 2: Update current user's document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'connectedSellerId': adminId,
      });

      // Step 3: Add user name to the admin's users array
      await FirebaseFirestore.instance.collection('admin').doc(adminId).update({
        'users': FieldValue.arrayUnion([userName])
      });

      setState(() => message = ' Connected to seller successfully!');
    } catch (e) {
      setState(() => message = ' Failed To Connect Seller');
    } finally {
      setState(() => isConnecting = false);
    }
  }


  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    sellerCodeController.dispose();
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
            Text('Seller: ${sellerName ? "You are Connected to Seller" : "You are not Connected to Any seller"}'),
            Divider(),

            if (role == 'user' && !sellerName) ...[
              const SizedBox(height: 10),
              Text('Connect to Your Seller', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: sellerCodeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit seller code',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isConnecting ? null : connectToSeller,
                child: Text('Connect',style: TextStyle(color: Colors.blue),),
              ),
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: message.contains('✅') ? Colors.green : Colors.red,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
