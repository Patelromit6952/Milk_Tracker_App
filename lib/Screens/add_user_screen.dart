import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String role = 'user'; // Default role
  bool isLoading = false;

  Future<void> addUser() async {
    try {
      setState(() => isLoading = true);

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: name + '123');

      String newUserId = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(newUserId).set({
        'name': name,
        'email': email,
        'role': role,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully')),
      );
      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Add New User'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.person_add, size: 60, color: Colors.blue[700]),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                        labelStyle: TextStyle(
                          color: Colors.black, // 👈 label text color
                          fontSize: 14,
                        ),
                      prefixIcon: const Icon(Icons.person,color: Colors.blue,),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue), // on focus
                        )
                    ),
                    onChanged: (val) => name = val,
                    validator: (val) => val!.isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                        labelStyle: TextStyle(
                          color: Colors.black, // 👈 label text color
                          fontSize: 14,
                        ),
                      prefixIcon: const Icon(Icons.email,color: Colors.blue,),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue), // on focus
                        )
                    ),
                    onChanged: (val) => email = val,
                    validator: (val) => val!.isEmpty ? 'Please enter an email' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      labelStyle: TextStyle(
                        color: Colors.black, // 👈 label text color
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.security,color: Colors.blue,),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue), // on focus
                        )
                    ),
                    items: ['user', 'admin']
                        .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r[0].toUpperCase() + r.substring(1)),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => role = val!),
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.blue,)
                      : ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        addUser();
                      }
                    },
                    icon: const Icon(Icons.save,color: Colors.white,),
                    label: const Text('Create User',style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
