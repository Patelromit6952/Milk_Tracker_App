import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milk_app/Screens/login_screen.dart';
import 'package:milk_app/Screens/previous_entries.dart';
import 'package:milk_app/Screens/user_profile.dart';

class UserHome extends StatefulWidget {
  final String userId;
  final String? email;
  final String? name;

  const UserHome({
    super.key,
    required this.userId,
    this.email,
    this.name,
  });

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late Future<List<Map<String, dynamic>>> _entriesFuture;
  double totalMilk = 0.0;
  double totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _entriesFuture = fetchCurrentMonthEntries();
  }

  String formatDate(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return DateFormat('dd-MM-yyyy').format(dt);
  }

  Future<List<Map<String, dynamic>>> fetchCurrentMonthEntries() async {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');

    final daysCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('milk_data')
        .doc(year)
        .collection('months')
        .doc(month)
        .collection('days');

    final daysSnapshot = await daysCollection.get();
    List<Map<String, dynamic>> allEntries = [];

    totalMilk = 0.0;
    totalSpent = 0.0;

    for (var dayDoc in daysSnapshot.docs) {
      final data = dayDoc.data();
      allEntries.add(data);

      double q = (data['quantity'] ?? 0).toDouble();
      double p = (data['price'] ?? 0).toDouble();
      totalMilk += q;
      totalSpent += q * p;
    }

    allEntries.sort((a, b) {
      final aDate = a['date'];
      final bDate = b['date'];
      if (aDate is Timestamp && bDate is Timestamp) {
        return bDate.compareTo(aDate);
      }
      return 0;
    });

    return allEntries;
  }

  Future<void> _refresh() async {
    final newFuture = fetchCurrentMonthEntries();
    setState(() {
      _entriesFuture = newFuture;
    });
    await newFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfile()));
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: const Icon(Icons.person, color: Colors.blue),
            ),
          ),
        ),
        title: Text(
          "Welcome, ${widget.name ?? 'User'}",
          style: const TextStyle(
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final entries = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.blue,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            "Monthly Summary",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text("Total Milk", style: TextStyle(color: Colors.black87)),
                                  Text("${totalMilk.toStringAsFixed(2)} L",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text("Total Spent", style: TextStyle(color: Colors.black87)),
                                  Text("₹ ${totalSpent.toStringAsFixed(2)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (entries.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "No entries for this month.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  )
                else
                  ...entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Card(
                        color: Colors.blue[50],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.local_drink, color: Colors.blue[800]),
                          title: Text("${entry['quantity']} L | ₹${entry['price']}"),
                          subtitle: Text(
                            "Date: ${entry['date'] != null ? formatDate(entry['date']) : 'Unknown'}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Entry"),
                onPressed: () async {
                  final updated = await Navigator.pushNamed(context, '/add-entry');
                  if (updated == true) {
                    _refresh();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text("Previous Entries"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PreviousEntriesScreen(userId: widget.userId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
